# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project adheres to Semantic Versioning.

## [Unreleased]

### Added
- Pending features per FRD v3.4 steps (integrations, strategies, RL, risk fortress, jobs, docs site).

### Changed
- **MQL5 EA v1.3 Chart Display**: Restored full detailed on-chart display from v1.1 to v1.3
  - Updated `UpdateDisplay()` function to accept 6 parameters (signal, quality, confluence, tradingZone, volRegime, entropy)
  - Replaced simplified text display with professional box-drawing character layout
  - Added 6-section display: Header, Mode, MA Crossover Status, Configuration (7 filters), Trading Status (6 metrics), Physics Metrics
  - Enhanced MA status with BULLISH/BEARISH indicators and emoji
  - Added intelligent mode detection (Pure MA Baseline, Physics Enhanced, Physics ON, Custom Mode)
  - Physics metrics default to 0.0 when disabled, read from indicator when enabled
  - Comprehensive documentation created (6 files: quick fix, patches, detailed guide, comparison, summary, index)

### Fixed
- **MQL5 EA v1.3**: Chart display now matches v1.1 professional layout with all filter states and metrics visible at a glance

## [0.1.0] - 2025-08-09

### Added
- Monorepo scaffold (backend, web, analytics), devcontainer, VS Code tasks/launch.
- Docker Compose for Postgres + API + Web. Root Makefile targets (up, down, logs, test, fmt, lint).
- Backend: FastAPI skeleton, health endpoints (/health/live, /health/ready with DB check).
- Observability: structured logging, Prometheus /metrics, optional OpenTelemetry (guarded by env).
- SQLAlchemy Base/session; initial model Symbol; API v1 router at /api/v1 with /symbols.
- Alembic configured with initial migration for symbols.
- CI: GitHub Actions for backend/web lint + tests; docker build smoke.
- Docs: Copilot prompt pack (FRD v3.4), STATUS.md.

[Unreleased]: https://example.com/compare/v0.1.0...HEAD
[0.1.0]: https://example.com/releases/v0.1.0
