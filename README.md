# Healthcare Platform

A full-stack healthcare management system built for MedAI. Supports two roles — **Doctor** and **Patient** — with appointment scheduling, medical report upload and multimodal OCR extraction, incident reporting with AI vision analysis, and an AI-powered health assistant.

---

## Architecture Overview

```
MedAI/
├── backend/          # FastAPI REST API (Python)
├── mobile_app/       # Mobile app (Flutter)
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
| OCR (PDF) | PyPDF2 (native text extraction) |
| OCR (Images) | Google Gemini 1.5 Pro (multimodal vision) via OpenRouter |
| LLM Structuring | OpenRouter (vision-capable model) — no Tesseract dependency |
| AI Chatbot | Anthropic Claude with MCP tool use + SSE streaming |
| Incident Analysis | OpenAI GPT-4o-mini (vision) via OpenRouter |
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
- View structured OCR-extracted report data (meta grid + results table)
- **Delete** own reports
- Upload incident photos for AI injury analysis
- **Delete** own incidents
- Chat with AI health assistant (SSE streaming)

### Doctor
- View and manage appointments (confirm, complete, no-show)
- Browse assigned patients
- Review and verify OCR-processed patient reports with editable data
- Chat with AI clinical assistant (has tool access to patient data)

---

## OCR Pipeline

Medical reports are processed as follows based on file type:

```
Upload (image or PDF)
        │
        ├── PDF ──▶ PyPDF2 (native text extraction)
        │                  │
        │                  ▼
        │           text sent to LLM for structuring
        │
        └── Image ──▶ Encoded as base64
                           │
                           ▼
                    Google Gemini 1.5 Pro (via OpenRouter)
                    — Direct image understanding, no OCR step
                           │
                           ▼
              Structured JSON (test_name, lab_name, patient_name,
                report_date, doctor_name, results[])
                           │
                           ▼
                    Stored in extracted_report_data table
                    Returned to both Patient and Doctor views
```

Extracted results are displayed as:
- **Meta grid** — Test Name, Lab Name, Patient Name, Report Date, Doctor Name (shown even when null as `—`)
- **Results table** — Parameter, Value, Unit, Reference Range, Flag (with High/Low highlighting)

---

## Project Structure

### Backend (`backend/`)

```
backend/
├── app/
│   ├── main.py                   # FastAPI app, CORS, router registration, resilient DB startup
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
│   │   ├── reports/              # Upload to S3, trigger OCR, verify, delete
│   │   ├── incidents/            # Upload photo, GPT-4o vision analysis, delete
│   │   ├── ocr/                  # PyPDF2 + Gemini 1.5 Pro multimodal parser
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
**Interactive docs:** `http://localhost:8000/docs`

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
| GET | `/reports/{id}` | Bearer | Get report + extracted OCR data |
| PATCH | `/reports/{id}` | Patient | Update report title |
| DELETE | `/reports/{id}` | Bearer | Delete report + file |
| PATCH | `/reports/{id}/verify` | Doctor | Verify/edit extracted data |
| GET | `/incidents` | Bearer | List incidents |
| POST | `/incidents/upload` | Patient | Upload incident photo (AI analysis) |
| GET | `/incidents/{id}` | Bearer | Get incident |
| DELETE | `/incidents/{id}` | Bearer | Delete incident + file |
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

### Flutter App (`mobile_app/`)

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
    ├── reports/                  # ReportBloc, list + detail pages
    │   └── pages/report_detail_page.dart  # Meta grid + results DataTable + delete
    ├── incidents/                # IncidentBloc, list + upload + detail pages
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
| `/reports/:id` | Report detail (meta grid + results table + delete) |
| `/incidents` | Incident list |
| `/incidents/upload` | Upload incident photo |
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
│   │       ├── reports/page.tsx  # Report list + detail (meta grid + table + delete)
│   │       ├── incidents/page.tsx
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
- An OpenRouter API key (for report OCR + incident analysis)
- An Anthropic API key (for AI chatbot)

### 1. Clone and configure environment

