import os
import sys
import time
from sqlalchemy import create_engine, text
from sqlalchemy.exc import OperationalError

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./app.db")


def wait_for_db(engine, retries=15, delay=2):
    for i in range(retries):
        try:
            with engine.connect() as conn:
                return True
        except OperationalError:
            time.sleep(delay)
    return False


def main():
    engine = create_engine(DATABASE_URL)
    if not wait_for_db(engine, retries=30, delay=1):
        print("Migration: DB not available after retries, exiting with error")
        sys.exit(1)

    with engine.connect() as conn:
        # Add columns if not exists (Postgres supports IF NOT EXISTS for ADD COLUMN)
        try:
            # Add email column (nullable) and email_hmac column (nullable) and index
            conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR(1024);"))
            conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS email_hmac VARCHAR(128);"))
            # create unique index if not exists (Postgres syntax)
            conn.execute(text(
                "CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_hmac ON users (email_hmac);"
            ))
            print("Migration: ensured columns email and email_hmac exist")
        except Exception as e:
            print("Migration error:", e)
            sys.exit(1)


if __name__ == '__main__':
    main()
