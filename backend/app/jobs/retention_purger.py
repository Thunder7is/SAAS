from datetime import datetime, timedelta, timezone
from sqlalchemy.orm import Session
from app.models.user import User
from app.models.attendance_record import AttendanceRecordModel

def purge_expired_attendance_data(db: Session) -> dict:
    """
    Scheduled job stub that purges attendance records exceeding each user's retention_days policy.
    Maintains clean database retention compliance while keeping audit metrics.
    """
    now_utc = datetime.now(timezone.utc)
    users = db.query(User).all()

    total_purged_records = 0
    affected_users = 0

    for user in users:
        cutoff_date = (now_utc - timedelta(days=user.retention_days)).date()
        
        # Purge records older than user's configured retention cutoff date
        deleted_count = db.query(AttendanceRecordModel).filter(
            AttendanceRecordModel.user_id == user.id,
            AttendanceRecordModel.date < cutoff_date
        ).delete(synchronize_session=False)

        if deleted_count > 0:
            total_purged_records += deleted_count
            affected_users += 1

    db.commit()

    return {
        "job_name": "retention_purger",
        "executed_at": now_utc.isoformat(),
        "affected_users": affected_users,
        "total_purged_records": total_purged_records,
    }
