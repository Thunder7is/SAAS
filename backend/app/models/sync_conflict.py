import uuid
from datetime import datetime, timezone
from sqlalchemy import String, DateTime, JSON, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID
from app.db.base_class import Base

class SyncConflictModel(Base):
    __tablename__ = "sync_conflicts"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    entity_type: Mapped[str] = mapped_column(String(50), nullable=False)  # "subject", "attendance_record", "rule_config"
    entity_id: Mapped[str] = mapped_column(String(100), nullable=False)
    server_data: Mapped[dict] = mapped_column(JSON, nullable=True)
    client_data: Mapped[dict] = mapped_column(JSON, nullable=True)
    resolved_via: Mapped[str] = mapped_column(String(50), nullable=False)  # "last_write_wins_client", "last_write_wins_server"
    conflict_timestamp: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    user = relationship("User")
