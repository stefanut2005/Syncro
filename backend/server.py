import os
import logging
from logging.handlers import RotatingFileHandler
import time
from sqlalchemy.exc import OperationalError
from flask import Flask, request, jsonify, make_response
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import base64
import hashlib
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
import hmac

# Database URL (Postgres recommended in production). Fallback to SQLite for easy local dev.
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./app.db")

# If using sqlite, SQLAlchemy needs connect_args to disable same-thread check.
connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}
engine = create_engine(DATABASE_URL, connect_args=connect_args)
SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(128), unique=True, index=True, nullable=False)
    # store encrypted email (base64 nonce+ciphertext) and a separate HMAC for lookup
    email = Column(String(1024), nullable=False)
    email_hmac = Column(String(128), unique=True, index=True, nullable=False)
    password_hash = Column(String(512), nullable=False)

# Note: table creation is deferred until DB is reachable (see wait_for_db below).

app = Flask(__name__)

# --- CORS configuration (simple, no extra dependency) ---
# Configure via environment variables in production as needed.
CORS_ORIGIN = os.getenv('CORS_ORIGIN', '*')
CORS_ALLOW_HEADERS = os.getenv('CORS_ALLOW_HEADERS', 'Content-Type,Authorization')
CORS_ALLOW_METHODS = os.getenv('CORS_ALLOW_METHODS', 'GET,POST,PUT,DELETE,OPTIONS')
CORS_ALLOW_CREDENTIALS = os.getenv('CORS_ALLOW_CREDENTIALS', 'false').lower() in ('1', 'true', 'yes')


@app.before_request
def _handle_options_preflight():
    # Respond to OPTIONS preflight quickly with the appropriate headers
    if request.method == 'OPTIONS':
        resp = make_response(('', 204))
        resp.headers['Access-Control-Allow-Origin'] = CORS_ORIGIN
        resp.headers['Access-Control-Allow-Methods'] = CORS_ALLOW_METHODS
        resp.headers['Access-Control-Allow-Headers'] = CORS_ALLOW_HEADERS
        resp.headers['Access-Control-Max-Age'] = os.getenv('CORS_MAX_AGE', '3600')
        if CORS_ALLOW_CREDENTIALS:
            resp.headers['Access-Control-Allow-Credentials'] = 'true'
        return resp


@app.after_request
def _add_cors_headers(response):
    # Add CORS headers to all responses
    response.headers.setdefault('Access-Control-Allow-Origin', CORS_ORIGIN)
    response.headers.setdefault('Access-Control-Allow-Methods', CORS_ALLOW_METHODS)
    response.headers.setdefault('Access-Control-Allow-Headers', CORS_ALLOW_HEADERS)
    if CORS_ALLOW_CREDENTIALS:
        response.headers.setdefault('Access-Control-Allow-Credentials', 'true')
    return response

# --- Logging setup: write to stdout and to a rotating file in /var/log/app/app.log ---
LOG_DIR = os.getenv("LOG_DIR", "/var/log/app")
LOG_FILE = os.path.join(LOG_DIR, "app.log")
try:
    os.makedirs(LOG_DIR, exist_ok=True)
except Exception:
    # If we can't create the dir (permissions), fallback to current dir
    LOG_DIR = os.path.dirname(os.path.abspath(__file__))
    LOG_FILE = os.path.join(LOG_DIR, "app.log")

formatter = logging.Formatter("%(asctime)s %(levelname)s %(name)s: %(message)s")
root_logger = logging.getLogger()
root_logger.setLevel(logging.INFO)

# Stream handler (stdout)
stream_handler = logging.StreamHandler()
stream_handler.setFormatter(formatter)
root_logger.addHandler(stream_handler)

# Rotating file handler
file_handler = RotatingFileHandler(LOG_FILE, maxBytes=5 * 1024 * 1024, backupCount=5)
file_handler.setFormatter(formatter)
root_logger.addHandler(file_handler)

app.logger = logging.getLogger("app")

# Log each request (method + path)
@app.before_request
def log_request_info():
    app.logger.info("%s %s from %s", request.method, request.path, request.remote_addr)


# --- Wait for DB to be ready (if using Postgres) and then create tables ---
def wait_for_db(engine, retries: int = int(os.getenv("DB_RETRIES", "15")), delay: int = int(os.getenv("DB_DELAY", "2"))):
    logger = logging.getLogger("app")
    if DATABASE_URL.startswith("sqlite"):
        logger.info("Using sqlite, skipping DB wait")
        return True
    logger.info("Waiting for DB to be ready (retries=%s, delay=%s)...", retries, delay)
    for i in range(retries):
        try:
            with engine.connect() as conn:
                logger.info("Connected to DB.")
                return True
        except OperationalError as e:
            logger.warning("DB not ready (%s/%s): %s", i + 1, retries, e)
            time.sleep(delay)
    logger.error("Could not connect to DB after %s retries.", retries)
    return False


