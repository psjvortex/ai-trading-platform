"""timeseries tables for candles

Revision ID: 20250809_0002
Revises: 20250809_0001
Create Date: 2025-08-09 00:30:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = "20250809_0002"
down_revision: Union[str, None] = "20250809_0001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "candles",
        sa.Column("id", sa.BigInteger(), primary_key=True, autoincrement=True),
        sa.Column("symbol_id", sa.Integer(), nullable=False),
        sa.Column("ts", sa.DateTime(timezone=True), nullable=False),
        sa.Column("open", sa.Numeric(18, 8), nullable=False),
        sa.Column("high", sa.Numeric(18, 8), nullable=False),
        sa.Column("low", sa.Numeric(18, 8), nullable=False),
        sa.Column("close", sa.Numeric(18, 8), nullable=False),
        sa.Column("volume", sa.Numeric(20, 4), nullable=True),
        sa.ForeignKeyConstraint(["symbol_id"], ["symbols.id"], ondelete="CASCADE"),
        sa.UniqueConstraint("symbol_id", "ts", name="uq_candles_symbol_ts"),
    )

    # Convert to hypertable (TimescaleDB). If extension not available, ignore.
    op.execute(
        """
        DO $$
        BEGIN
          IF EXISTS (SELECT 1 FROM pg_extension WHERE extname='timescaledb') THEN
            PERFORM create_hypertable('candles', 'ts', if_not_exists => TRUE);
          END IF;
        END$$;
        """
    )


def downgrade() -> None:
    op.drop_table("candles")
