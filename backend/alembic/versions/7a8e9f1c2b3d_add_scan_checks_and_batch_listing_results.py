"""add_scan_checks_and_batch_listing_results

Revision ID: 7a8e9f1c2b3d
Revises: 2e95cddfe42a
Create Date: 2026-09-05 16:05:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '7a8e9f1c2b3d'
down_revision: Union[str, None] = '2e95cddfe42a'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'scan_checks',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('scan_id', sa.String(), nullable=False),
        sa.Column('check_id', sa.String(), nullable=False),
        sa.Column('rule_cited', sa.String(), nullable=False),
        sa.Column('result', sa.String(), nullable=False),
        sa.Column('confidence', sa.Float(), nullable=False),
        sa.Column('description', sa.String(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['scan_id'], ['scan_sessions.scan_id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_scan_checks_scan_id'), 'scan_checks', ['scan_id'], unique=False)

    op.create_table(
        'batch_listing_results',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('batch_id', sa.String(), nullable=True),
        sa.Column('listing_url', sa.String(), nullable=False),
        sa.Column('index', sa.Integer(), nullable=True),
        sa.Column('verdict', sa.String(), nullable=False),
        sa.Column('missing_fields', sa.JSON(), nullable=True),
        sa.Column('checked_by', sa.String(), nullable=False),
        sa.Column('checked_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.ForeignKeyConstraint(['batch_id'], ['batch_jobs.batch_id'], ),
        sa.ForeignKeyConstraint(['checked_by'], ['users.user_id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_batch_listing_results_batch_id'), 'batch_listing_results', ['batch_id'], unique=False)
    op.create_index(op.f('ix_batch_listing_results_checked_by'), 'batch_listing_results', ['checked_by'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_batch_listing_results_checked_by'), table_name='batch_listing_results')
    op.drop_index(op.f('ix_batch_listing_results_batch_id'), table_name='batch_listing_results')
    op.drop_table('batch_listing_results')
    op.drop_index(op.f('ix_scan_checks_scan_id'), table_name='scan_checks')
    op.drop_table('scan_checks')
