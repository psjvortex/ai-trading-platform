# Project Status

Updated: 2025-08-09

## Completed

- Monorepo bootstrap (backend, web, analytics), devcontainer, VS Code tasks/launch
- Docker Compose wiring: Postgres + API + Web (make up)
- Backend
  - FastAPI skeleton with `/health/live`, `/health/ready` (DB connectivity check), `/metrics`
  - Config via Pydantic Settings, including updated TradeLocker env var names
  - SQLAlchemy session factory and Base; initial model: `Symbol`
  - API v1 router mounted at `/api/v1`; `GET /api/v1/symbols`
  - Structured logging; OTEL instrumentation (enabled when OTEL_EXPORTER_OTLP_ENDPOINT is set; disabled during tests); Prometheus metrics
  - Alembic configured; initial migration for `symbols`
- Web
  - Vite + React scaffold; unit tests via Vitest
- CI
  - GitHub Actions: backend/web lint+tests, docker build

## In Progress / Next

- Add OpenTelemetry Collector to docker-compose; consider Prometheus + Grafana
- TimescaleDB and hypertables for time-series tables
- CRUD routers for symbols; trades, signals, risk, system endpoints
- Integrations: Polygon client (REST/WS), TradeLocker client (auth, orders, positions) with mocks
- Seed/fixtures and basic data access patterns

## How to Verify

- make up
- curl http://localhost:8000/health/ready → {"status":"ready","db":"ok"|"error"}
- curl http://localhost:8000/metrics
- cd backend && make test; cd web && pnpm test
- docker compose exec api alembic upgrade head

## Notes

- OTEL imports are optional and only activated when endpoint is configured; they won’t break tests.
- DEV_BOOTSTRAP_DB=1 can be used in local dev to auto-create tables without migrations.
