from sqlalchemy.orm import Session
from app.db.session import SessionLocal
from app.models.symbol import Symbol

DEFAULT_SYMBOLS = [
    ("AAPL", "Apple Inc."),
    ("MSFT", "Microsoft Corporation"),
    ("GOOGL", "Alphabet Inc. Class A"),
    ("AMZN", "Amazon.com, Inc."),
    ("TSLA", "Tesla, Inc."),
    ("SPY", "SPDR S&P 500 ETF Trust"),
]


def seed_symbols(db: Session, symbols: list[tuple[str, str | None]] = DEFAULT_SYMBOLS) -> int:
    count = 0
    for name, desc in symbols:
        existing = db.query(Symbol).filter(Symbol.name == name).first()
        if existing:
            continue
        obj = Symbol(name=name, description=desc)
        db.add(obj)
        count += 1
    db.commit()
    return count


def main() -> None:
    db = SessionLocal()
    try:
        added = seed_symbols(db)
        print(f"Seeded {added} symbols (idempotent)")
    finally:
        db.close()


if __name__ == "__main__":
    main()
