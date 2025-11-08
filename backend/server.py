import os
import logging
from logging.handlers import RotatingFileHandler
import time
from sqlalchemy.exc import OperationalError
from flask import Flask, request, jsonify, make_response
from sqlalchemy import create_engine, Column, Integer, String, DateTime, Text, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
import base64
import hashlib
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
import hmac
import json
import re

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


class Task(Base):
    __tablename__ = "tasks"
    id = Column(Integer, primary_key=True, index=True)
    # owner / person id - references users.id
    owner_id = Column(Integer, ForeignKey('users.id'), nullable=True, index=True)
    owner = relationship('User', backref='tasks')
    title = Column(String(512), nullable=False)
    start_dt = Column(DateTime, nullable=True)
    end_dt = Column(DateTime, nullable=True)
    # priority: 1 = low, 2 = medium, 3 = high
    priority = Column(Integer, nullable=False, default=1)
    notes = Column(Text, nullable=True)

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

# Directory to store per-user offline task files
USER_TASK_DIR = os.getenv('USER_TASK_DIR', os.path.join(os.path.dirname(os.path.abspath(__file__)), 'user_tasks'))
try:
    os.makedirs(USER_TASK_DIR, exist_ok=True)
except Exception:
    # fallback to cwd if creation fails
    USER_TASK_DIR = os.getcwd()


def _sanitize_username(name: str) -> str:
    """Sanitize username for use as a filename: keep alphanumeric, dash and underscore."""
    if not name:
        return 'unknown'
    return re.sub(r'[^A-Za-z0-9_\-]', '_', name)


def write_user_tasks_file(db_session, user: User):
    """Write all tasks for `user` to a JSON file named <username>.json in USER_TASK_DIR.

    This mirrors the DB state and can be used by the client to sync while offline.
    """
    try:
        if not user:
            return False
        tasks = db_session.query(Task).filter_by(owner_id=user.id).all()
        out = []
        for t in tasks:
            out.append({
                'id': t.id,
                'owner_id': t.owner_id,
                'title': t.title,
                'start_dt': t.start_dt.isoformat() if t.start_dt else None,
                'end_dt': t.end_dt.isoformat() if t.end_dt else None,
                'priority': t.priority,
                'notes': t.notes,
            })

        filename = os.path.join(USER_TASK_DIR, f"{_sanitize_username(user.username)}.json")
        with open(filename, 'w', encoding='utf-8') as fh:
            json.dump({'user': user.username, 'user_id': user.id, 'tasks': out}, fh, ensure_ascii=False, indent=2)
        app.logger.info("Wrote user tasks file: %s", filename)
        return True
    except Exception as e:
        app.logger.warning("Failed to write user tasks file for %s: %s", getattr(user, 'username', None), e)
        return False


def _local_tasks_filename_for(username: str) -> str:
    return os.path.join(USER_TASK_DIR, f"{_sanitize_username(username)}.json")


def read_local_user_tasks(username: str):
    """Read the local per-user tasks JSON file and return its dict, or None if not present/invalid."""
    try:
        fn = _local_tasks_filename_for(username)
        if not os.path.exists(fn):
            return {'user': username, 'user_id': None, 'tasks': []}
        with open(fn, 'r', encoding='utf-8') as fh:
            return json.load(fh)
    except Exception as e:
        app.logger.warning("Failed to read local user tasks file for %s: %s", username, e)
        return {'user': username, 'user_id': None, 'tasks': []}


