"""Add Sync Conflicts and Timestamps Migration

Revision ID: 002_add_sync_conflicts
Revises: 001_initial_schema
Create Date: 2026-08-04 16:46:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = '002_add_sync_conflicts'
down_revision: Union[str, None] = '001_initial_schema'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    # 1. Add updated_at to subjects
    op.add_column('subjects', sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('NOW()')))

    # 2. Add updated_at to attendance_records
    op.add_column('attendance_records', sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('NOW()')))

    # 3. Add updated_at to rule_configs
    op.add_column('rule_configs', sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('NOW()')))

    # 4. Create sync_conflicts table
    op.create_table(
        'sync_conflicts',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('entity_type', sa.String(length=50), nullable=False),
        sa.Column('entity_id', sa.String(length=100), nullable=False),
        sa.Column('server_data', sa.JSON(), nullable=True),
        sa.Column('client_data', sa.JSON(), nullable=True),
        sa.Column('resolved_via', sa.String(length=50), nullable=False),
        sa.Column('conflict_timestamp', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('NOW()')),
    )

def downgrade() -> None:
    op.drop_table('sync_conflicts')
    op.drop_column('rule_configs', 'updated_at')
    op.drop_column('attendance_records', 'updated_at')
    op.drop_column('subjects', 'updated_at')
