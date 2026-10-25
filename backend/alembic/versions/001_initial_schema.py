"""Initial Schema Migration

Revision ID: 001_initial_schema
Revises: 
Create Date: 2026-08-04 16:38:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = '001_initial_schema'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    # 1. users table
    op.create_table(
        'users',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('email', sa.String(length=255), nullable=False, unique=True),
        sa.Column('hashed_password', sa.String(length=255), nullable=False),
        sa.Column('full_name', sa.String(length=255), nullable=True),
        sa.Column('college_id', sa.String(length=100), nullable=False, server_default='default'),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index('ix_users_email', 'users', ['email'], unique=True)

    # 2. subjects table
    op.create_table(
        'subjects',
        sa.Column('id', sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('name', sa.String(length=255), nullable=False),
        sa.Column('college_id', sa.String(length=100), nullable=False),
    )

    # 3. attendance_records table
    op.create_table(
        'attendance_records',
        sa.Column('id', sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('subject_id', sa.Integer(), sa.ForeignKey('subjects.id', ondelete='CASCADE'), nullable=False),
        sa.Column('date', sa.Date(), nullable=False),
        sa.Column('status', sa.String(length=50), nullable=False),
        sa.Column('is_lab', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('source', sa.String(length=20), nullable=False, server_default='manual'),
    )

    # 4. rule_configs table
    op.create_table(
        'rule_configs',
        sa.Column('college_id', sa.String(length=100), primary_key=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=True),
        sa.Column('threshold_pct', sa.Float(), nullable=False, server_default='75.0'),
        sa.Column('calculation_mode', sa.String(length=50), nullable=False, server_default='per_subject'),
        sa.Column('excluded_statuses', sa.JSON(), nullable=True),
        sa.Column('lab_weight_multiplier', sa.Float(), nullable=False, server_default='1.0'),
        sa.Column('per_subject_weighting', sa.JSON(), nullable=True),
    )

def downgrade() -> None:
    op.drop_table('rule_configs')
    op.drop_table('attendance_records')
    op.drop_table('subjects')
    op.drop_index('ix_users_email', table_name='users')
    op.drop_table('users')
