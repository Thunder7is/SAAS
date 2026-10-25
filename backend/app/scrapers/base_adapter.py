from abc import ABC, abstractmethod
from typing import Any, Dict, List, Optional
from pydantic import BaseModel

class PortalConfig(BaseModel):
    college_name: str
    login_url: str
    attendance_url: str
    username_selector: str = "#username"
    password_selector: str = "#password"
    submit_selector: str = "#submit-btn"
    captcha_selector: Optional[str] = ".captcha-container, iframe[src*='captcha']"
    two_factor_selector: Optional[str] = ".2fa-input, input[name='otp']"
    attendance_table_selector: str = "#attendance-table, table.attendance"
    row_selector: str = "tbody tr"
    subject_col_index: int = 0
    date_col_index: int = 1
    status_col_index: int = 2
    lab_col_index: Optional[int] = None

class ScraperException(Exception):
    """Base exception for portal scrapers."""
    pass

class ManualInterventionRequiredError(ScraperException):
    """Raised when CAPTCHA, 2FA, or security challenge requires human action."""
    def __init__(self, reason: str, challenge_type: str = "CAPTCHA/2FA"):
        self.reason = reason
        self.challenge_type = challenge_type
        super().__init__(f"Manual intervention required ({challenge_type}): {reason}")

class PortalLayoutDriftError(ScraperException):
    """Raised when portal selectors fail due to layout changes/drift."""
    def __init__(self, missing_selector: str, context: str):
        self.missing_selector = missing_selector
        self.context = context
        super().__init__(f"Portal layout drift detected! Selector '{missing_selector}' failed during {context}.")

class AuthenticationFailedError(ScraperException):
    """Raised when login credentials are rejected by portal."""
    def __init__(self, message: str = "Invalid credentials"):
        super().__init__(message)

class PortalScraperAdapter(ABC):
    def __init__(self, config: PortalConfig):
        self.config = config

    @abstractmethod
    async def login(self, credentials: Dict[str, str]) -> bool:
        """Authenticate user on college portal."""
        pass

    @abstractmethod
    async def navigate_to_attendance(self) -> None:
        """Navigate to student attendance page."""
        pass

    @abstractmethod
    async def extract_records(self) -> List[Dict[str, Any]]:
        """Extract attendance records into backend normalized schema."""
        pass