def write_local_user_tasks(username: str, payload: dict):
    """Write payload to the user's local tasks file safely (atomic replace).

    payload should be a dict with keys: user, user_id, tasks
    """
    try:
        fn = _local_tasks_filename_for(username)
        tmp = fn + '.tmp'
        with open(tmp, 'w', encoding='utf-8') as fh:
            json.dump(payload, fh, ensure_ascii=False, indent=2)
        os.replace(tmp, fn)
        app.logger.info("Wrote local tasks file for %s -> %s", username, fn)
        return True
    except Exception as e:
        app.logger.warning("Failed to write local user tasks file for %s: %s", username, e)
        return False

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

        # Also include user id and any tasks owned by this user so client can
        # initialise local storage on login.
        task_list = []
        try:
            tasks = db.query(Task).filter_by(owner_id=user.id).all()
            for t in tasks:
                task_list.append({
                    'id': t.id,
                    'owner_id': t.owner_id,
                    'title': t.title,
                    'start_dt': t.start_dt.isoformat() if t.start_dt else None,
                    'end_dt': t.end_dt.isoformat() if t.end_dt else None,
                    'priority': t.priority,
                    'notes': t.notes,
                })
        except Exception:
            task_list = []

        return jsonify({
            "message": "login successful",
            "username": user.username,
            "email": dec_email,
            "user_id": user.id,
            "tasks": task_list,
        }), 200
    finally:
        db.close()

@app.route("/", methods=["GET"])
def index():
    return jsonify({"status": "ok"})


@app.route("/create_task", methods=["POST"])
def create_task():
    data = request.get_json() or {}
    owner_id = data.get('owner_id')
    title = data.get('title')
    start_dt = data.get('start_dt')
    end_dt = data.get('end_dt')
    priority = data.get('priority', 1)
    notes = data.get('notes')

    if not owner_id or not title:
        return jsonify({'error': 'owner_id and title required'}), 400

    # Build a local task entry first (temporary id)
    from datetime import datetime
    ts = int(time.time() * 1000)
    local_id = f"local-{ts}"
    sd = None
    ed = None
    try:
        if start_dt:
            sd = datetime.fromisoformat(start_dt)
    except Exception:
        sd = None
    try:
        if end_dt:
            ed = datetime.fromisoformat(end_dt)
    except Exception:
        ed = None

    local_task = {
        'id': local_id,
        'owner_id': owner_id,
        'title': title,
        'start_dt': sd.isoformat() if sd else None,
        'end_dt': ed.isoformat() if ed else None,
        'priority': int(priority or 1),
        'notes': notes,
    }

    # Determine username (prefer provided username, else try DB, else fallback)
    username = data.get('username')
    user_obj = None
    try:
        db = SessionLocal()
        try:
            if not username:
                user_obj = db.query(User).filter_by(id=owner_id).first()
                if user_obj:
                    username = user_obj.username
        except Exception:
            user_obj = None
    except Exception:
        db = None

    if not username:
        username = f'user_{owner_id}'

    # Update local file first
    try:
        local_payload = read_local_user_tasks(username)
        local_payload.setdefault('tasks', [])
        local_payload['user'] = username
        local_payload['user_id'] = owner_id
        local_payload['tasks'].append(local_task)
        write_local_user_tasks(username, local_payload)
    except Exception:
        app.logger.warning("Failed to persist local task for %s", username)

    # Now attempt DB insert; if it succeeds, refresh local file from DB (replace temp id)
    db_failed = False
    db_task = None
    try:
        if db is None:
            db = SessionLocal()
        # basic owner check
        if not user_obj:
            user_obj = db.query(User).filter_by(id=owner_id).first()
            if not user_obj:
                db_failed = True
        if not db_failed:
            task = Task(owner_id=owner_id, title=title, start_dt=sd, end_dt=ed, priority=int(priority or 1), notes=notes)
            db.add(task)
            db.commit()
            db.refresh(task)
            db_task = task
            # refresh local file from DB authoritative state
            try:
                write_user_tasks_file(db, user_obj)
            except Exception:
                pass
    except Exception as e:
        app.logger.warning("DB insert failed for create_task: %s", e)
        db_failed = True
    finally:
        try:
            if db:
                db.close()
        except Exception:
            pass

    if db_failed:
        # return accepted with local id so client can track
        return jsonify({'message': 'saved locally', 'local_id': local_id}), 202
    else:
        return jsonify({
            'id': db_task.id,
            'owner_id': db_task.owner_id,
            'title': db_task.title,
            'start_dt': db_task.start_dt.isoformat() if db_task.start_dt else None,
            'end_dt': db_task.end_dt.isoformat() if db_task.end_dt else None,
            'priority': db_task.priority,
            'notes': db_task.notes,
        }), 201


