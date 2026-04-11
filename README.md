# Healthcare Platform

A full-stack healthcare management system built for MedAI. Supports two roles — **Doctor** and **Patient** — with appointment scheduling, medical report upload and OCR extraction, and an AI-powered health assistant.

---

## Architecture Overview

```
MedAI/
├── backend/          # FastAPI REST API (Python)
├── flutter_app/      # Mobile app (Flutter)
├── web_app/          # Web dashboard (Next.js 14)
├── docker-compose.yml
└── nginx.conf
```

### Tech Stack

| Layer | Technology |
|---|---|
| Backend API | FastAPI + SQLAlchemy (async) + PostgreSQL |
| Background Jobs | Celery + Redis |
| File Storage | MinIO (S3-compatible) |
| OCR | Tesseract + pdf2image + Claude (LLM structuring) |
| AI Chatbot | Anthropic Claude with MCP tool use + SSE streaming |
| Mobile App | Flutter + BLoC + GetIt + GoRouter |
| Web Dashboard | Next.js 14 App Router + Tailwind CSS + Zustand |
| Auth | JWT (HS256) — 15 min access tokens + 7-day rotating refresh tokens |
| Reverse Proxy | Nginx with rate limiting |

---

## Features

### Patient
- Register and log in
- Book appointments with doctors
- Upload medical reports (image or PDF)
- View OCR-extracted report data
- Chat with AI health assistant (SSE streaming)

### Doctor
- View and manage appointments (confirm, complete, no-show)
- Browse assigned patients
- Review and verify OCR-processed patient reports
- Chat with AI clinical assistant (has tool access to patient data)

---

## Project Structure

### Backend (`backend/`)

```
backend/
├── app/
│   ├── main.py                   # FastAPI app, CORS, router registration
│   ├── config.py                 # Pydantic settings (loaded from .env)
│   ├── dependencies.py           # get_current_user JWT dependency
│   ├── core/
│   │   ├── security.py           # bcrypt hashing, JWT creation/decoding
│   │   └── permissions.py        # require_doctor / require_patient RBAC
│   ├── database/
│   │   ├── session.py            # Async SQLAlchemy engine + get_db
│   │   └── base.py               # DeclarativeBase + TimestampMixin
│   ├── modules/
│   │   ├── auth/                 # Register, login, refresh, logout, /me
│   │   ├── users/                # Doctor/patient profiles, doctor listing
│   │   ├── appointments/         # CRUD with conflict detection
│   │   ├── reports/              # Upload to S3, trigger OCR, verify
│   │   ├── ocr/                  # Tesseract extractor + Claude LLM parser
│   │   └── ai/                   # Chat sessions, MCP tools, SSE streaming
│   └── workers/
│       ├── celery_app.py         # Celery config with task routing
│       ├── ocr_worker.py         # process_ocr_task (max 3 retries)
│       └── notification_worker.py # Appointment reminders
├── alembic/                      # Database migrations
├── Dockerfile
├── pyproject.toml                # Project metadata + dependencies (uv)
├── uv.lock                       # Locked dependency versions
└── .env.example
```

**API base URL:** `http://localhost:8000/api/v1`  
**Interactive docs:** `http://localhost:8000/api/docs`

