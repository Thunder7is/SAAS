<div align="center">

# 📚 SAAS
### Student Attendance & Academic System

*Enterprise-grade, offline-first attendance management — built with Flutter & FastAPI.*

[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.110%2B-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.11%2B-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-asyncpg-336791?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

</div>

---

## Overview

**SAAS** is a full-stack, offline-first academic attendance tracker designed for students who need precise control over their attendance across subjects. It pairs a **Flutter** cross-platform client with a **Python FastAPI** backend to deliver real-time analytics, automated portal scraping, batch import from CSV/XLSX files, and a bi-directional sync engine that works seamlessly even without internet.

> Know exactly how many classes you can skip. Know exactly how many you *need* to attend.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🔌 **Offline-First** | Full functionality via local SQLite — zero-latency reads, background sync when online |
| 📊 **Predictive Analytics** | Per-subject "safe bunks" left and classes needed to reach target % |
| 🏫 **College Rule Engine** | Configurable thresholds, medical leave, duty leave, grace margins |
| 🤖 **Portal Scraping** | Playwright-powered headless browser auto-fetches attendance from college portals |
| 📂 **CSV / XLSX Import** | Batch import attendance & timetable with customizable column mapping |
| 🔄 **Conflict Reconciliation** | Timestamp-based engine resolves offline vs. online data conflicts automatically |
| 🌗 **Dark / Light UI** | Material Design 3 Flutter shell with real-time sync status indicators |

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────┐
│          Flutter Client Application       │
│     (Clean Architecture / Material 3)     │
└────────────────┬─────────────────────────┘
                 │
    ┌────────────┴────────────┐
    │                         │
┌───▼──────────┐      ┌───────▼──────────┐
│  Local SQLite │      │  REST API Client  │
│  (sqflite)    │      │  (http package)   │
└───────────────┘      └───────┬──────────┘
                               │ JWT / HTTPS
                       ┌───────▼──────────────────┐
                       │   FastAPI Backend          │
                       │   (Async / SQLAlchemy)     │
                       └──────┬──────────┬─────────┘
                              │          │
                   ┌──────────▼─┐  ┌─────▼──────────┐
                   │ PostgreSQL  │  │ Playwright      │
                   │ (asyncpg)   │  │ (College Scraper│
                   └────────────┘  └────────────────┘
```

### Flutter — Clean Architecture Layers

```
lib/
├── data/           # Data sources (SQLite, HTTP) & Repository implementations
├── domain/         # Pure business logic — Engines, Models, Repository interfaces
│   └── usecases/   # AttendanceRuleEngine, AnalyticsEngine, SyncManager, ...
└── presentation/   # Screens, Widgets, Theme (Material 3 dark design system)
```

### Backend — FastAPI Modules

```
backend/app/
├── api/            # REST routes: /auth, /sync
├── core/           # JWT security, encryption, config
├── db/             # Async SQLAlchemy engine & session
├── models/         # ORM models: User, AttendanceRecord, SyncConflict, ...
├── schemas/        # Pydantic request/response schemas
├── scrapers/       # Playwright portal adapters (modular per college)
└── jobs/           # Background workers (data retention purger, ...)
```

---

## 🧠 Core Domain Engines

| Engine | File | Responsibility |
|---|---|---|
| `AttendanceRuleEngine` | `lib/domain/usecases/attendance_rule_engine.dart` | Policy eligibility, condonation, medical & duty leave |
| `AttendanceAnalyticsEngine` | `lib/domain/usecases/attendance_analytics_engine.dart` | Safe bunks, target %, required classes calculator |
| `FileImportEngine` | `lib/domain/usecases/file_import_engine.dart` | CSV/XLSX parsing, column mapping, row validation |
| `TimetableImportEngine` | `lib/domain/usecases/timetable_import_engine.dart` | Weekly slot extraction from spreadsheet formats |
| `ReconciliationEngine` | `lib/domain/usecases/reconciliation_engine.dart` | Offline/online conflict resolution via timestamps |
| `SyncManager` | `lib/domain/usecases/sync_manager.dart` | Sync state machine: Offline → Syncing → Synced / Conflict |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) `>=3.0.0`
- [Python](https://python.org) `>=3.11`
- [PostgreSQL](https://www.postgresql.org/download/) running locally or remote
- A `.env` file in `backend/` (see [Environment Variables](#-environment-variables))

---

### 1. Flutter Client

```bash
# Install dependencies
flutter pub get

# Run unit tests
flutter test

# Run on desktop / emulator / device
flutter run
```

---

### 2. FastAPI Backend

```bash
cd backend

# Create & activate virtual environment
python -m venv venv
# Windows:
venv\Scripts\activate
# macOS / Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Install Playwright browser (for portal scraping)
playwright install chromium

# Run database migrations
alembic upgrade head

# Start development server
uvicorn app.main:app --reload --port 8000
```

Interactive API docs will be available at: **http://localhost:8000/docs**

---

## 🔐 Environment Variables

Create a `backend/.env` file (this file is excluded from git):

```env
# Database
DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/saas_db

# Security
SECRET_KEY=your-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Encryption
ENCRYPTION_KEY=your-32-byte-fernet-key-here
```

---

## 🗄️ Database Schema

### Local SQLite (on-device)

| Table | Description |
|---|---|
| `subjects` | Subject metadata — name, code, credit weight, target % |
| `attendance_records` | Daily logs — date, status (Present / Absent / Medical / Duty), sync state |
| `rule_configs` | Institutional policy: min %, medical leave allowed, grace margin |
| `column_mappings` | CSV/XLSX import header mapping configurations |
| `timetable_entries` | Day-of-week scheduled slots per subject |

### Remote PostgreSQL (backend)

| Table | Description |
|---|---|
| `users` | Credentials, OAuth tokens, linked portal credentials |
| `attendance_records` | Synced records with server-side timestamps |
| `rule_configs` | Remote rule config per student/college |
| `sync_conflicts` | Ambiguous offline/online collisions pending resolution |

---

## 🧪 Tests

```bash
flutter test
```

| Test File | Engine Tested | Coverage |
|---|---|---|
| `test/attendance_analytics_test.dart` | `AttendanceAnalyticsEngine` | Safe bunks, min-class calc, % rounding |
| `test/attendance_rule_engine_test.dart` | `AttendanceRuleEngine` | Policy eligibility, medical & duty leaves |
| `test/file_import_engine_test.dart` | `FileImportEngine` | Column mapping, CSV parsing, malformed data |
| `test/reconciliation_engine_test.dart` | `ReconciliationEngine` | Timestamp-based conflict resolution |

---

## 🛠️ Tech Stack

### Flutter Client
| Package | Version | Purpose |
|---|---|---|
| `sqflite` / `sqflite_common_ffi` | `^2.3.0` | Local SQLite persistence |
| `path_provider` | `^2.1.2` | File system paths |
| `csv` | `^6.0.0` | CSV file parsing |
| `excel` | `^4.0.0` | XLSX file parsing |
| `http` | `^1.2.0` | REST API communication |

### Python Backend
| Package | Version | Purpose |
|---|---|---|
| `fastapi` | `>=0.110.0` | Web framework |
| `uvicorn` | `>=0.28.0` | ASGI server |
| `sqlalchemy` | `>=2.0.0` | Async ORM |
| `asyncpg` | `>=0.29.0` | PostgreSQL async driver |
| `alembic` | `>=1.13.0` | DB migrations |
| `python-jose` | `>=3.3.0` | JWT tokens |
| `passlib[bcrypt]` | `>=1.7.4` | Password hashing |
| `playwright` | `>=1.42.0` | College portal scraping |

---

## 📁 Project Structure

```
saas/
├── README.md
├── PROJECT_OVERVIEW.md         # Detailed technical documentation
├── pubspec.yaml
├── analysis_options.yaml
│
├── lib/                        # Flutter application
│   ├── main.dart
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── local/          # SQLite database helper
│   │   │   └── remote/         # HTTP sync service
│   │   └── repositories/
│   ├── domain/
│   │   ├── models/             # AttendanceRecord, Subject, RuleConfig, ...
│   │   ├── repositories/       # Abstract interfaces
│   │   └── usecases/           # Core business engines
│   └── presentation/
│       ├── screens/            # Dashboard, Timetable, Settings, Assignments
│       ├── theme/              # AppTheme (Material 3 dark/light)
│       └── widgets/            # SyncStatusIndicator, SyncSourceIndicator
│
├── backend/                    # FastAPI backend
│   ├── requirements.txt
│   ├── alembic.ini
│   ├── alembic/versions/
│   └── app/
│       ├── main.py
│       ├── api/                # /auth, /sync routes
│       ├── core/               # Config, Security, Encryption
│       ├── db/                 # Session, Base class
│       ├── jobs/               # Background workers
│       ├── models/             # SQLAlchemy ORM models
│       ├── schemas/            # Pydantic schemas
│       └── scrapers/           # Playwright adapters
│
└── test/                       # Flutter unit tests
```

---

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m 'Add your feature'`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License.

---

<div align="center">
Made with ❤️ by <a href="https://github.com/Thunder7is">Thunder7is</a>
</div>
