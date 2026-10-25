# SAAS - Student Attendance & Academic System
## Technical Overview & Architectural Documentation

---

### Executive Summary

**SAAS** (Student Attendance & Academic System) is an enterprise-grade, offline-first mobile and desktop application paired with a high-performance Python FastAPI backend. Designed to help students monitor, manage, and optimize their academic attendance, the platform provides automated portal scraping, customizable college rule engines, file-based batch imports (CSV/XLSX), intelligent attendance target projections ("safe bunks" vs "required classes"), and bi-directional offline-first data synchronization.

---

### System Key Features

1. **Offline-First & Hybrid Data Sync**:
   - Local SQLite database on device ensuring full offline functionality and zero-latency UI responses.
   - Background bi-directional sync with FastAPI backend and conflict reconciliation engine.

2. **Customizable College Rule Engine**:
   - Supports custom attendance rules, policy thresholds (e.g., 75% minimum requirement), grace margins, duty leaves, medical leave policies, and subject weightages.

3. **Predictive Attendance Analytics**:
   - Calculates real-time attendance percentage per subject and overall.
   - Computes exact number of classes needed to reach target percentage or "safe bunks" available before dropping below threshold.

4. **Automated College Portal Scraping**:
   - Modular Playwright adapter system capable of logging into university portals automatically to fetch latest attendance and timetable records.

5. **Flexible Batch Import & Field Mapping**:
   - Imports attendance and timetable records from CSV and Excel (`.xlsx`) files with customizable user column mapping.

6. **Interactive UI Shell**:
   - Modern, sleek Flutter dark/light responsive interface featuring real-time sync indicators, timetable schedules, dashboard metrics, and settings panel.

---

### Technical Architecture & Technology Stack

```
                  +-----------------------------------+
                  |      Flutter Client Application    |
                  |  (Presentation / BLoC/Clean Arch) |
                  +-----------------+-----------------+
                                    |
                    +---------------+---------------+
                    |                               |
          +---------v----------+          +---------v----------+
          | Local SQLite DB    |          |  Rest API Client   |
          | (sqflite / ffi)    |          |   (http package)   |
          +--------------------+          +---------+----------+
                                                    |
                                                    | HTTP / REST (JWT)
                                                    v
                                  +-----------------+-----------------+
                                  |    FastAPI Backend Application   |
                                  |    (Async Python / SQLAlchemy)   |
                                  +--------+----------------+---------+
                                           |                |
                       +-------------------+                +-------------------+
                       |                                                        |
             +---------v----------+                                   +---------v----------+
             | PostgreSQL DB      |                                   |  Playwright Engine |
             | (Asyncpg Engine)   |                                   | (College Scraper)  |
             +--------------------+                                   +--------------------+
```

#### Frontend Tech Stack (Flutter)
- **Framework**: Flutter (`>=3.0.0 <4.0.0`)
- **Architecture**: Clean Architecture (Layered: `Data`, `Domain`, `Presentation`)
- **Local Persistence**: `sqflite`, `sqflite_common_ffi`, `path_provider`
- **Parsers & Utilities**: `csv`, `excel`, `http`
- **Styling**: Material Design 3 with custom dark theme design system (`AppTheme`)

#### Backend Tech Stack (Python FastAPI)
- **Framework**: FastAPI `^0.110.0` running on Uvicorn
- **ORM & Migrations**: Async SQLAlchemy `^2.0.0`, Asyncpg driver, Alembic `^1.13.0`
- **Security & Auth**: OAuth2 / JWT authentication using `python-jose`, Passlib (`bcrypt`), `cryptography`
- **Automation / Scraping**: Playwright `^1.42.0` (Headless Browser Automation)

---

### Core Business Engines (Flutter Domain Layer)

The Flutter domain layer encapsulates the primary business rules of SAAS across 6 core engines:

