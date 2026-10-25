from datetime import datetime, timezone
from typing import Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.attendance_record import AttendanceRecordModel
from app.models.rule_config import RuleConfigModel
from app.models.subject import Subject
from app.models.sync_conflict import SyncConflictModel
from app.models.user import User
from app.schemas.sync import (
    SyncAttendancePayload,
    SyncPullResponse,
    SyncPushRequest,
    SyncPushResponse,
    SyncRuleConfigPayload,
    SyncSubjectPayload,
)

router = APIRouter(prefix="/sync", tags=["Synchronization"])

@router.post("/push", response_model=SyncPushResponse)
def push_sync(
    payload: SyncPushRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    now_utc = datetime.now(timezone.utc)
    conflicts_logged = 0

    # 1. Process Subjects Push (Last-Write-Wins with Conflict Audit Logging)
    for client_sub in payload.subjects:
        server_sub = None
        if client_sub.id:
            server_sub = db.query(Subject).filter(
                Subject.id == client_sub.id,
                Subject.user_id == current_user.id
            ).first()

        if not server_sub:
            # Brand new subject on server
            new_sub = Subject(
                user_id=current_user.id,
                name=client_sub.name,
                college_id=client_sub.college_id,
                updated_at=client_sub.updated_at,
            )
            db.add(new_sub)
        else:
            # Existing subject -> Conflict check via timestamp
            server_data = {"id": server_sub.id, "name": server_sub.name, "updated_at": server_sub.updated_at.isoformat()}
            client_data = client_sub.model_dump(mode="json")

            if client_sub.updated_at > server_sub.updated_at:
                # Client Wins
                conflict = SyncConflictModel(
                    user_id=current_user.id,
                    entity_type="subject",
                    entity_id=str(server_sub.id),
                    server_data=server_data,
                    client_data=client_data,
                    resolved_via="last_write_wins_client",
                    conflict_timestamp=now_utc,
                )
                db.add(conflict)
                conflicts_logged += 1

                server_sub.name = client_sub.name
                server_sub.college_id = client_sub.college_id
                server_sub.updated_at = client_sub.updated_at
            elif server_sub.updated_at > client_sub.updated_at:
                # Server Wins
                conflict = SyncConflictModel(
                    user_id=current_user.id,
                    entity_type="subject",
                    entity_id=str(server_sub.id),
                    server_data=server_data,
                    client_data=client_data,
                    resolved_via="last_write_wins_server",
                    conflict_timestamp=now_utc,
                )
                db.add(conflict)
                conflicts_logged += 1

    # 2. Process Attendance Records Push (Last-Write-Wins with Conflict Audit Logging)
    for client_rec in payload.attendance_records:
        server_rec = None
        if client_rec.id:
            server_rec = db.query(AttendanceRecordModel).filter(
                AttendanceRecordModel.id == client_rec.id,
                AttendanceRecordModel.user_id == current_user.id
            ).first()

        if not server_rec:
            # Search by unique business key (subject_id + date)
            server_rec = db.query(AttendanceRecordModel).filter(
                AttendanceRecordModel.subject_id == client_rec.subject_id,
                AttendanceRecordModel.date == client_rec.date,
                AttendanceRecordModel.user_id == current_user.id
            ).first()

        if not server_rec:
            # Brand new record
            new_rec = AttendanceRecordModel(
                user_id=current_user.id,
                subject_id=client_rec.subject_id,
                date=client_rec.date,
                status=client_rec.status,
                is_lab=client_rec.is_lab,
                source=client_rec.source,
                updated_at=client_rec.updated_at,
            )
            db.add(new_rec)
        else:
            server_data = {
                "id": server_rec.id,
                "subject_id": server_rec.subject_id,
                "date": server_rec.date.isoformat(),
                "status": server_rec.status,
                "source": server_rec.source,
                "updated_at": server_rec.updated_at.isoformat(),
            }
            client_data = client_rec.model_dump(mode="json")

            if client_rec.updated_at > server_rec.updated_at:
                # Client Wins
                conflict = SyncConflictModel(
                    user_id=current_user.id,
                    entity_type="attendance_record",
                    entity_id=str(server_rec.id),
                    server_data=server_data,
                    client_data=client_data,
                    resolved_via="last_write_wins_client",
                    conflict_timestamp=now_utc,
                )
                db.add(conflict)
                conflicts_logged += 1

                server_rec.status = client_rec.status
                server_rec.is_lab = client_rec.is_lab
                server_rec.source = client_rec.source
                server_rec.updated_at = client_rec.updated_at
            elif server_rec.updated_at > client_rec.updated_at:
                # Server Wins
                conflict = SyncConflictModel(
                    user_id=current_user.id,
                    entity_type="attendance_record",
                    entity_id=str(server_rec.id),
                    server_data=server_data,
                    client_data=client_data,
                    resolved_via="last_write_wins_server",
                    conflict_timestamp=now_utc,
                )
                db.add(conflict)
                conflicts_logged += 1

    # 3. Process Rule Config Push
    if payload.rule_config:
        client_cfg = payload.rule_config
        server_cfg = db.query(RuleConfigModel).filter(
            RuleConfigModel.college_id == client_cfg.college_id
        ).first()

        if not server_cfg:
            new_cfg = RuleConfigModel(
                college_id=client_cfg.college_id,
                user_id=current_user.id,
                threshold_pct=client_cfg.threshold_pct,
                calculation_mode=client_cfg.calculation_mode,
                excluded_statuses=client_cfg.excluded_statuses,
                lab_weight_multiplier=client_cfg.lab_weight_multiplier,
                per_subject_weighting=client_cfg.per_subject_weighting,
                updated_at=client_cfg.updated_at,
            )
            db.add(new_cfg)
        else:
            if client_cfg.updated_at > server_cfg.updated_at:
                conflict = SyncConflictModel(
                    user_id=current_user.id,
                    entity_type="rule_config",
                    entity_id=server_cfg.college_id,
                    server_data={"threshold_pct": server_cfg.threshold_pct, "updated_at": server_cfg.updated_at.isoformat()},
                    client_data=client_cfg.model_dump(mode="json"),
                    resolved_via="last_write_wins_client",
                    conflict_timestamp=now_utc,
                )
                db.add(conflict)
                conflicts_logged += 1

                server_cfg.threshold_pct = client_cfg.threshold_pct
                server_cfg.calculation_mode = client_cfg.calculation_mode
                server_cfg.excluded_statuses = client_cfg.excluded_statuses
                server_cfg.lab_weight_multiplier = client_cfg.lab_weight_multiplier
                server_cfg.per_subject_weighting = client_cfg.per_subject_weighting
                server_cfg.updated_at = client_cfg.updated_at

    db.commit()

    new_sync_token = now_utc.isoformat()
    return SyncPushResponse(
        status="success",
        processed_at=now_utc,
        conflicts_logged=conflicts_logged,
        new_sync_token=new_sync_token,
    )

@router.get("/pull", response_model=SyncPullResponse)
def pull_sync(
    last_sync_token: Optional[str] = Query(None, description="ISO timestamp token of last sync"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    now_utc = datetime.now(timezone.utc)
    since_time: Optional[datetime] = None

    if last_sync_token:
        try:
            since_time = datetime.fromisoformat(last_sync_token)
        except ValueError:
            since_time = None

    # Query delta changes for user
    sub_query = db.query(Subject).filter(Subject.user_id == current_user.id)
    att_query = db.query(AttendanceRecordModel).filter(AttendanceRecordModel.user_id == current_user.id)
    cfg_query = db.query(RuleConfigModel).filter(
        (RuleConfigModel.user_id == current_user.id) | (RuleConfigModel.college_id == current_user.college_id)
    )

    if since_time:
        sub_query = sub_query.filter(Subject.updated_at > since_time)
        att_query = att_query.filter(AttendanceRecordModel.updated_at > since_time)
        cfg_query = cfg_query.filter(RuleConfigModel.updated_at > since_time)

    subjects = sub_query.all()
    attendance_records = att_query.all()
    rule_config = cfg_query.first()

    return SyncPullResponse(
        new_sync_token=now_utc.isoformat(),
        server_time=now_utc,
        subjects=[SyncSubjectPayload.model_validate(s) for s in subjects],
        attendance_records=[SyncAttendancePayload.model_validate(a) for a in attendance_records],
        rule_config=SyncRuleConfigPayload.model_validate(rule_config) if rule_config else None,
    )
