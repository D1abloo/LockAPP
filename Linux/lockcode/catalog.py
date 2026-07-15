from __future__ import annotations

import configparser
import os
import shlex
import shutil
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class InstalledApp:
    name: str
    executable: str


def manual_app(path: str) -> InstalledApp | None:
    executable = os.path.realpath(path)
    if (not os.path.isfile(executable) or not os.access(executable, os.X_OK)
            or executable in {"/usr/bin/lockcode", "/usr/lib/lockcode/lockcode.py"}):
        return None
    return InstalledApp(Path(executable).name, executable)


def load_apps(roots: list[Path] | None = None) -> list[InstalledApp]:
    roots = roots or [
        Path.home() / ".local/share/applications",
        Path("/usr/local/share/applications"),
        Path("/usr/share/applications"),
    ]
    found: dict[str, InstalledApp] = {}
    for root in roots:
        if not root.exists():
            continue
        for desktop in root.glob("*.desktop"):
            parser = configparser.ConfigParser(interpolation=None, strict=False)
            try:
                parser.read(desktop, encoding="utf-8")
                item = parser["Desktop Entry"]
                if item.get("Type") != "Application" or item.getboolean("NoDisplay", fallback=False):
                    continue
                command = shlex.split(item.get("Exec", ""))[0]
                if command.startswith("%") or command == "lockcode":
                    continue
                executable = command if os.path.isabs(command) else shutil.which(command)
                if executable and os.path.isfile(executable):
                    found[os.path.realpath(executable)] = InstalledApp(
                        item.get("Name", Path(executable).name), os.path.realpath(executable)
                    )
            except (OSError, KeyError, ValueError, IndexError):
                continue
    return sorted(found.values(), key=lambda app: app.name.casefold())
