from importlib import import_module

# Robust import path handling like other tests
try:
    from app.main import app  # type: ignore
except Exception:  # pragma: no cover
    import os
    import sys

    backend_root = os.path.dirname(os.path.abspath(__file__))
    backend_dir = os.path.abspath(os.path.join(backend_root, "."))
    if backend_dir not in sys.path:
        sys.path.insert(0, backend_dir)
    app = import_module("app.main").app  # type: ignore

from fastapi.testclient import TestClient
from prometheus_client import CONTENT_TYPE_LATEST

client = TestClient(app)


def test_metrics_endpoint_exposes_prometheus():
    r = client.get("/metrics")
    assert r.status_code == 200
    # Content-Type matches Prometheus exposition format
    assert r.headers.get("content-type") == CONTENT_TYPE_LATEST
    assert len(r.text) > 0