if not wait_for_db(engine):
    # If DB isn't available after retries, fail fast so container doesn't run in a broken state
    raise RuntimeError("Database unavailable after retries")

# Create tables if they don't exist yet (after DB is reachable)
Base.metadata.create_all(bind=engine)

# --- Encryption utilities (AES-GCM for confidentiality + HMAC-SHA256 for deterministic lookup) ---
KEY_B64 = os.getenv("KEY")
if not KEY_B64:
    # if no key set, warn and proceed but data won't be encryptable (shouldn't happen when entrypoint sets KEY)
    app.logger.warning("No KEY environment variable set; email encryption is disabled")
    AES_KEY = None
else:
    try:
        AES_KEY = base64.b64decode(KEY_B64)
    except Exception:
        AES_KEY = None


def encrypt_email(plain: str) -> str:
    if AES_KEY is None:
        return plain
    aesgcm = AESGCM(AES_KEY)
    nonce = os.urandom(12)
    ct = aesgcm.encrypt(nonce, plain.encode("utf-8"), associated_data=None)
    # store nonce + ciphertext in base64
    return base64.b64encode(nonce + ct).decode("utf-8")


def decrypt_email(enc: str) -> str:
    if AES_KEY is None:
        return enc
    try:
        data = base64.b64decode(enc)
        nonce = data[:12]
        ct = data[12:]
        aesgcm = AESGCM(AES_KEY)
        pt = aesgcm.decrypt(nonce, ct, associated_data=None)
        return pt.decode("utf-8")
    except Exception:
        return ""


def email_hmac(plain: str) -> str:
    # deterministic HMAC-SHA256 for lookup; use AES_KEY if available, else a fallback static
    key = AES_KEY if AES_KEY is not None else b"fallback-key"
    hm = hashlib.pbkdf2_hmac('sha256', plain.encode('utf-8'), key, 1000)
    return hm.hex()

@app.route("/register", methods=["POST"])
def register():
    data = request.get_json() or {}
    username = data.get("username")
    email = data.get("email")
    hash_value = data.get("hash")
    if not username or not email or not hash_value:
        return jsonify({"error": "username, email and hash are required"}), 400

    # basic validation
    if not isinstance(hash_value, str) or len(hash_value) == 0:
        return jsonify({"error": "invalid hash"}), 400
    if len(hash_value.encode("utf-8")) > 4096:
        return jsonify({"error": "hash too long"}), 400

    db = SessionLocal()
    try:
        # check username already exists
        if db.query(User).filter_by(username=username).first():
            return jsonify({"error": "username exists"}), 400
        # compute email hmac and encrypted email
        enc_email = encrypt_email(email)
        eh = email_hmac(email)
        if db.query(User).filter_by(email_hmac=eh).first():
            return jsonify({"error": "email exists"}), 400

        user = User(username=username, email=enc_email, email_hmac=eh, password_hash=hash_value)
        db.add(user)
        db.commit()
        return jsonify({"message": "registered"}), 201
    finally:
        db.close()

@app.route("/login", methods=["POST"])
def login():
    data = request.get_json() or {}
    # accept either username or email as identifier
    username = data.get("username")
    email = data.get("email")
    hash_value = data.get("hash")
    if not hash_value or (not username and not email):
        return jsonify({"error": "provide username or email and hash"}), 400

    db = SessionLocal()
    try:
        user = None
        if username:
            user = db.query(User).filter_by(username=username).first()
        elif email:
            # compute hmac and lookup by email_hmac
            eh = email_hmac(email)
            user = db.query(User).filter_by(email_hmac=eh).first()

        if not user:
            return jsonify({"error": "invalid credentials"}), 401

        # compare provided hash from frontend with stored hash
        try:
            match = hmac.compare_digest(hash_value, user.password_hash)
        except Exception:
            match = False

        if not match:
            return jsonify({"error": "invalid credentials"}), 401
        # Return decrypted email and username so clients can populate local state
        try:
            dec_email = decrypt_email(user.email) if user.email else ''
        except Exception:
            dec_email = ''
        return jsonify({"message": "login successful", "username": user.username, "email": dec_email}), 200
    finally:
        db.close()

@app.route("/", methods=["GET"])
def index():
    return jsonify({"status": "ok"})

if __name__ == "__main__":
    port = int(os.getenv("PORT", "5555"))
    app.run(host="0.0.0.0", port=port)
