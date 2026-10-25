import base64
import os
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from app.core.config import settings

def _get_fernet_key() -> bytes:
    # Derive 32-byte key from settings.SECRET_KEY
    salt = b"saas_encryption_at_rest_salt"
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=salt,
        iterations=100000,
    )
    key = base64.urlsafe_b64encode(kdf.derive(settings.SECRET_KEY.encode()))
    return key

_fernet = Fernet(_get_fernet_key())

def encrypt_field(data: str) -> str:
    if not data:
        return ""
    return _fernet.encrypt(data.encode()).decode()

def decrypt_field(encrypted_data: str) -> str:
    if not encrypted_data:
        return ""
    try:
        return _fernet.decrypt(encrypted_data.encode()).decode()
    except Exception:
        return encrypted_data
