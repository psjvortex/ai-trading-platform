# Copilot Prompt Pack & Build Checklist (FRD v3.4)

> Drop this file into `/docs/` (e.g., `/docs/copilot-prompt-pack.md`). Use each block as a **single Copilot Chat prompt** within VS Code. Work in order. Each prompt includes **Acceptance Criteria** to steer Copilot to done.

---

## 0) Repo Bootstrap & Conventions

**Prompt**

> You’re my lead engineer. Initialize a mono-repo named `ai-trading-platform` with a backend (`/backend` Python FastAPI), a web app (`/web` React + Vite), and an optional analytics app (`/analytics` Streamlit).
>
> **Standards**
>
> * Python deps via `uv` or `poetry`; `ruff`, `black`, `mypy`, `pytest`, `alembic`.
> * Node 20, `pnpm`, TypeScript strict, ESLint + Prettier.
> * `docker-compose` for dev; `.env.example` at root and per app.
> * Makefiles at root and per app.
> * GitHub Actions CI: lint/test/build on PR; tagged releases build images.
> * VS Code workspace with recommended extensions, debug configs for API + web, and `devcontainer.json`.
>
> **Scaffold**
>
> * Root: `README.md`, `LICENSE`, `CONTRIBUTING.md`, `SECURITY.md`, `CODEOWNERS`, `.editorconfig`, `.gitignore`.
> * Infra: `docker-compose.yml`, `infra/postgres/init.sql`, `infra/traefik/` (reverse proxy for dev), `scripts/`.
>
> **Acceptance Criteria**
>
> * `make up` starts Postgres + API + Web.
> * `make test` runs backend pytest and web unit tests.
> * F5 in VS Code attaches debuggers to API + Web.

---

## 1) Backend API Skeleton (FastAPI + Timescale/Postgres)

**Prompt**

> In `/backend`, create a FastAPI project `app/` with:
>
> * `main.py`, `api/` (v1 routers), `core/` (config, logging, security), `db/` (session, base, migrations), `models/`, `schemas/`, `services/`, `integrations/` (tradelocker, polygon, thegraph), `tasks/` (celery/apscheduler), `tests/`.
> * Config with Pydantic Settings: DB URL, broker URL, Polygon key, TradeLocker creds, rate limits.
> * SQLAlchemy + Alembic (TimescaleDB extension enabled).
> * Health endpoints: `/health/live`, `/health/ready`.
> * Observability: structured JSON logging, OpenTelemetry traces/metrics (OTLP), Prometheus `/metrics`.
>
> **Initial Models** (SQLAlchemy + Pydantic):
>
> * `Symbol`, `TradeContext`, `LearnedPattern`, `RiskLog`, `ServiceHealth`, `CostTracker`.
> * Use Timescale hypertables for `TradeContext`, `RiskLog`, `ServiceHealth`, `CostTracker`.
>
> **Routers**
>
> * `/v1/symbols` CRUD
> * `/v1/trades` (ingest, list, detail)
> * `/v1/signals` (POST decision request → returns decision + confidence + rationale)
> * `/v1/risk/events` (log + query)
> * `/v1/system/health` (service KPIs)
>
> **Acceptance Criteria**
>
> * `alembic upgrade head` succeeds.
> * `pytest -q` passes.
> * `GET /health/ready` confirms DB connectivity.

---

## 2) Data Integrations: Polygon.io & TradeLocker Clients

**Prompt**

> Create typed clients:
>
> * `/backend/integrations/polygon.py`: REST + WebSocket (1m bars, trades, aggregates). Include backfill + live stream consumer.
> * `/backend/integrations/tradelocker.py`: auth, account info, place/cancel/modify orders, positions, and webhooks for fills.
>   Implement retry with exponential backoff, circuit breaker, and per-method rate limiting.
>
> **Services**
>
> * `services/market_data.py`: backfill OHLCV to DB; stream → feature pipeline.
> * `services/execution.py`: idempotent order placement; dedupe on client order id; maps internal symbols to TL symbols.
>
> **Acceptance Criteria**
>
> * Mocked tests for clients (`httpx` + `respx`).
> * CLI: `python -m app.scripts.backfill --symbol NAS100 --from 2024-01-01`.
> * WebSocket consumer writes to DB in dev using mocks.

