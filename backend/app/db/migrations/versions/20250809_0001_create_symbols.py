"""create symbols table

Revision ID: 20250809_0001
Revises: 
Create Date: 2025-08-09 00:00:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = "20250809_0001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "symbols",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("name", sa.String(length=64), nullable=False, unique=True),
        sa.Column("description", sa.String(length=255), nullable=True),
    )
    op.create_index("ix_symbols_name", "symbols", ["name"], unique=True)


def downgrade() -> None:
    op.drop_index("ix_symbols_name", table_name="symbols")
    op.drop_table("symbols")
