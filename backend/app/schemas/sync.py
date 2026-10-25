from datetime import date, datetime
from typing import List, Optional
from pydantic import BaseModel

class SyncSubjectPayload(BaseModel):
    id: Optional[int] = None
    name: str
    college_id: str
    updated_at: datetime

    class Config:
        from_attributes = True

class SyncAttendancePayload(BaseModel):
    id: Optional[int] = None
    subject_id: int
    date: date
    status: str
    is_lab: bool = False
    source: str = "manual"
    updated_at: datetime

    class Config:
        from_attributes = True

class SyncRuleConfigPayload(BaseModel):
    college_id: str
    threshold_pct: float
    calculation_mode: str
    excluded_statuses: List[str]
    lab_weight_multiplier: float
    per_subject_weighting: dict
    updated_at: datetime

    class Config:
        from_attributes = True

class SyncPushRequest(BaseModel):
    subjects: List[SyncSubjectPayload] = []
    attendance_records: List[SyncAttendancePayload] = []
    rule_config: Optional[SyncRuleConfigPayload] = None
    client_sync_time: datetime

class SyncPushResponse(BaseModel):
    status: str = "success"
    processed_at: datetime
    conflicts_logged: int
    new_sync_token: str

class SyncPullResponse(BaseModel):
    new_sync_token: str
    server_time: datetime
    subjects: List[SyncSubjectPayload]
    attendance_records: List[SyncAttendancePayload]
    rule_config: Optional[SyncRuleConfigPayload] = None
