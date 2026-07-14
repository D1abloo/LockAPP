from __future__ import annotations

import shutil
import subprocess


def available() -> bool:
    return shutil.which("fprintd-verify") is not None


def authenticate() -> bool:
    if not available():
        return False
    try:
        result = subprocess.run(
            ["fprintd-verify"], timeout=35, capture_output=True, text=True, check=False
        )
        output = (result.stdout + result.stderr).casefold()
        return result.returncode == 0 and "verify-match" in output
    except (OSError, subprocess.TimeoutExpired):
        return False
