from __future__ import annotations

import subprocess
from pathlib import Path

def set_enabled(enabled: bool) -> None:
    # Migrate the old XDG entry: running both it and systemd caused duplicate activation prompts.
    (Path.home() / ".config" / "autostart" / "lockcode.desktop").unlink(missing_ok=True)
    subprocess.run(
        ["systemctl", "--user", "enable" if enabled else "disable", "lockcode.service"],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False, timeout=5,
    )
