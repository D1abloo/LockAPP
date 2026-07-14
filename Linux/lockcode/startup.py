from __future__ import annotations

from pathlib import Path


AUTOSTART = """[Desktop Entry]
Type=Application
Name=LockCode
Exec=/usr/bin/lockcode --background
Terminal=false
X-GNOME-Autostart-enabled=true
Comment=Protección de privacidad de aplicaciones
"""


def set_enabled(enabled: bool) -> None:
    path = Path.home() / ".config" / "autostart" / "lockcode.desktop"
    if enabled:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(AUTOSTART, encoding="utf-8")
    else:
        path.unlink(missing_ok=True)
