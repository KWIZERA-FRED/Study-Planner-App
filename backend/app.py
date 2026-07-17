import os
from flask import Flask, jsonify, request
from flask_cors import CORS
import mysql.connector
from mysql.connector import Error

app = Flask(__name__)
CORS(app)

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", 3306)),
    "user": os.getenv("DB_USER", "root"),
    "password": os.getenv("DB_PASSWORD", "password"),
    "database": os.getenv("DB_NAME", "study_planner"),
    "ssl_disabled": False,
}

# Aiven requires SSL. If you've downloaded the CA cert (ca.pem) from the
# Aiven console, set DB_SSL_CA to its path (or upload it as a Render secret
# file and point to that path) for full certificate verification.
DB_SSL_CA = os.getenv("DB_SSL_CA")
if DB_SSL_CA:
    DB_CONFIG["ssl_ca"] = DB_SSL_CA
    DB_CONFIG["ssl_verify_cert"] = True
else:
    # Works without the CA file, but doesn't verify the server certificate.
    # Fine for testing; add DB_SSL_CA for production.
    DB_CONFIG["ssl_verify_cert"] = False


def get_connection():
    return mysql.connector.connect(**DB_CONFIG)


def init_db():
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS goals (
                id INT AUTO_INCREMENT PRIMARY KEY,
                subject VARCHAR(255) NOT NULL,
                hours INT NOT NULL,
                done BOOLEAN NOT NULL DEFAULT FALSE
            )
            """
        )
        conn.commit()
        cursor.close()
        conn.close()
        print("Database initialized successfully.")
    except Error as e:
        print(f"Database initialization failed: {e}")
        raise


@app.route("/", methods=["GET"])
def health_check():
    return jsonify({"status": "ok", "message": "Backend is running"}), 200


@app.route("/goals", methods=["GET"])
def list_goals():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT id, subject, hours, done FROM goals")
    rows = cursor.fetchall()
    cursor.close()
    conn.close()
    for row in rows:
        row["done"] = bool(row["done"])
    return jsonify(rows)


@app.route("/goals", methods=["POST"])
def create_goal():
    data = request.get_json()
    subject = (data.get("subject") or "").strip()
    hours = data.get("hours")

    if not subject:
        return jsonify({"error": "Subject cannot be empty"}), 400
    if not isinstance(hours, int) or hours <= 0:
        return jsonify({"error": "Hours must be a positive integer"}), 400

    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO goals (subject, hours, done) VALUES (%s, %s, %s)",
        (subject, hours, False),
    )
    conn.commit()
    new_id = cursor.lastrowid
    cursor.close()
    conn.close()

    return jsonify({"id": new_id, "subject": subject, "hours": hours, "done": False}), 201


@app.route("/goals/<int:goal_id>", methods=["PUT"])
def update_goal(goal_id):
    data = request.get_json()

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM goals WHERE id = %s", (goal_id,))
    goal = cursor.fetchone()
    if not goal:
        cursor.close()
        conn.close()
        return jsonify({"error": "Goal not found"}), 404

    subject = data.get("subject", goal["subject"])
    hours = data.get("hours", goal["hours"])
    done = data.get("done", bool(goal["done"]))

    cursor.execute(
        "UPDATE goals SET subject = %s, hours = %s, done = %s WHERE id = %s",
        (subject, hours, done, goal_id),
    )
    conn.commit()
    cursor.close()
    conn.close()

    return jsonify({"id": goal_id, "subject": subject, "hours": hours, "done": bool(done)})


@app.route("/goals/<int:goal_id>", methods=["DELETE"])
def delete_goal(goal_id):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT id FROM goals WHERE id = %s", (goal_id,))
    if not cursor.fetchone():
        cursor.close()
        conn.close()
        return jsonify({"error": "Goal not found"}), 404

    cursor.execute("DELETE FROM goals WHERE id = %s", (goal_id,))
    conn.commit()
    cursor.close()
    conn.close()
    return "", 204


if __name__ == "__main__":
    init_db()
    port = int(os.getenv("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=False)