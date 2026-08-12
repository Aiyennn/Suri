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
Image Validation
  ↓
AI Vision Analysis
  ↓
Clinical Rule Engine
  ↓
PostgreSQL
  ↓
Redis (assessment history cache)
```

The AI model produces visual observations, while the deterministic rule
engine handles risk scoring, referrals, recommendations, and follow-ups.

## Project Structure

```text
backend/
├── app/
│   ├── ai/              # AI inference
│   ├── api/             # API routes
│   ├── core/            # Config, security, logging
│   ├── db/              # Database setup
│   ├── engine/          # Rule-based assessment engine
│   ├── models/          # SQLAlchemy models
│   ├── repository/      # Database access
│   ├── schemas/         # Pydantic schemas
│   ├── services/        # Business logic
│   └── utils/           # Shared utilities
├── alembic/             # Database migrations
├── tests/               # Unit and integration tests
└── scripts/              # Development utilities
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
pytest
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