1. **`AttendanceRuleEngine`** ([`lib/domain/usecases/attendance_rule_engine.dart`](file:///r:/saas/lib/domain/usecases/attendance_rule_engine.dart)):
   - Enforces institutional policies, computes eligibility, factors in condonation, medical leave, and duty leaves against threshold policies.

2. **`AttendanceAnalyticsEngine`** ([`lib/domain/usecases/attendance_analytics_engine.dart`](file:///r:/saas/lib/domain/usecases/attendance_analytics_engine.dart)):
   - Computes subject-wise and global attendance percentages, margin calculations, safe bunks left, and required consecutive classes to achieve target percentage.

3. **`FileImportEngine`** ([`lib/domain/usecases/file_import_engine.dart`](file:///r:/saas/lib/domain/usecases/file_import_engine.dart)):
   - Processes uploaded CSV/XLSX files, validates raw rows against defined `ColumnMapping`, handles errors, and transforms rows into normalized domain entities.

4. **`TimetableImportEngine`** ([`lib/domain/usecases/timetable_import_engine.dart`](file:///r:/saas/lib/domain/usecases/timetable_import_engine.dart)):
   - Extracts recurring weekly schedule slots from external spreadsheet formats into daily timetable entries.

5. **`ReconciliationEngine`** ([`lib/domain/usecases/reconciliation_engine.dart`](file:///r:/saas/lib/domain/usecases/reconciliation_engine.dart)):
   - Resolves conflicts between locally modified offline records and newly fetched backend state using timestamp comparison and version vectors.

6. **`SyncManager`** ([`lib/domain/usecases/sync_manager.dart`](file:///r:/saas/lib/domain/usecases/sync_manager.dart)):
   - Coordinates background network requests, status transitions (Offline, Syncing, Synced, Conflict), and triggers local repository updates.

---

### Directory & Project Structure

```
saas/
├── PROJECT_OVERVIEW.md                 # Project Documentation (This File)
├── pubspec.yaml                        # Flutter Project Dependencies
├── analysis_options.yaml               # Dart Linter Configuration
│
├── lib/                                # Flutter Client Codebase
│   ├── main.dart                       # App Entry Point & MaterialApp Setup
│   ├── data/                           # Data Layer
│   │   ├── datasources/
│   │   │   ├── local/                  # SQLite Database Helper & Schema Init
│   │   │   └── remote/                 # HTTP Remote Sync Service APIs
│   │   └── repositories/               # Repository Implementations
│   │
│   ├── domain/                         # Domain Layer (Pure Business Logic)
│   │   ├── models/                     # Core Domain Entities (Attendance, Subject, Rules)
│   │   ├── repositories/               # Repository Interfaces
│   │   └── usecases/                   # Core Domain Engines & Business Rules
│   │
│   └── presentation/                   # Presentation Layer (UI & Widgets)
│       ├── screens/
│       │   ├── dashboard/              # Main Dashboard Screen & Analytics Overview
│       │   ├── timetable/              # Daily/Weekly Schedule View
│       │   ├── settings/              # Rules Config & Column Mapping Settings
│       │   ├── assignments/            # Assignment Tracker Screen
│       │   └── main_shell.dart         # Bottom Navigation Shell Container
│       ├── theme/                      # App Theme Tokens & Dark/Light Styling
│       └── widgets/                    # Reusable Indicators & Components
│
├── backend/                            # FastAPI Server Codebase
│   ├── alembic/                        # Database Migration Scripts
│   ├── alembic.ini                     # Migration Settings
│   ├── requirements.txt                # Python Dependencies
│   └── app/
│       ├── main.py                     # FastAPI Application Factory & CORS
│       ├── api/                        # REST Routes (Auth, Sync)
│       ├── core/                       # App Configuration & Security Utils
│       ├── db/                         # Database Engine & Session Generators
│       ├── jobs/                       # Background Task Queue / Cron Workers
│       ├── models/                     # SQLAlchemy Database Models
│       ├── schemas/                    # Pydantic Request/Response Models
│       └── scrapers/                   # Playwright Portal Adapters
│
└── test/                               # Flutter Unit & Integration Test Suite
    ├── attendance_analytics_test.dart
    ├── attendance_rule_engine_test.dart
    ├── file_import_engine_test.dart
    ├── reconciliation_engine_test.dart
    └── sample_policies.dart
```

---

### Database Schema Highlights

#### Local SQLite Database (`database_helper.dart`)
- **`subjects`**: Stores subject metadata (ID, code, name, credit weight, target percentage).
- **`attendance_records`**: Daily class logs (ID, subject_id, date, status [Present/Absent/Medical/Duty], sync_status).
- **`rule_configs`**: Institutional policy settings (minimum_percentage, medical_leave_allowed, etc.).
- **`column_mappings`**: CSV/XLSX import header mapping configurations.
- **`timetable_entries`**: Scheduled day-of-week slots per subject.

#### Remote PostgreSQL Database (`backend/app/models`)
- **`users`**: User credentials, OAuth tokens, linked portal credentials.
- **`attendance_records`**: Synced global records with server timestamps.
- **`rule_configs`**: Remote rule configurations per student/college.
- **`sync_conflicts`**: Log of ambiguous offline/online sync collisions requiring manual or rule-based resolution.

---

### Getting Started & Running the Project

#### 1. Running the Flutter Client
```bash
# Fetch dependencies
flutter pub get

# Run unit tests
flutter test

# Run app locally (Desktop / Mobile / Emulator)
flutter run
```

#### 2. Running the FastAPI Backend
```bash
cd backend

# Create virtual environment (optional but recommended)
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Install Playwright browser binaries
playwright install chromium

# Run migrations
alembic upgrade head

# Start development server
uvicorn app.main:app --reload --port 8000
```
- API Documentation will be accessible at: `http://localhost:8000/docs`

---

### Verification & Testing Suite

The codebase comes equipped with automated unit tests verifying core engine correctness:

| Test File | Target Domain Engine | Covered Scenarios |
| :--- | :--- | :--- |
| [`test/attendance_analytics_test.dart`](file:///r:/saas/test/attendance_analytics_test.dart) | `AttendanceAnalyticsEngine` | Safe bunks, minimum class calculation, percentage rounding. |
| [`test/attendance_rule_engine_test.dart`](file:///r:/saas/test/attendance_rule_engine_test.dart) | `AttendanceRuleEngine` | Policy eligibility, medical leave exemptions, duty leave application. |
| [`test/file_import_engine_test.dart`](file:///r:/saas/test/file_import_engine_test.dart) | `FileImportEngine` | Column mapping validation, CSV parsing, malformed data handling. |
| [`test/reconciliation_engine_test.dart`](file:///r:/saas/test/reconciliation_engine_test.dart) | `ReconciliationEngine` | Offline vs online timestamp conflict resolution. |