#### API Endpoints

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/auth/register` | — | Create account |
| POST | `/auth/login` | — | Get access + refresh tokens |
| POST | `/auth/refresh` | — | Rotate refresh token |
| POST | `/auth/logout` | Bearer | Revoke refresh token |
| GET | `/auth/me` | Bearer | Current user |
| GET | `/users/doctors` | Bearer | List doctors (filterable) |
| GET | `/users/doctors/{id}` | Bearer | Doctor profile |
| GET/PATCH | `/users/me/profile` | Bearer | Own profile |
| GET | `/appointments` | Bearer | List appointments |
| POST | `/appointments` | Patient | Book appointment |
| PATCH | `/appointments/{id}` | Bearer | Update status |
| DELETE | `/appointments/{id}` | Patient | Cancel |
| GET | `/reports` | Bearer | List reports |
| POST | `/reports` | Patient | Upload report (multipart) |
| GET | `/reports/{id}` | Bearer | Get report + OCR data |
| POST | `/reports/{id}/verify` | Doctor | Verify report |
| GET | `/chat/sessions` | Bearer | List chat sessions |
| POST | `/chat/sessions` | Bearer | Create session |
| POST | `/chat/sessions/{id}/messages` | Bearer | Send message (SSE stream) |

#### AI Chatbot — MCP Tools

The chatbot runs an agentic loop with four tools:

| Tool | Access |
|---|---|
| `get_patient_profile` | Own profile (patient) or any patient (doctor) |
| `get_medical_reports` | Own reports or patient's reports (doctor only) |
| `get_appointments` | Own appointments |
| `search_lab_trends` | Lab value history across reports |

---

### Flutter App (`flutter_app/`)

Clean Architecture — three layers:

```
lib/
├── main.dart
├── app.dart                      # GoRouter + MaterialApp
├── injection_container.dart      # GetIt DI setup
├── core/
│   ├── constants/                # AppRoutes, ApiEndpoints
│   ├── network/dio_client.dart   # Dio + auth interceptor + token refresh
│   ├── theme/app_theme.dart
│   ├── errors/failures.dart
│   └── utils/validators.dart
├── domain/
│   ├── entities/                 # UserEntity, AppointmentEntity
│   ├── repositories/             # Abstract interfaces
│   └── usecases/                 # LoginUseCase, RegisterUseCase, etc.
├── data/
│   ├── models/                   # UserModel, AppointmentModel (fromJson)
│   ├── datasources/              # Remote datasources (Dio)
│   └── repositories/             # Implementations (store tokens in SecureStorage)
└── presentation/
    ├── auth/                     # AuthBloc, LoginPage, RegisterPage
    ├── appointments/             # AppointmentBloc, list + book pages
    ├── reports/                  # ReportBloc, list + upload pages
    ├── chatbot/                  # ChatPage (SSE streaming)
    └── dashboard/                # PatientDashboard, DoctorDashboard
```

**Routes:**

| Route | Page |
|---|---|
| `/login` | Login |
| `/register` | Register |
| `/patient/dashboard` | Patient home |
| `/doctor/dashboard` | Doctor home |
| `/appointments` | Appointment list |
| `/appointments/book` | Book appointment |
| `/reports` | Report list |
| `/reports/upload` | Upload report |
| `/chat` | AI assistant |
| `/doctor/patients` | Patient list (doctor only) |

---

### Web Dashboard (`web_app/`)

Next.js 14 App Router with route groups for role separation:

```
src/
├── app/
│   ├── layout.tsx                # Root layout + Toaster
│   ├── page.tsx                  # Redirects to /login
│   ├── globals.css               # Tailwind + component classes
│   ├── (auth)/
│   │   ├── login/page.tsx
│   │   └── register/page.tsx
│   ├── (patient)/
│   │   ├── layout.tsx            # Sidebar wrapper
│   │   └── patient/
│   │       ├── dashboard/page.tsx
│   │       ├── appointments/page.tsx
│   │       ├── appointments/book/page.tsx
│   │       ├── reports/page.tsx
│   │       ├── reports/upload/page.tsx
│   │       └── chat/page.tsx     # SSE streaming chat
│   └── (doctor)/
│       ├── layout.tsx
│       └── doctor/
│           ├── dashboard/page.tsx
│           ├── appointments/page.tsx
│           ├── patients/page.tsx
│           ├── reports/page.tsx
│           └── chat/page.tsx
├── components/layout/Sidebar.tsx # Role-aware navigation sidebar
├── lib/api-client.ts             # Axios + auth interceptor + all API helpers
├── store/auth.store.ts           # Zustand store with localStorage hydration
├── middleware.ts                 # Route protection + role-based redirects
└── types/index.ts                # Shared TypeScript types
```

---

## Getting Started

### Prerequisites

- Docker and Docker Compose
- [uv](https://docs.astral.sh/uv/) (Python package manager — install once for local backend dev)
- Python **3.13+** (matches `backend/pyproject.toml` and `backend/Dockerfile`)
- Flutter SDK 3.x
- Node.js 18+
- An Anthropic API key

### 1. Clone and configure environment

```bash