---

## 3) Feature Pipeline & Strategy Interfaces

**Prompt**

> Add `services/features.py` producing RSI, ATR, volatility rank, EMA(1/18), RSI divergence, session flags, regime labels.
> Define a Strategy interface `core/strategy.py` with `prepare_state()`, `generate_signal()`, `post_trade_update()`.
> Implement baseline `strategies/ema_crossover.py` returning signal + suggested SL/TP.
>
> **Acceptance Criteria**
>
> * Unit tests for feature calc edge cases (NaNs, partial windows).
> * `POST /v1/signals` (symbol, timeframe) hits pipeline → strategy and returns decision.

---

## 4) Consensus Swarm Engine (Agents + Debate)

**Prompt**

> Create `ai/consensus/` with:
>
> * Agent interface: `analyze(state) -> {opinion, confidence, rationale}`.
> * Agents: technical, sentiment (mock X/news), risk, DeFi, psycho placeholder.
> * Debate orchestrator with provider interface for Grok/Claude (start with stubs/mocks).
> * RL-weighted voting: persist per-agent weights; update using Brier score after trade outcomes with exponential decay.
>
> **API**
>
> * Extend `/v1/signals` to call consensus: returns `final_decision`, `confidence`, `explanations: Agent->rationale`, `weights`.
>
> **Acceptance Criteria**
>
> * Deterministic mode with mocked LLMs for tests.
> * Weight updates persisted and visible via `/v1/agents/weights`.

---

## 5) RL Layer (PPO via SB3) + GAN Scenarios

**Prompt**

> Add `ai/rl/` with:
>
> * `TradingEnv` (gymnasium) consuming features; actions: {skip, buy, sell, adjust\_sl\_tp, hedge}; reward = PnL – drawdown penalty.
> * PPO training loop with config yaml; model checkpointing; offline training job.
> * `ai/sim/gan.py` stub producing adversarial sequences (start with regime resampling + shock injection).
>
> **Integration**
>
> * `services/rl_decider.py`: at signal time, optionally filter/override consensus if RL confidence > threshold.
>
> **Acceptance Criteria**
>
> * `make train-rl` runs a short training epoch and emits a checkpoint.
> * Offline batch evaluation saved to `/reports/rl_eval.json`.

---

## 6) Risk Fortress

**Prompt**

> Implement `risk/fortress.py` with:
>
> * Dynamic SL/TP = f(ATR, regime).
> * Daily circuit breaker: if equity drawdown ≥ X%, disable auto-trading until next session.
> * Position limits per symbol and aggregate; correlation-aware exposure cap.
> * Biofeedback pause hook (HRV input stub via `/v1/risk/hrv`).
> * Event logging to `RiskLog`.
>
> **Execution Guard**
>
> * Wrap `services/execution.py` with risk checks/circuit breaker.
>
> **Acceptance Criteria**
>
> * Unit tests simulate drawdown trip & reset.
> * `/v1/risk/state` shows breakers, exposures, last HRV.

---

## 7) Frontend: React Dashboard (Dark, Pro)

**Prompt**

> In `/web` (Vite + React + TypeScript):
>
> * Pages: Overview, Signals, Trades, Agents, Risk, Settings.
> * Components: EquityCurve, Heatmap, DebateLog, SystemHealth, SustainabilityWidget, OrderPanel (read-only first).
> * State: Zustand or Redux Toolkit; API client with token auth.
> * Theme: dark, high-contrast; responsive grid; keyboard shortcuts; voice command placeholder.
>
> **Acceptance Criteria**
>
> * Overview shows equity curve (mock), service health, latest signal with confidence + per-agent breakdown.
> * Risk page shows circuit breaker status and exposure.
> * Settings stores API keys locally for dev (secure storage note displayed).