@app.route("/update_task", methods=["PUT"])
def update_task():
    """Partial update for a task. Expects JSON with 'id' and any of (title, start_dt, end_dt, priority, notes).
    Returns 200 with updated task or appropriate error codes.
    """
    data = request.get_json() or {}
    task_id = data.get('id')
    if not task_id:
        return jsonify({'error': 'id required'}), 400

    # Update local file first
    username = data.get('username')
    # try to determine username from DB if not provided and id looks numeric
    owner_username = None
    try:
        # if task_id is numeric, try to get owner username
        try:
            int_id = int(task_id)
        except Exception:
            int_id = None
        if not username and int_id is not None:
            db = SessionLocal()
            try:
                t = db.query(Task).filter_by(id=int_id).first()
                if t and t.owner:
                    username = t.owner.username
            finally:
                db.close()
    except Exception:
        pass

    if not username:
        username = 'unknown'

    try:
        local_payload = read_local_user_tasks(username)
        changed = False
        for lt in local_payload.get('tasks', []):
            if str(lt.get('id')) == str(task_id):
                # apply fields
                if 'title' in data:
                    lt['title'] = data.get('title')
                if 'start_dt' in data:
                    lt['start_dt'] = data.get('start_dt')
                if 'end_dt' in data:
                    lt['end_dt'] = data.get('end_dt')
                if 'priority' in data:
                    lt['priority'] = data.get('priority')
                if 'notes' in data:
                    lt['notes'] = data.get('notes')
                changed = True
                break
        if not changed:
            # If task not found locally, append an entry (will be reconciled later)
            new_local = {
                'id': task_id,
                'owner_id': data.get('owner_id'),
                'title': data.get('title'),
                'start_dt': data.get('start_dt'),
                'end_dt': data.get('end_dt'),
                'priority': data.get('priority'),
                'notes': data.get('notes'),
            }
            local_payload.setdefault('tasks', []).append(new_local)
        local_payload['user'] = username
        write_local_user_tasks(username, local_payload)
    except Exception:
        app.logger.warning("Failed to update local task file for %s", username)

    # Now attempt DB update if possible. Try numeric id first; if non-numeric, do a
    # best-effort lookup by owner/title/start_dt/end_dt and apply the update to matching rows.
    db_failed = False
    db_task = None
    try:
        int_id = None
        try:
            int_id = int(task_id)
        except Exception:
            int_id = None

        db = SessionLocal()
        try:
            if int_id is not None:
                task = db.query(Task).filter_by(id=int_id).first()
                if not task:
                    db_failed = True
                else:
                    if 'title' in data:
                        task.title = data.get('title')
                    if 'start_dt' in data:
                        try:
                            from datetime import datetime
                            task.start_dt = datetime.fromisoformat(data.get('start_dt')) if data.get('start_dt') else None
                        except Exception:
                            pass
                    if 'end_dt' in data:
                        try:
                            from datetime import datetime
                            task.end_dt = datetime.fromisoformat(data.get('end_dt')) if data.get('end_dt') else None
                        except Exception:
                            pass
                    if 'priority' in data:
                        try:
                            task.priority = int(data.get('priority') or task.priority)
                        except Exception:
                            pass
                    if 'notes' in data:
                        task.notes = data.get('notes')

                    db.add(task)
                    db.commit()
                    db.refresh(task)
                    db_task = task
                    try:
                        u = db.query(User).filter_by(id=task.owner_id).first()
                        write_user_tasks_file(db, u)
                    except Exception:
                        pass
            else:
                # attempt best-effort mapping
                owner_obj = None
                owner_id_val = data.get('owner_id') or data.get('user_id')
                if owner_id_val is not None:
                    try:
                        owner_n = int(owner_id_val)
                        owner_obj = db.query(User).filter_by(id=owner_n).first()
                    except Exception:
                        try:
                            owner_obj = db.query(User).filter_by(username=str(owner_id_val)).first()
                        except Exception:
                            owner_obj = None

                q = db.query(Task)
                if owner_obj:
                    q = q.filter_by(owner_id=owner_obj.id)

                title = data.get('title')
                if title:
                    try:
                        q = q.filter(Task.title == title)
                    except Exception:
                        pass

                from datetime import datetime
                start_dt = None
                end_dt = None
                try:
                    if data.get('start_dt'):
                        start_dt = datetime.fromisoformat(data.get('start_dt'))
                except Exception:
                    start_dt = None
                try:
                    if data.get('end_dt'):
                        end_dt = datetime.fromisoformat(data.get('end_dt'))
                except Exception:
                    end_dt = None

                if start_dt is not None:
                    try:
                        q = q.filter(Task.start_dt == start_dt)
                    except Exception:
                        pass
                if end_dt is not None:
                    try:
                        q = q.filter(Task.end_dt == end_dt)
                    except Exception:
                        pass

                candidates = []
                try:
                    candidates = q.all()
                except Exception:
                    candidates = []

                if candidates:
                    # apply updates to all matching candidates
                    for cand in candidates:
                        if 'title' in data:
                            cand.title = data.get('title') or cand.title
                        if 'start_dt' in data:
                            try:
                                cand.start_dt = datetime.fromisoformat(data.get('start_dt')) if data.get('start_dt') else None
                            except Exception:
                                pass
                        if 'end_dt' in data:
                            try:
                                cand.end_dt = datetime.fromisoformat(data.get('end_dt')) if data.get('end_dt') else None
                            except Exception:
                                pass
                        if 'priority' in data:
                            try:
                                cand.priority = int(data.get('priority') or cand.priority)
                            except Exception:
                                pass
                        if 'notes' in data:
                            cand.notes = data.get('notes') or cand.notes
                        db.add(cand)
                    db.commit()
                    # pick the first as the returned task
                    try:
                        db.refresh(candidates[0])
                        db_task = candidates[0]
                    except Exception:
                        db_task = None
                    try:
                        if owner_obj:
                            write_user_tasks_file(db, owner_obj)
                    except Exception:
                        pass
                else:
                    db_failed = True
        finally:
            try:
                db.close()
            except Exception:
                pass
    except Exception as e:
        app.logger.warning("DB update failed for update_task: %s", e)
        db_failed = True

    if db_failed:
        return jsonify({'message': 'updated locally; DB update pending'}), 202
    else:
        return jsonify({
            'id': db_task.id,
            'owner_id': db_task.owner_id,
            'title': db_task.title,
            'start_dt': db_task.start_dt.isoformat() if db_task.start_dt else None,
            'end_dt': db_task.end_dt.isoformat() if db_task.end_dt else None,
            'priority': db_task.priority,
            'notes': db_task.notes,
        }), 200