```bash
cp backend/.env.example backend/.env
# Edit backend/.env — set at minimum:
#   SECRET_KEY          (min 32 chars)
#   ANTHROPIC_API_KEY   (for AI chatbot)
#   OPENROUTER_API_KEY  (for OCR + incident vision)
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

> The API performs a resilient startup — it will retry the database connection up to 10 times (3-second intervals) before giving up, so the API container no longer crashes if PostgreSQL is momentarily unavailable on first boot.

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
cd mobile_app
flutter pub get
flutter run
```

---

## Development

### Backend — local without Docker

```bash
cd backend
uv sync
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Run Celery worker separately:

```bash
cd backend
uv run celery -A app.workers.celery_app worker --loglevel=info -Q ocr,notifications
```

You still need **PostgreSQL**, **Redis**, **MinIO**, and a configured `backend/.env`. A typical workflow is `docker compose up -d` for infrastructure only, then run the API with `uv` as above.

### Running migrations

```bash
cd backend

# Create a new migration
uv run alembic revision --autogenerate -m "description"

# Apply
uv run alembic upgrade head

# Rollback one step
uv run alembic downgrade -1
```

---

## Recent Updates (May 2026)

### Multimodal OCR Pipeline
- **Removed Tesseract**: The old pipeline (Tesseract → LLM text structuring) is fully replaced.
- **PDFs**: Parsed natively with **PyPDF2** (fast, lossless text extraction).
- **Images**: Sent directly as base64 to **Google Gemini 1.5 Pro** via OpenRouter — the model reads the image and structures it in one pass.
- **Result**: Far superior accuracy for complex medical lab reports, printed text, and mixed-format documents.

### Report & Incident Delete
- Patients and doctors can now **delete reports** from the detail page (web + mobile). The backend deletes both the DB row and the underlying file from object storage.
- Incidents already had a delete button; reports are now at parity.

### Unified Report Detail UI (Web + Mobile Parity)
- Both platforms now show identical structured layouts:
  - **Metadata grid** — 5 cards (Test Name, Lab Name, Patient Name, Report Date, Doctor Name). Cards render even when data is null, showing `—` as a placeholder.
  - **Results DataTable** — Parameter / Value / Unit / Reference Range / Flag, with red badge highlighting for `HIGH`/`LOW` flags.
- Patient view matches Doctor view layout on the web.

### Backend Startup Resilience
- `startup_event` in `main.py` now retries DB connection up to **10 times** (3-second delay each) using the shared SQLAlchemy engine. Eliminates crash loops when the API container starts before PostgreSQL is ready.

### Mobile App Performance & UI
- Eliminated GPU compositing overhead by removing `BackdropFilter`/`ImageFilter.blur` in nav bars and cards.
- Fixed animation lifecycle issues in dashboard stat cards.
- Added `RepaintBoundary` isolation for hero card and stat strip.
- Animated splash screen with session resolution in parallel.

---

## Security Design

- **Passwords** hashed with bcrypt (cost factor 12)
- **Access tokens** expire in 15 minutes (HS256 JWT)
- **Refresh tokens** are single-use — rotated on every refresh
- **RBAC** enforced at route level (`require_doctor`, `require_patient`) and at service level (ownership checks)
- **Rate limiting** via Nginx: 100 req/min on API, 10 req/min on auth endpoints
- **File validation** — MIME type and 20 MB size limit enforced before S3 upload

---

## Environment Variables

| Variable | Description |
|---|---|
| `SECRET_KEY` | JWT signing secret (min 32 chars) |
| `DATABASE_URL` | Async PostgreSQL URL |
| `REDIS_URL` | Redis connection string |
| `STORAGE_BACKEND` | `minio` or `s3` |
| `MINIO_ENDPOINT` | MinIO host:port |
| `ANTHROPIC_API_KEY` | Claude API key (chatbot) |
| `LLM_MODEL` | Claude model ID (default: `claude-haiku-4-5-20251001`) |
| `OPENROUTER_API_KEY` | OpenRouter key (OCR + incident vision) |
| `OPENROUTER_MODEL` | Fallback LLM for text-based parsing |
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
