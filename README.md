# Syncro

A cross-platform task manager with login form that pairs a Flutter mobile client with a Python/Flask backend to provide team task coordination and offline sync.

## Project structure
- `backend/` — Python backend (Flask + SQLAlchemy). Important files:
  - `server.py` — API endpoints, DB models and encryption utilities (AES‑GCM used for email encryption).
  - `requirements.txt`, `Dockerfile`, `docker-compose.yml`, `entrypoint.sh`.
- `task_manager_app/` — Flutter client (Android/iOS/web). Main app file:
  - `lib/main.dart`.

## Technologies
- Frontend: Flutter (Dart)
- Backend: Python 3, Flask, SQLAlchemy
- Cryptography: `cryptography` (AES‑GCM), `hashlib` (PBKDF2/HMAC used in certain helpers)
- Database: PostgreSQL recommended; SQLite used as a local fallback
- Containerization: Docker, docker‑compose

## Quick start — using Docker (recommended)
1. Clone the repository and change into it:
   - `git clone <repo-url>`
   - `cd itfest`
2. Create a `.env` file (example minimal content):
   ```
   PORT=5000
   DATABASE_URL=sqlite:///./app.db
   KEY=<base64-encoded-32-bytes>   # base64 of a 32-byte key (AES-256)
   LOG_DIR=./logs
   ```
3. Bring up the services with docker-compose:
   - `docker compose up --build`
4. Backend will be available at `http://localhost:5000` (or `PORT` from `.env`).

## Quick start — without Docker (Windows)
1. Create a virtual environment and install dependencies:
   ```powershell
   python -m venv .venv
   .\.venv\Scripts\activate
   pip install -r backend\requirements.txt
   ```
2. Set environment variables (example, PowerShell):
   ```powershell
   $env:PORT = '5000'; $env:DATABASE_URL = 'sqlite:///./app.db'; $env:KEY = '<base64>'
   python backend\server.py
   ```

## Important environment variables
- `DATABASE_URL` — database connection string (e.g. `postgres://...` or `sqlite:///./app.db`).
- `KEY` — Base64 encoded encryption key. The server expects a binary key (16/24/32 bytes for AES); 32 bytes (AES‑256) is recommended.
- `PORT`, `LOG_DIR`, `DB_RETRIES`, `DB_DELAY`, `CORS_*` — other optional configuration.

## Security notes (read carefully)
- The backend uses AES‑GCM (`cryptography.hazmat.primitives.ciphers.aead.AESGCM`) to encrypt user emails. AES‑GCM provides authenticated encryption (confidentiality + integrity). Nonce (12 bytes) is generated per encryption and stored together with ciphertext (base64).
- The repository also contains a deterministic lookup helper (an HMAC/PBKDF2‑based function) used to support searching by email while keeping email ciphertexts confidential. IMPORTANT: do not reuse the same key for both encryption and HMAC/indexing.

## Development notes & useful details
- Database: the code uses SQLAlchemy and supports PostgreSQL (recommended) or a local SQLite fallback for development.
- Logging: the server logs to stdout and to a rotating file (configurable via `LOG_DIR`).
- Offline per-user sync: the backend stores per-user JSON files under `USER_TASK_DIR` (configurable by environment variable) for offline/sync features.
- CORS: simple CORS configuration is available via `CORS_ORIGIN`, `CORS_ALLOW_HEADERS`, etc.


