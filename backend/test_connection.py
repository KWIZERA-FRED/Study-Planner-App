import os
import mysql.connector
from mysql.connector import Error

# ---------------------------------------------------------------------
# Connection details from your Aiven service.
# Set these as environment variables rather than hardcoding the password.
# ---------------------------------------------------------------------
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'mysql-efbd6a0-study-planner-api.d.aivencloud.com'),
    'port': int(os.getenv('DB_PORT', 15413)),
    'user': os.getenv('DB_USER', 'avnadmin'),
    'password': os.getenv('DB_PASSWORD'),  # no fallback — must be set explicitly
    'database': os.getenv('DB_NAME', 'defaultdb'),
    'ssl_disabled': False,  # Aiven requires SSL (mode: REQUIRED)
}

CREATE_TABLE_SQL = '''
CREATE TABLE IF NOT EXISTS goals (
    id INT AUTO_INCREMENT PRIMARY KEY,
    subject VARCHAR(255) NOT NULL,
    hours INT NOT NULL,
    done BOOLEAN NOT NULL DEFAULT FALSE
)
'''


def main():
    if not DB_CONFIG['password']:
        print("Error: DB_PASSWORD environment variable is not set.")
        return

    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        print("Connected to Aiven MySQL successfully.")

        cursor = conn.cursor()
        cursor.execute(CREATE_TABLE_SQL)
        conn.commit()
        print("Table 'goals' created (or already exists).")

        cursor.execute("SHOW TABLES")
        print("Tables in defaultdb:", cursor.fetchall())

        cursor.close()
        conn.close()
    except Error as e:
        print("Error:", e)


if __name__ == '__main__':
    main()