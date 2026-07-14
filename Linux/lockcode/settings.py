from __future__ import annotations

import json
import os
from dataclasses import asdict, dataclass, field
from pathlib import Path


@dataclass
class Settings:
    protection_enabled: bool = True
    biometrics_enabled: bool = True
    start_with_linux: bool = True
    grace_minutes: int = 0
    protected_executables: list[str] = field(default_factory=list)


class SettingsStore:
    def __init__(self, path: Path | None = None) -> None:
        self.path = path or Path.home() / ".config" / "lockcode" / "settings.json"
        self.value = self._load()

    def _load(self) -> Settings:
        try:
            raw = json.loads(self.path.read_text(encoding="utf-8"))
            allowed = Settings.__dataclass_fields__.keys()
            return Settings(**{key: value for key, value in raw.items() if key in allowed})
        except (OSError, ValueError, TypeError):
            return Settings()

    def save(self) -> None:
        self.value.grace_minutes = max(0, min(1440, int(self.value.grace_minutes)))
        self.value.protected_executables = sorted(set(self.value.protected_executables))
        self.path.parent.mkdir(parents=True, exist_ok=True)
        temporary = self.path.with_suffix(".tmp")
        temporary.write_text(json.dumps(asdict(self.value), indent=2), encoding="utf-8")
        os.chmod(temporary, 0o600)
        temporary.replace(self.path)
