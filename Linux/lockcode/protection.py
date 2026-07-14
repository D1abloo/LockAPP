from __future__ import annotations

import os
import queue
import signal
import threading
import time
from dataclasses import dataclass

from .settings import SettingsStore
from .policy import GrantState, PendingRequestState


@dataclass(frozen=True)
class AccessRequest:
    pid: int
    executable: str


class ProtectionService:
    """Best-effort process monitor. SIGSTOP prevents further drawing until authentication."""

    def __init__(self, settings: SettingsStore) -> None:
        self.settings = settings
        self.requests: queue.Queue[AccessRequest] = queue.Queue()
        self._pending = PendingRequestState()
        self._grants = GrantState()
        self._stop = threading.Event()
        self._thread = threading.Thread(target=self._run, name="lockcode-monitor", daemon=True)

    def start(self) -> None:
        self._thread.start()

    def close(self) -> None:
        self._stop.set()
        self._thread.join(timeout=1)
        for pid in self._pending.drain():
            self._signal(pid, signal.SIGCONT)

    def lock_now(self) -> None:
        self._grants.invalidate_all()

    def approve(self, request: AccessRequest) -> None:
        self._pending.complete(request.pid)
        minutes = self.settings.value.grace_minutes
        self._grants.approve(request.executable, request.pid, minutes, time.monotonic())
        self._signal(request.pid, signal.SIGCONT)

    def deny(self, request: AccessRequest) -> None:
        # SIGTERM is the standard request for a normal Unix shutdown; never SIGKILL.
        self._signal(request.pid, signal.SIGTERM)
        self._signal(request.pid, signal.SIGCONT)

    def _run(self) -> None:
        while not self._stop.wait(0.10):
            if not self.settings.value.protection_enabled:
                continue
            protected = set(self.settings.value.protected_executables)
            proc_names = os.listdir("/proc")
            self._pending.retain({int(name) for name in proc_names if name.isdigit()})
            for name in proc_names:
                if not name.isdigit():
                    continue
                pid = int(name)
                try:
                    executable = os.path.realpath(os.readlink(f"/proc/{pid}/exe"))
                except OSError:
                    continue
                if executable not in protected or pid == os.getpid() or self._granted(executable, pid):
                    continue
                self._signal(pid, signal.SIGSTOP)
                if self._pending.begin(pid):
                    self.requests.put(AccessRequest(pid, executable))

    def _granted(self, executable: str, pid: int) -> bool:
        return self._grants.granted(
            executable, pid, time.monotonic(), lambda item: os.path.exists(f"/proc/{item}")
        )

    @staticmethod
    def _signal(pid: int, action: signal.Signals) -> None:
        try:
            os.kill(pid, action)
        except (ProcessLookupError, PermissionError):
            pass
