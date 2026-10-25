import asyncio
from datetime import datetime
from typing import Any, Dict, List
from playwright.async_api import Page, async_playwright

from app.scrapers.base_adapter import (
    AuthenticationFailedError,
    ManualInterventionRequiredError,
    PortalConfig,
    PortalLayoutDriftError,
    PortalScraperAdapter,
)

class PilotCollegeConfig(PortalConfig):
    college_name: str = "Pilot Engineering College"
    login_url: str = "https://pilot-portal.college.edu/login"
    attendance_url: str = "https://pilot-portal.college.edu/student/attendance"
    username_selector: str = "input#user_code"
    password_selector: str = "input#user_pass"
    submit_selector: str = "button#btn_login"
    captcha_selector: str = "div.g-recaptcha, iframe[title*='recaptcha']"
    two_factor_selector: str = "input#otp_code"
    attendance_table_selector: str = "table#tbl_student_attendance"
    row_selector: str = "tbody tr"
    subject_col_index: int = 0
    date_col_index: int = 1
    status_col_index: int = 2
    lab_col_index: int = 3

class PilotCollegeScraperAdapter(PortalScraperAdapter):
    def __init__(self, config: PortalConfig = PilotCollegeConfig()):
        super().__init__(config)
        self._browser = None
        self._page: Page = None

    async def init_browser(self):
        playwright = await async_playwright().start()
        self._browser = await playwright.chromium.launch(headless=True)
        self._page = await self._browser.new_page()

    async def login(self, credentials: Dict[str, str]) -> bool:
        if not self._page:
            await self.init_browser()

        try:
            await self._page.goto(self.config.login_url, timeout=15000)
        except Exception as e:
            raise PortalLayoutDriftError(self.config.login_url, f"Initial page load failed: {e}")

        # Check for CAPTCHA or 2FA challenge
        if self.config.captcha_selector:
            captcha_elem = await self._page.query_selector(self.config.captcha_selector)
            if captcha_elem and await captcha_elem.is_visible():
                raise ManualInterventionRequiredError("reCAPTCHA challenge detected on login page", "CAPTCHA")

        # Fill credentials
        try:
            await self._page.fill(self.config.username_selector, credentials.get("username", ""))
            await self._page.fill(self.config.password_selector, credentials.get("password", ""))
            await self._page.click(self.config.submit_selector)
        except Exception as e:
            raise PortalLayoutDriftError(self.config.username_selector, f"Login form interaction: {e}")

        await self._page.wait_for_load_state("networkidle")

        # Check for 2FA prompt after submit
        if self.config.two_factor_selector:
            two_fa_elem = await self._page.query_selector(self.config.two_factor_selector)
            if two_fa_elem and await two_fa_elem.is_visible():
                raise ManualInterventionRequiredError("OTP / 2FA code entry required", "2FA")

        # Check login success
        if "login" in self._page.url.lower():
            raise AuthenticationFailedError("Portal login failed. Please verify credentials.")

        return True

    async def navigate_to_attendance(self) -> None:
        try:
            await self._page.goto(self.config.attendance_url, timeout=15000)
            await self._page.wait_for_selector(self.config.attendance_table_selector, timeout=10000)
        except Exception as e:
            raise PortalLayoutDriftError(
                self.config.attendance_table_selector,
                f"Navigating to attendance table: {e}"
            )

    async def extract_records(self) -> List[Dict[str, Any]]:
        table_elem = await self._page.query_selector(self.config.attendance_table_selector)
        if not table_elem:
            raise PortalLayoutDriftError(self.config.attendance_table_selector, "Extracting attendance table")

        rows = await self._page.query_selector_all(f"{self.config.attendance_table_selector} {self.config.row_selector}")
        if not rows:
            return []

        extracted_records = []
        for idx, row in enumerate(rows):
            cells = await row.query_selector_all("td")
            if len(cells) <= max(self.config.subject_col_index, self.config.date_col_index, self.config.status_col_index):
                continue

            raw_subject = (await cells[self.config.subject_col_index].inner_text()).strip()
            raw_date = (await cells[self.config.date_col_index].inner_text()).strip()
            raw_status = (await cells[self.config.status_col_index].inner_text()).strip()

            raw_is_lab = False
            if self.config.lab_col_index is not None and len(cells) > self.config.lab_col_index:
                lab_txt = (await cells[self.config.lab_col_index].inner_text()).strip().lower()
                raw_is_lab = "lab" in lab_txt or "practical" in lab_txt

            extracted_records.append({
                "subject_name": raw_subject,
                "date": raw_date,
                "status": raw_status,
                "is_lab": raw_is_lab,
                "source": "auto_scrape",
            })

        return extracted_records

    async def close(self):
        if self._browser:
            await self._browser.close()