@app.route("/delete_task", methods=["DELETE"])
def delete_task():
    """Delete a task. Accepts JSON with 'id' of the task to delete.
    Returns 200 on success or 404 if not found.
    """
    data = request.get_json() or {}
    task_id = data.get('id')
    if not task_id:
        return jsonify({'error': 'id required'}), 400

    # Update local file first
    username = data.get('username')
    try:
        # if id numeric, try to get owner username from DB
        try:
            int_id = int(task_id)
        except Exception:
            int_id = None
        if not username and int_id is not None:
            db = SessionLocal()
            try:
                t = db.query(Task).filter_by(id=int_id).first()
                if t and t.owner:
                    username = t.owner.username
            finally:
                db.close()
    except Exception:
        pass

    if not username:
        username = 'unknown'

    try:
        local_payload = read_local_user_tasks(username)
        new_tasks = [lt for lt in local_payload.get('tasks', []) if str(lt.get('id')) != str(task_id)]
        local_payload['tasks'] = new_tasks
        write_local_user_tasks(username, local_payload)
    except Exception:
        app.logger.warning("Failed to update local tasks file for delete %s", username)

    # Now attempt DB delete if possible. We try numeric-id deletion first; if id is non-numeric
    # (local id like "local-123") perform a best-effort lookup using owner/title/start_dt/end_dt
    db_failed = False
    try:
        int_id = None
        try:
            int_id = int(task_id)
        except Exception:
            int_id = None

        db = SessionLocal()
        try:
            if int_id is not None:
                # straightforward numeric id delete
                task = db.query(Task).filter_by(id=int_id).first()
                if not task:
                    db_failed = True
                else:
                    owner = db.query(User).filter_by(id=task.owner_id).first() if task.owner_id else None
                    db.delete(task)
                    db.commit()
                    app.logger.info("delete_task: deleted numeric id %s from DB (owner=%s)", int_id, getattr(owner, 'username', owner.id if owner else None))
                    try:
                        if owner:
                            write_user_tasks_file(db, owner)
                    except Exception:
                        pass
            else:
                # try to match by owner (owner_id or user_id), or username if provided
                owner_obj = None
                owner_id_val = data.get('owner_id') or data.get('user_id')
                if owner_id_val is not None:
                    try:
                        owner_n = int(owner_id_val)
                        owner_obj = db.query(User).filter_by(id=owner_n).first()
                    except Exception:
                        # maybe username provided
                        try:
                            owner_obj = db.query(User).filter_by(username=str(owner_id_val)).first()
                        except Exception:
                            owner_obj = None

                # build a query to look for candidate tasks
                q = db.query(Task)
                if owner_obj:
                    q = q.filter_by(owner_id=owner_obj.id)

                title = data.get('title')
                if title:
                    try:
                        q = q.filter(Task.title == title)
                    except Exception:
                        pass

                # parse optional datetimes
                from datetime import datetime
                start_dt = None
                end_dt = None
                try:
                    if data.get('start_dt'):
                        start_dt = datetime.fromisoformat(data.get('start_dt'))
                except Exception:
                    start_dt = None
                try:
                    if data.get('end_dt'):
                        end_dt = datetime.fromisoformat(data.get('end_dt'))
                except Exception:
                    end_dt = None

                if start_dt is not None:
                    try:
                        q = q.filter(Task.start_dt == start_dt)
                    except Exception:
                        pass
                if end_dt is not None:
                    try:
                        q = q.filter(Task.end_dt == end_dt)
                    except Exception:
                        pass

                candidates = []
                try:
                    candidates = q.all()
                except Exception:
                    candidates = []

                if candidates:
                    # delete all matching candidates (best-effort)
                    for cand in candidates:
                        db.delete(cand)
                    db.commit()
                    app.logger.info("delete_task: best-effort matched and deleted %s candidate(s) for username=%s title=%s", len(candidates), getattr(owner_obj, 'username', None), title)
                    try:
                        if owner_obj:
                            write_user_tasks_file(db, owner_obj)
                    except Exception:
                        pass
                else:
                    # nothing matched in DB
                    app.logger.info("delete_task: no DB candidates matched for id=%s username=%s title=%s start_dt=%s end_dt=%s", task_id, getattr(owner_obj, 'username', None), title, data.get('start_dt'), data.get('end_dt'))
                    db_failed = True
        finally:
            try:
                db.close()
            except Exception:
                pass
    except Exception as e:
        app.logger.warning("DB delete failed for delete_task: %s", e)
        db_failed = True

    if db_failed:
        return jsonify({'message': 'deleted locally; DB delete pending'}), 202
    else:
        return jsonify({'message': 'deleted'}), 200


