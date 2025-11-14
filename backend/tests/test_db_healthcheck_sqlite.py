import importlib
import os


def test_db_healthcheck_with_sqlite_in_memory(monkeypatch):
    # Point to in-memory sqlite, then reload session module to rebuild engine
    monkeypatch.setenv("POSTGRES_URL", "sqlite+pysqlite:///:memory:")
    # Reload settings and session to pick up env changes
    import app.core.config as config
    importlib.reload(config)
    import app.db.session as session
    importlib.reload(session)

    assert session.db_healthcheck() is True
