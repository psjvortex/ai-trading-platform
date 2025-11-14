from importlib import import_module

# Support running tests whether 'app' is importable or not by tweaking sys.path
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

client = TestClient(app)


def test_liveness():
    r = client.get("/health/live")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_readiness():
    r = client.get("/health/ready")
    assert r.status_code == 200
    data = r.json()
    assert data["status"] == "ready"
    assert data["db"] in {"ok", "error"}
