import uuid
from datetime import datetime, timezone
from sqlalchemy import String, Float, JSON, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID
from app.db.base_class import Base

class RuleConfigModel(Base):
    __tablename__ = "rule_configs"

    college_id: Mapped[str] = mapped_column(String(100), primary_key=True)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=True)
    threshold_pct: Mapped[float] = mapped_column(Float, default=75.0, nullable=False)
    calculation_mode: Mapped[str] = mapped_column(String(50), default="per_subject", nullable=False)
    excluded_statuses: Mapped[dict] = mapped_column(JSON, default=list, nullable=True)
    lab_weight_multiplier: Mapped[float] = mapped_column(Float, default=1.0, nullable=False)
    per_subject_weighting: Mapped[dict] = mapped_column(JSON, default=dict, nullable=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)