@app.route("/update_db_with_local", methods=["POST"])
def update_db_with_local():
    """Read the server-side per-user local JSON file and apply its contents to the DB.

    Expects JSON body with either 'username' or 'user_id'. Returns 200 with a summary
    on success, or 400/500 on errors. If DB operations partially fail, returns 500
    with details.
    """
    data = request.get_json() or {}
    username = data.get('username')
    user_id = data.get('user_id')

    db = SessionLocal()
    try:
        user = None
        if user_id:
            user = db.query(User).filter_by(id=user_id).first()
            if user and not username:
                username = user.username
        elif username:
            user = db.query(User).filter_by(username=username).first()

        if not user:
            return jsonify({'error': 'user not found'}), 404

        # read local file
        local = read_local_user_tasks(user.username)
        tasks = local.get('tasks', []) if isinstance(local, dict) else []

        applied = []
        errors = []

        # Build set of numeric ids present locally (to detect deletes)
        local_db_ids = set()
        for lt in tasks:
            lid = lt.get('id')
            try:
                if isinstance(lid, int):
                    local_db_ids.add(int(lid))
                else:
                    # if string and numeric
                    if isinstance(lid, str) and lid.isdigit():
                        local_db_ids.add(int(lid))
            except Exception:
                pass

        # Upsert tasks from local file
        from datetime import datetime
        for lt in tasks:
            try:
                lid = lt.get('id')
                title = lt.get('title')
                priority = int(lt.get('priority') or 1)
                notes = lt.get('notes')
                start_dt = None
                end_dt = None
                try:
                    if lt.get('start_dt'):
                        start_dt = datetime.fromisoformat(lt.get('start_dt'))
                except Exception:
                    start_dt = None
                try:
                    if lt.get('end_dt'):
                        end_dt = datetime.fromisoformat(lt.get('end_dt'))
                except Exception:
                    end_dt = None

                # Determine if this is an existing DB row
                is_db_id = False
                db_id = None
                if isinstance(lid, int):
                    is_db_id = True
                    db_id = int(lid)
                elif isinstance(lid, str) and lid.isdigit():
                    is_db_id = True
                    db_id = int(lid)

                if is_db_id and db_id is not None:
                    task = db.query(Task).filter_by(id=db_id, owner_id=user.id).first()
                    if task:
                        # update
                        task.title = title or task.title
                        task.priority = priority or task.priority
                        task.notes = notes
                        task.start_dt = start_dt
                        task.end_dt = end_dt
                        db.add(task)
                        db.commit()
                        db.refresh(task)
                        applied.append({'action': 'updated', 'id': task.id})
                        continue
                    else:
                        # not found, treat as create
                        new_task = Task(owner_id=user.id, title=title or '', start_dt=start_dt, end_dt=end_dt, priority=priority, notes=notes)
                        db.add(new_task)
                        db.commit()
                        db.refresh(new_task)
                        applied.append({'action': 'created', 'id': new_task.id})
                        continue
                else:
                    # local id (e.g., local-123) -> create in DB
                    new_task = Task(owner_id=user.id, title=title or '', start_dt=start_dt, end_dt=end_dt, priority=priority, notes=notes)
                    db.add(new_task)
                    db.commit()
                    db.refresh(new_task)
                    applied.append({'action': 'created', 'id': new_task.id})
            except Exception as e:
                errors.append(str(e))

        # Delete DB tasks not present in local_db_ids
        try:
            db_tasks = db.query(Task).filter_by(owner_id=user.id).all()
            for dt in db_tasks:
                if dt.id not in local_db_ids:
                    # If local_db_ids is empty it means local file had only local IDs; be conservative and skip deletion
                    if len(local_db_ids) == 0:
                        continue
                    db.delete(dt)
                    db.commit()
                    applied.append({'action': 'deleted', 'id': dt.id})
        except Exception as e:
            errors.append(str(e))

        # After applying, refresh the server-side file from DB (authoritative)
        try:
            write_user_tasks_file(db, user)
        except Exception:
            pass

        summary = {'applied': applied, 'errors': errors}
        if errors:
            return jsonify(summary), 500
        return jsonify(summary), 200
    finally:
        db.close()

if __name__ == "__main__":
    port = int(os.getenv("PORT", "5555"))
    app.run(host="0.0.0.0", port=port)