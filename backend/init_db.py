import mysql.connector
from mysql.connector import Error

# ---------------------------------------------------------------------
# Connection details from your Aiven service
# ---------------------------------------------------------------------
DB_CONFIG = {
    'host': 'mysql-efbd6a0-study-planner-api.d.aivencloud.com',
    'port': 15413,
    'user': 'avnadmin',
    'password': 'YOUR_PASSWORD_HERE',
    'database': 'defaultdb',
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