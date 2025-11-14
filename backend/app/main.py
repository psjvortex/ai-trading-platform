from fastapi import FastAPI
from starlette.responses import Response
from prometheus_client import CONTENT_TYPE_LATEST, generate_latest, REGISTRY
import logging
import sys
import os

from app.core.config import settings
from app.db.session import db_healthcheck, engine
from app.api.v1.router import router as api_v1_router
from app.db.base import Base
from fastapi.middleware.cors import CORSMiddleware

# Structured logging
handler = logging.StreamHandler(sys.stdout)
formatter = logging.Formatter("%(asctime)s %(levelname)s %(name)s %(message)s")
handler.setFormatter(formatter)
root = logging.getLogger()
root.setLevel(logging.INFO)
root.handlers.clear()
root.addHandler(handler)

app = FastAPI(title=settings.PROJECT_NAME)

# CORS
if settings.BACKEND_CORS_ORIGINS:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.BACKEND_CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

# Include API routers
app.include_router(api_v1_router, prefix="/api")

# Dev bootstrap: ensure tables exist (migrations should be used in prod)
try:  # pragma: no cover - best effort
    if os.getenv("DEV_BOOTSTRAP_DB") == "1":
        Base.metadata.create_all(bind=engine)
except Exception as e:  # pragma: no cover
    logging.getLogger(__name__).warning(f"Failed to create tables: {e}")


@app.get("/health/live")
def liveness():
    return {"status": "ok"}


_OTEL_ENABLED = False


@app.get("/health/ready")
def readiness():
    db_ok = db_healthcheck()
    return {
        "status": "ready",
        "db": "ok" if db_ok else "error",
        "otel": "enabled" if _OTEL_ENABLED else "disabled",
    }


# Use default Prometheus registry so Python/process metrics are exposed
@app.get("/metrics")
def metrics():
    data = generate_latest(registry=REGISTRY)
    return Response(content=data, media_type=CONTENT_TYPE_LATEST)


# Prometheus metrics for FastAPI/uvicorn latency & throughput
try:  # best-effort; don't break app if lib missing
    from prometheus_fastapi_instrumentator import Instrumentator  # type: ignore

    running_pytest = ("PYTEST_CURRENT_TEST" in os.environ) or ("pytest" in sys.modules)
    if not running_pytest:
        # Instrument only; do not expose another /metrics endpoint
        Instrumentator().instrument(app)
        logging.getLogger(__name__).info("Prometheus instrumentator enabled")
except Exception as e:  # pragma: no cover
    logging.getLogger(__name__).warning(f"Prometheus instrumentator disabled: {e}")


# OpenTelemetry instrumentation (enabled only if endpoint configured and not under tests)
try:  # best-effort; do not crash app if OTEL not available
    import sys as _sys

    otel_disabled_env = os.getenv("OTEL_SDK_DISABLED", "").lower() in ("1", "true", "yes")
    running_pytest = ("PYTEST_CURRENT_TEST" in os.environ) or ("pytest" in _sys.modules)
    if settings.OTEL_EXPORTER_OTLP_ENDPOINT and not otel_disabled_env and not running_pytest:
        from opentelemetry import trace
        from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
        from opentelemetry.sdk.resources import Resource
        from opentelemetry.sdk.trace import TracerProvider
        from opentelemetry.sdk.trace.export import BatchSpanProcessor
        from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
        from opentelemetry.instrumentation.logging import LoggingInstrumentor

        resource = Resource.create({"service.name": "ai-trading-backend"})
        provider = TracerProvider(resource=resource)
        span_exporter = OTLPSpanExporter(endpoint=str(settings.OTEL_EXPORTER_OTLP_ENDPOINT))
        span_processor = BatchSpanProcessor(span_exporter)
        provider.add_span_processor(span_processor)
        trace.set_tracer_provider(provider)

        FastAPIInstrumentor.instrument_app(app)
        LoggingInstrumentor().instrument(set_logging_format=True)
        _OTEL_ENABLED = True
        logging.getLogger(__name__).info("OpenTelemetry instrumentation enabled")
except Exception as e:  # pragma: no cover - do not fail app on OTEL issues
    logging.getLogger(__name__).warning(f"Failed to initialize OpenTelemetry: {e}")