---

## 8) Streamlit Analytics App (Optional)

**Prompt**

> In `/analytics`, add a Streamlit app:
>
> * Tabs: Backtests, Walk-Forward, RL Reports, Cost Tracker.
> * Read from DB; plot via matplotlib/plotly.
> * Button triggers backtest job (calls backend task endpoint).
>
> **Acceptance Criteria**
>
> * Backtest tab renders sample report from DB fixtures.
> * “Run backtest” triggers backend job and updates when complete.

---

## 9) Jobs & Scheduling

**Prompt**

> Add job runner using APScheduler or Celery + Redis:
>
> * Schedules: market backfills, nightly walk-forward, RL training, agent weight updates, health checks, cost aggregation.
> * `/v1/system/jobs` to list/trigger jobs.
>
> **Acceptance Criteria**
>
> * `make scheduler` starts jobs; logs visible; manual triggers work.

---

## 10) CI/CD, Security, and Dev UX

**Prompt**

> Add GitHub Actions:
>
> * `ci.yaml`: Python lint+tests, Node lint+tests, docker build.
> * `release.yaml`: on tag, build+push images `api`, `web`, `analytics`.
>
> **Security & Compliance**
>
> * Secrets via cloud provider using GitHub OIDC (document placeholders).
> * Dependency scanning (`pip-audit`, `npm audit`) in CI.
> * Basic data retention policy doc; audit log table.
>
> **VS Code**
>
> * `.vscode/launch.json` for API (uvicorn + reload) and Web (Vite).
> * `.vscode/tasks.json` to run tests/lints.
>
> **Acceptance Criteria**
>
> * Green CI on fresh clone.
> * “Run → Start Debugging” launches both services.

---

## 11) Env, Makefiles, Docker

**Prompt**

> Create `.env.example` files (root + per app):
>
> ```env
> POSTGRES_URL=postgresql+psycopg://trader:trader@db:5432/trading
> POLYGON_API_KEY=__set_me__
> TRADELOCKER_ENVIRONMENT=demo
> TRADELOCKER_DEMO_USERNAME=__set_me__
> TRADELOCKER_DEMO_PASSWORD=__set_me__
> TRADELOCKER_DEMO_SERVER=BLU-DEMO
> TRADELOCKER_DEMO_URL=https://demo.tradelocker.com
> TRADELOCKER_DEMO_ACCOUNT_ID=__set_me__
> TRADELOCKER_DEMO_ACC_NUM=__set_me__
> TRADELOCKER_LIVE_USERNAME=
> TRADELOCKER_LIVE_PASSWORD=
> TRADELOCKER_LIVE_SERVER=
> TRADELOCKER_LIVE_URL=https://live.tradelocker.com
> TRADELOCKER_LIVE_ACCOUNT_ID=
> OTEL_EXPORTER_OTLP_ENDPOINT=http://otelcol:4318
> ```
>
> **Makefiles**
>
> * Root: `up`, `down`, `logs`, `test`, `fmt`, `lint`, `train-rl`, `backfill`.
> * Backend/Web: `dev`, `test`, `lint`, `migrate`.
>
> **Docker**
>
> * Multi-stage builds; `docker-compose.yml` wires db, api, web, redis, otelcol, traefik.
>
> **Acceptance Criteria**
>
> * `make up` → `http://localhost:5173` (web) and `http://localhost:8000/docs` (API).
> * Timescale extension enabled automatically.

---

# Build Tasks Checklist

Use this as a living checklist while you implement.

### Core Repo

* [x] Monorepo scaffold with workspace + devcontainer
* [x] Docker Compose up: DB, API, Web
* [ ] Redis, OTEL, Traefik
* [x] CI green on first PR

### Backend

* [x] FastAPI skeleton with health + metrics
* [ ] TimescaleDB migrations
* [x] Models & routers in place (initial)
* [ ] Polygon + TradeLocker clients (mock-tested)
