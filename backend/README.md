# Suri Backend API

Suri Backend is the core backend service powering the Suri application. It provides authentication, image processing and validation, AI-powered wound analysis, rule-based assessment, and persistent storage of assessment results.

## Tech Stack

- FastAPI
- PostgreSQL
- SQLAlchemy
- Redis
- OpenCV
- Alembic
- Pytest
- Docker

## Architecture

```text
Request flow:
Client
  ↓
FastAPI API
  ↓
Image Validation (OpenCV quality gating)
  ↓
AI Vision Analysis
  ↓
Clinical Rule Engine (Risk scoring, recommendations, monitoring signs, referrals, follow-up)
  ↓
Assessment Explanation Service
  ↓
PostgreSQL & Redis Cache
```

The AI model produces visual observations, while the deterministic rule
engine handles risk scoring, referrals, care recommendations, monitoring signs
("What to Monitor" warning indicators), and follow-up scheduling. For in-depth
details on rule definitions, scoring tables, and schema, refer to the [Wound Assessment Rule Engine README](app/engine/README.md).

## Project Structure

```text
backend/
├── app/
│   ├── ai/              # AI inference & mock vision model
│   ├── api/             # API routes and dependencies
│   ├── core/            # Config, security, logging
│   ├── db/              # Database setup & sessions
│   ├── engine/          # Deterministic clinical rule engine (rules, scoring, monitoring, referrals)
│   ├── models/          # SQLAlchemy database models
│   ├── repository/      # Database access layers
│   ├── schemas/         # Pydantic schemas (input, output, engine)
│   ├── services/        # Business logic (wound analysis, explanation, caching, image quality)
│   └── utils/           # Shared utilities (image metrics)
├── alembic/             # Database migrations
├── tests/               # Unit and integration tests
│   └── test_engine_pkg/ # Dedicated rule engine test suite
└── scripts/             # Development utilities
```


## Setup

### Prerequisites

- Python 3.11+
- Docker

### Install

```bash
cd backend
python -m venv .venv

# Windows (PowerShell)
.venv\Scripts\Activate.ps1

# Linux/macOS
source .venv/bin/activate

pip install -r requirements.txt
```

### Start Services

```bash
docker-compose up -d
```

### Run Migrations

```bash
alembic upgrade head
```

### Start API

```bash
uvicorn app.main:app --reload --port 8000
```

API documentation:
- **Interactive OpenAPI (Swagger)**: [http://localhost:8000/docs](http://localhost:8000/docs)
- **ReDoc**: [http://localhost:8000/redoc](http://localhost:8000/redoc)

## Testing
 
```bash
# Run all tests
pytest

# Run wound assessment rule engine tests specifically
pytest tests/test_engine_pkg
```

## API

| Method | Endpoint | Description |
|---|---|---|
| GET | `/health` | Health check |
| POST | `/auth/register` | Register a user |
| POST | `/auth/login` | Authenticate a user |
| POST | `/wound/analyze` | Analyze wound images |
| GET | `/wound/assessments` | Retrieve assessment history |

## Medical Disclaimer

Suri is not a substitute for professional medical advice, diagnosis,
or clinical evaluation.