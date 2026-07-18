# 📚 My Study Planner

A Flutter mobile application that helps students organize their study goals, track tasks, and manage their academic workload — backed by a Flask REST API and a cloud-hosted MySQL database.

Built as part of a Mobile Development course assignment at the **University of Lay Adventists of Kigali (UNILAK)**.

---

## 📲 Download

**[Download the APK](https://drive.google.com/file/d/1GteFMGBuMWMtXphrtg63tVRAxmHwTH0H/view?usp=drive_link)**

> Note: Since this isn't distributed via the Play Store, Android will prompt you to allow installs from unknown sources — this is expected.

---

## ✨ Features

- **Goal & Task Management** — Create, edit, mark as done, and delete study goals
- **Live Stats Dashboard** — At-a-glance totals for goals, planned hours, and completed items
- **Cloud-Backed Persistence** — Data is stored in a MySQL database, so progress is available across sessions and devices, not just on one phone
- **Pull-to-Refresh** — Reload goals from the server on demand
- **Graceful Error Handling** — Clear feedback and retry option if the server is unreachable
- **Reusable Widgets** — Modular, component-based UI architecture
- **Smooth Navigation** — Multi-screen flow between the home dashboard and the add-goal screen

---

## 🛠️ Tech Stack

### Frontend (Mobile App)
| Technology | Purpose |
|---|---|
| [Flutter](https://flutter.dev) | Cross-platform UI framework |
| [Dart](https://dart.dev) | Programming language |
| [http](https://pub.dev/packages/http) | REST API communication with the backend |

### Backend (API)
| Technology | Purpose |
|---|---|
| [Flask](https://flask.palletsprojects.com/) | Python REST API framework |
| [Flask-CORS](https://flask-cors.readthedocs.io/) | Cross-origin request support |
| [mysql-connector-python](https://pypi.org/project/mysql-connector-python/) | MySQL database driver |
| [Render](https://render.com) | Backend hosting/deployment |

### Database
| Technology | Purpose |
|---|---|
| [MySQL](https://www.mysql.com/) | Relational data storage |
| [Aiven](https://aiven.io) | Managed cloud MySQL hosting |

---

## 📱 Screenshots

<table align="center">
  <tr>
    <td align="center">
      <img src="assets/screenshots/HomeScreen.jpeg" alt="Home Screen" width="260" /><br/>
      <em>Home Screen</em>
    </td>
    <td align="center">
      <img src="assets/screenshots/AddGoalScreen.jpeg" alt="Add Goal Screen" width="260" /><br/>
      <em>Add Goal Screen</em>
    </td>
  </tr>
</table>

---

## 🏗️ Architecture

```
┌─────────────────┐       HTTPS        ┌──────────────────┐       SSL        ┌─────────────────┐
│  Flutter App     │  ───────────────▶ │  Flask API        │ ───────────────▶│  MySQL Database  │
│  (Android)       │  ◀─────────────── │  (hosted on Render)│◀─────────────── │  (hosted on Aiven)│
└─────────────────┘     JSON / REST    └──────────────────┘                  └─────────────────┘
```

The app is a thin client: all goal data lives in a MySQL database, accessed exclusively through a Flask REST API. The mobile app never talks to the database directly.

---

## 🚀 Getting Started

### Prerequisites

Make sure you have the following installed:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- [Dart SDK](https://dart.dev/get-dart) (comes bundled with Flutter)
- Android Studio or VS Code with the Flutter/Dart plugins
- An Android emulator or physical device
- Python 3.10+ (only if running the backend locally)
- Access to a MySQL instance (local or a free [Aiven](https://aiven.io) service)

### Running the Mobile App

1. **Clone the repository**
   ```bash
   git clone https://github.com/KWIZERA-FRED/Study-Planner-App.git
   cd Study-Planner-App/my_study_planner
   ```
2. **Install dependencies**
   ```bash
   flutter pub get
   ```
3. **Run the app**
   ```bash
   flutter run
   ```
   By default, the app points at the deployed Render backend, so no local backend setup is required to try it out.

### Running the Backend Locally (optional)

1. **Navigate to the backend folder**
   ```bash
   cd backend
   ```
2. **Install Python dependencies**
   ```bash
   pip install flask flask-cors mysql-connector-python
   ```
3. **Set environment variables** for your MySQL connection:
   ```bash
   export DB_HOST=your-db-host
   export DB_PORT=3306
   export DB_USER=your-db-user
   export DB_PASSWORD=your-db-password
   export DB_NAME=your-db-name
   ```
4. **Run the server**
   ```bash
   python app.py
   ```
5. **Point the app at your local server** by updating `baseUrl` in `lib/api_service.dart`.

---

## 📂 Project Structure

```
Study-Planner-App/
├── my_study_planner/
│   ├── lib/
│   │   ├── main.dart          # UI, state management, navigation
│   │   └── api_service.dart   # REST API client (goals CRUD)
│   ├── assets/
│   │   └── screenshots/       # App screenshots used in this README
│   ├── android/                # Android platform files
│   ├── ios/                     # iOS platform files
│   └── pubspec.yaml              # Project dependencies and metadata
├── backend/
│   └── app.py                  # Flask REST API + MySQL integration
└── README.md
```

---

## 🧠 How It Works

- The app maintains goal/task state in memory using Flutter's built-in state management (`setState` / `StatefulWidget`).
- On launch, and on pull-to-refresh, the app calls `GET /goals` on the Flask API to load the current list.
- Creating, updating, and deleting goals sends `POST`, `PUT`, and `DELETE` requests respectively to the Flask API, which executes the corresponding SQL statements against MySQL.
- The Flask API is stateless — every request opens its own database connection, executes the query, and closes it.
- Navigation between screens (home ↔ add goal) is handled using Flutter's `Navigator`.
- The UI is composed of reusable custom widgets to keep the codebase clean and maintainable.

---

## ⚠️ Known Limitations

- **No authentication** — all users of the app currently share the same goals list; there is no per-user login or data isolation.
- **Free-tier hosting** — the backend (Render) and database (Aiven) are on free tiers, which can spin down after periods of inactivity. The first request after idle time may take 30–60 seconds while the services wake up.

---

## 🗺️ Roadmap

- [ ] User authentication and per-user goal lists
- [ ] Due-date reminders and notifications
- [ ] Categories/tags for goals (e.g., by course)
- [ ] Calendar view
- [ ] Offline support with local caching and background sync

---

## 🤝 Contributing

This project was built for academic purposes, but suggestions and improvements are welcome.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -m "Add your feature"`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

---

## 📄 License

This project is open source and available for educational use.

---

## 👤 Author

**Fred Kwizera**
University of Lay Adventists of Kigali (UNILAK)
[GitHub](https://github.com/KWIZERA-FRED)
