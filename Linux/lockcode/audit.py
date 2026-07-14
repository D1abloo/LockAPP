from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path


class AuditStore:
    def __init__(self, path: Path | None = None) -> None:
        self.path = path or Path.home() / ".local" / "state" / "lockcode" / "audit.json"

    def read(self) -> list[dict[str, str]]:
        try:
            value = json.loads(self.path.read_text(encoding="utf-8"))
            return value if isinstance(value, list) else []
        except (OSError, json.JSONDecodeError):
            return []

    def record(self, kind: str) -> None:
        events = (self.read() + [{"at": datetime.now(timezone.utc).isoformat(), "kind": kind}])[-200:]
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.write_text(json.dumps(events, indent=2), encoding="utf-8")
        os.chmod(self.path, 0o600)

    def clear(self) -> None:
        self.path.unlink(missing_ok=True)
