from __future__ import annotations

import time
import unicodedata
from collections.abc import Callable


def valid_code(value: str) -> bool:
    return 4 <= len(value) <= 64 and all(
        unicodedata.category(char) not in {"Cc", "Cf", "Cs"} for char in value
    )


class AttemptLimiter:
    def __init__(self) -> None:
        self.failures = 0
        self.blocked_until = 0.0

    def can_attempt(self, now: float | None = None) -> bool:
        return (time.monotonic() if now is None else now) >= self.blocked_until

    def failed(self, now: float | None = None) -> int:
        self.failures += 1
        delay = 0 if self.failures < 3 else min(300, 2 ** (self.failures - 3))
        self.blocked_until = (time.monotonic() if now is None else now) + delay
        return delay

    def succeeded(self) -> None:
        self.failures = 0
        self.blocked_until = 0.0


class GrantState:
    def __init__(self) -> None:
        self._grants: dict[str, tuple[float | None, set[int]]] = {}

    def approve(self, executable: str, pid: int, minutes: int, now: float) -> None:
        self._grants[executable] = (now + minutes * 60 if minutes else None, {pid})

    def granted(self, executable: str, pid: int, now: float, living: Callable[[int], bool]) -> bool:
        grant = self._grants.get(executable)
        if grant is None:
            return False
        until, pids = grant
        if until is not None:
            if until > now:
                return True
            self._grants.pop(executable, None)
            return False
        pids.intersection_update({item for item in pids if living(item)})
        if not pids:
            self._grants.pop(executable, None)
            return False
        return pid in pids

    def invalidate_all(self) -> None:
        self._grants.clear()


class PendingRequestState:
    def __init__(self) -> None:
        self._pids: set[int] = set()
    def begin(self, pid: int) -> bool:
        if pid in self._pids: return False
        self._pids.add(pid); return True
    def complete(self, pid: int) -> None:
        self._pids.discard(pid)
    def retain(self, living: set[int]) -> None:
        self._pids.intersection_update(living)
    def drain(self) -> tuple[int, ...]:
        result = tuple(self._pids); self._pids.clear(); return result
