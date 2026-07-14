from __future__ import annotations

import base64
import hashlib
import hmac
import json
import os
import subprocess

from .policy import valid_code

ITERATIONS = 210_000
ATTRIBUTES = ["application", "lockcode-linux", "type", "primary-code"]
SECRET_TOOL_TIMEOUT = 20


class SecretStore:
    """Stores only a salted derived credential in the desktop Secret Service."""

    def available(self) -> bool:
        return subprocess.call(
            ["sh", "-c", "command -v secret-tool >/dev/null 2>&1"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        ) == 0

    def has_code(self) -> bool:
        return self._lookup() is not None

    def set_code(self, code: str) -> None:
        if not valid_code(code):
            raise ValueError("El código debe tener entre 4 y 64 caracteres imprimibles.")
        payload = derive_credential(code)
        try:
            result = subprocess.run(
                ["secret-tool", "store", "--label=LockCode", *ATTRIBUTES],
                input=payload,
                text=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.PIPE,
                check=False,
                timeout=SECRET_TOOL_TIMEOUT,
            )
        except subprocess.TimeoutExpired as error:
            raise RuntimeError(
                "El llavero GNOME está bloqueado. Desbloquéalo y vuelve a intentarlo."
            ) from error
        if result.returncode:
            raise RuntimeError("Secret Service no pudo guardar la credencial.")

    def verify(self, code: str) -> bool:
        if not valid_code(code):
            return False
        payload = self._lookup()
        if payload is None:
            return False
        try:
            return verify_credential(code, payload)
        except (KeyError, ValueError, TypeError, json.JSONDecodeError):
            return False

    def _lookup(self) -> str | None:
        try:
            result = subprocess.run(
                ["secret-tool", "lookup", *ATTRIBUTES], capture_output=True, text=True,
                check=False, timeout=5,
            )
        except subprocess.TimeoutExpired:
            return None
        return result.stdout.rstrip("\n") if result.returncode == 0 and result.stdout else None


def derive_credential(code: str) -> str:
    if not valid_code(code):
        raise ValueError("Código no válido")
    salt = os.urandom(32)
    digest = hashlib.pbkdf2_hmac("sha256", code.encode(), salt, ITERATIONS, 32)
    return json.dumps({"salt": base64.b64encode(salt).decode(),
                       "hash": base64.b64encode(digest).decode(), "rounds": ITERATIONS})


def verify_credential(code: str, payload: str) -> bool:
    if not valid_code(code):
        return False
    stored = json.loads(payload)
    actual = hashlib.pbkdf2_hmac("sha256", code.encode(), base64.b64decode(stored["salt"]),
                                 int(stored["rounds"]), 32)
    return hmac.compare_digest(actual, base64.b64decode(stored["hash"]))
