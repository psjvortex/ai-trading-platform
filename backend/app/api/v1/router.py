from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.symbol import Symbol
from app.core.config import settings
from app.db.session import db_healthcheck
import os
from datetime import datetime, timezone
from app.schemas.symbol import SymbolOut, SymbolCreate, SymbolUpdate

router = APIRouter(prefix="/v1")

@router.get("/symbols")
async def list_symbols(db: Session = Depends(get_db)):
    # Simple list to validate DB path; production would add pagination
    rows = db.query(Symbol).order_by(Symbol.name.asc()).all()
    return [
        {"id": s.id, "name": s.name, "description": s.description}
        for s in rows
    ]


@router.post("/symbols", response_model=SymbolOut, status_code=201)
async def create_symbol(payload: SymbolCreate, db: Session = Depends(get_db)):
    existing = db.query(Symbol).filter(Symbol.name == payload.name).first()
    if existing:
        raise HTTPException(status_code=409, detail="Symbol already exists")
    obj = Symbol(name=payload.name, description=payload.description)
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


@router.get("/symbols/{symbol_id}", response_model=SymbolOut)
async def get_symbol(symbol_id: int, db: Session = Depends(get_db)):
    obj = db.get(Symbol, symbol_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Not found")
    return obj


@router.patch("/symbols/{symbol_id}", response_model=SymbolOut)
async def update_symbol(symbol_id: int, payload: SymbolUpdate, db: Session = Depends(get_db)):
    obj = db.get(Symbol, symbol_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Not found")
    if payload.name is not None:
        # prevent duplicate names
        existing = db.query(Symbol).filter(Symbol.name == payload.name, Symbol.id != symbol_id).first()
        if existing:
            raise HTTPException(status_code=409, detail="Symbol name already in use")
        obj.name = payload.name
    if payload.description is not None:
        obj.description = payload.description
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj


@router.delete("/symbols/{symbol_id}", status_code=204)
async def delete_symbol(symbol_id: int, db: Session = Depends(get_db)):
    obj = db.get(Symbol, symbol_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Not found")
    db.delete(obj)
    db.commit()
    return {"status": "deleted"}


@router.get("/system/info")
async def system_info():
    # Derive OTEL status from env + settings (best-effort)
    otel_disabled_env = os.getenv("OTEL_SDK_DISABLED", "").lower() in ("1", "true", "yes")
    otel_enabled = bool(settings.OTEL_EXPORTER_OTLP_ENDPOINT) and not otel_disabled_env

    # Try to fetch package version; fallback to 0.1.0
    version = "0.1.0"
    try:  # pragma: no cover
        from importlib.metadata import version as _version
        version = _version("ai-trading-backend")
    except Exception:
        pass

    return {
        "service": settings.PROJECT_NAME,
        "version": version,
        "environment": settings.TRADELOCKER_ENVIRONMENT,
        "db": "ok" if db_healthcheck() else "error",
        "otel": "enabled" if otel_enabled else "disabled",
        "time": datetime.now(timezone.utc).isoformat(),
        "cors_origins": settings.BACKEND_CORS_ORIGINS,
    }
