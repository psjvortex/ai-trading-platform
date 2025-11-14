from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "0001"
down_revision = None
branch_labels = None
depends_on = None

def upgrade() -> None:
    op.create_table(
        "symbols",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("name", sa.String(64), nullable=False, unique=True),
        sa.Column("description", sa.String(255), nullable=True),
    )
    op.create_index("ix_symbols_name", "symbols", ["name"], unique=True)


def downgrade() -> None:
    op.drop_index("ix_symbols_name", table_name="symbols")
    op.drop_table("symbols")
