import importlib
import os
from fastapi.testclient import TestClient


def test_symbols_crud_flow(monkeypatch):
    # Use in-memory SQLite for isolated tests
    monkeypatch.setenv("POSTGRES_URL", "sqlite+pysqlite:///:memory:")
    import app.core.config as config
    importlib.reload(config)
    import app.db.session as session
    importlib.reload(session)

    # Import app after environment is set
    from app.main import app
    from app.db.base import Base
    from app.db.session import engine

    # Create tables for the in-memory DB
    Base.metadata.create_all(bind=engine)

    client = TestClient(app)

    # Create
    r = client.post("/api/v1/symbols", json={"name": "TEST", "description": "Test Symbol"})
    assert r.status_code in (201, 409)
    data = r.json() if r.status_code == 201 else None

    # List
    r = client.get("/api/v1/symbols")
    assert r.status_code == 200
    items = r.json()
    assert isinstance(items, list)

    # Get by id if created
    if data:
        r = client.get(f"/api/v1/symbols/{data['id']}")
        assert r.status_code == 200
        assert r.json()["name"] == "TEST"

        # Update
        r = client.patch(f"/api/v1/symbols/{data['id']}", json={"description": "Updated"})
        assert r.status_code == 200
        assert r.json()["description"] == "Updated"

        # Delete
        r = client.delete(f"/api/v1/symbols/{data['id']}")
        assert r.status_code == 204


def test_seed_idempotent(monkeypatch):
    # Use in-memory SQLite
    monkeypatch.setenv("POSTGRES_URL", "sqlite+pysqlite:///:memory:")
    import app.core.config as config
    import importlib

    importlib.reload(config)
    import app.db.session as session
    importlib.reload(session)

    from app.db.base import Base
    Base.metadata.create_all(bind=session.engine)

    from app.scripts.seed_symbols import seed_symbols
    from app.models.symbol import Symbol

    db = session.SessionLocal()
    try:
        added1 = seed_symbols(db, symbols=[("X1", "x"), ("X2", "x")])
        added2 = seed_symbols(db, symbols=[("X1", "x"), ("X2", "x")])
        assert added1 in (0, 1, 2)
        assert added2 == 0
        # Ensure uniqueness
        all_names = [s.name for s in db.query(Symbol).all()]
        assert all_names.count("X1") == 1
        assert all_names.count("X2") == 1
    finally:
        db.close()