cp backend/.env.example backend/.env
# Edit backend/.env and set:
#   SECRET_KEY (min 32 chars)
#   ANTHROPIC_API_KEY
```

### 2. Start all backend services

```bash
docker compose up -d
```

This starts:
- **FastAPI** on `http://localhost:8000`
- **PostgreSQL** on `localhost:5432`
- **Redis** on `localhost:6379`
- **MinIO** on `http://localhost:9000` (console: `http://localhost:9001`)
- **Celery** worker + beat scheduler
- **Nginx** reverse proxy on `http://localhost:80`

### 3. Run database migrations

```bash
docker compose exec api alembic upgrade head
```

### 4. Start the web dashboard

```bash
cd web_app
cp .env.local.example .env.local
npm install
npm run dev
# Opens at http://localhost:3000
```

### 5. Run the Flutter app

```bash
cd flutter_app
flutter pub get
flutter run
```

---

## Development

### Backend — local without Docker

Install dependencies from `pyproject.toml` / `uv.lock`, then run the API:

```bash
cd backend
uv sync
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

On Windows, the same commands work in PowerShell or Command Prompt.

Run Celery worker separately (uses the same uv environment):

```bash
cd backend
uv run celery -A app.workers.celery_app worker --loglevel=info -Q ocr,notifications
```

You still need **PostgreSQL**, **Redis**, **MinIO**, and a configured `backend/.env` (see `backend/.env.example`). A typical workflow is `docker compose up -d` for infrastructure only, then run the API with `uv` as above.

### Running migrations

From `backend/` (with dependencies installed via `uv sync`):

```bash
cd backend

# Create a new migration
uv run alembic revision --autogenerate -m "description"

# Apply
uv run alembic upgrade head

# Rollback one step
uv run alembic downgrade -1
```

When using Docker for the API, keep using `docker compose exec api alembic ...` as in [Getting Started](#getting-started).

---

## Security Design

- **Passwords** hashed with bcrypt (cost factor 12)
- **Access tokens** expire in 15 minutes (HS256 JWT)
- **Refresh tokens** are single-use — rotated on every refresh (old token revoked, new token issued)
- **RBAC** enforced at route level (`require_doctor`, `require_patient`) and again at service level (ownership checks)
- **Rate limiting** via Nginx: 100 req/min on API, 10 req/min on auth endpoints
- **File validation** — MIME type and 20 MB size limit enforced before S3 upload
- **Audit log** for OCR operations (HIPAA compliance)

---

## Environment Variables

| Variable | Description |
|---|---|
| `SECRET_KEY` | JWT signing secret (min 32 chars) |
| `DATABASE_URL` | Async PostgreSQL URL |
| `REDIS_URL` | Redis connection string |
| `STORAGE_BACKEND` | `minio` or `s3` |
| `MINIO_ENDPOINT` | MinIO host:port |
| `ANTHROPIC_API_KEY` | Claude API key |
| `LLM_MODEL` | Claude model ID (default: `claude-haiku-4-5-20251001`) |
| `ALLOWED_ORIGINS` | Comma-separated CORS origins |

See `backend/.env.example` for the full list.

---

## Service Ports (default)

| Service | Port |
|---|---|
| Nginx (entry point) | 80 |
| FastAPI | 8000 |
| PostgreSQL | 5432 |
| Redis | 6379 |
| MinIO API | 9000 |
| MinIO Console | 9001 |
| Next.js dev | 3000 |
