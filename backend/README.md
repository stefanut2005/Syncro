# Backend (Flask + Docker)

Acest folder conține un mic server Flask cu endpoint-uri pentru `register` și `login` și configurare Docker Compose pentru rulare cu PostgreSQL.

Fișiere create:
- `server.py` - server Flask (port 5555 by default)
- `Dockerfile` - imagine pentru server
- `docker-compose.yml` - rulează serviciile `web` și `db` (Postgres)
- `requirements.txt` - dependențe Python

Cum rulezi (folosind Docker Compose):

1) În folderul `backend` rulează:

```powershell
# build + run
docker-compose up --build
```

2) Serverul va fi expus pe `http://localhost:5555`.

Endpoint-uri utile:
- POST /register
  - Body JSON: { "username": "nume", "password": "parola" }
  - Răspuns: 201 la succes
- POST /login
  - Body JSON: { "username": "nume", "password": "parola" }
  - Răspuns: 200 la succes

Exemple curl:

```powershell
# register
curl -X POST http://localhost:5555/register -H "Content-Type: application/json" -d '{"username":"test","password":"1234"}'

# login
curl -X POST http://localhost:5555/login -H "Content-Type: application/json" -d '{"username":"test","password":"1234"}'
```

Recomandări privind baza de date:
- Pentru dezvoltare rapidă: SQLite (folosit implicit dacă nu setați `DATABASE_URL`). Este simplu, zero-config.
- Pentru producție: PostgreSQL (recomandat). Are tranzacții robuste, replicare, backup-urile sunt mai simple.
- Alternative: MySQL/MariaDB (dacă ai deja ecosistemul), sau baza NoSQL (MongoDB) dacă modelul tău nu e relațional.

Note:
- În `docker-compose.yml` am setat user/parola/db la `myuser/mypassword/appdb`. Schimbă-le înainte de producție.
- Parolele sunt stocate hashed cu `passlib` (bcrypt). Pentru session management sau JWT se pot adăuga token-uri.

Logging / debugging
-------------------
Serverul scrie loguri atât la stdout (vizibile cu `docker-compose logs`) cât și într-un fișier rotativ: `/var/log/app/app.log`.

Am adăugat un volum `logdata` în `docker-compose.yml` care păstrează logurile aplicației. Poți vizualiza logurile astfel:

PowerShell examples:

```powershell
# pornește serviciile
docker-compose up --build -d

# urmărește logurile aggregate (stdout)
docker-compose logs -f web

# sau pornește serviciul "logviewer" care face tail la fișierul de log
docker-compose up logviewer

# intră în containerul web și verifică fișierul
docker-compose exec web sh
tail -n 200 /var/log/app/app.log
```

Notă: `logviewer` folosește `tail -F` pe fișierul din volum și este util pentru debug rapid; de asemenea poți folosi `docker-compose logs -f web` pentru a vedea ce scrie la stdout.
