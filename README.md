# AI Trading Platform Monorepo

This monorepo contains:

- backend: FastAPI service
- web: React + Vite dashboard (TypeScript)
- analytics: Optional Streamlit analytics app

Quick start

- Prereqs: Docker, Docker Compose, VS Code
- Copy .env.example to .env at repo root and each app as needed
- make up to start Postgres + API + Web
- Open http://localhost:8000/docs and http://localhost:5173
- Press F5 in VS Code to attach debuggers (API + Web)

Targets

- make up / down / logs
- make test (backend pytest + web vitest)
- make fmt, make lint

See docs/copilot-prompt-pack.md to build the full system iteratively.

---

Status (snapshot)

Completed
- Monorepo scaffold, devcontainer, VS Code tasks/launch
- Docker Compose: DB + API + Web come up via make up
- Backend: FastAPI skeleton, health endpoints (live/ready with DB check), Prometheus /metrics
- Backend: SQLAlchemy session + Alembic wired; initial model: Symbol; API v1 router (/api/v1)
- Observability plumbing: structured logging; OTEL exporter guarded by env; metrics exposed
- CI: GitHub Actions for backend/web lint + tests + docker build

Pending (next)
- Add OTEL Collector service (and optional Prometheus/Grafana) to docker-compose
- Extend models/routers (trades, signals, risk, system)
- TimescaleDB migration setup and hypertables for time-series models
- Data integrations (Polygon, TradeLocker) with mocked tests

See docs/STATUS.md for details.
