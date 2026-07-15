from __future__ import annotations

import hashlib
import json
import re
import shutil
import subprocess
import tempfile
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Callable
from urllib.parse import urlparse

from . import __version__

RELEASE_API = "https://api.github.com/repos/D1abloo/LockAPP/releases/latest"
Progress = Callable[[float, str], None]


@dataclass(frozen=True)
class Release:
    version: str
    name: str
    url: str
    digest: str
    size: int


def is_newer(candidate: str, current: str = __version__) -> bool:
    try:
        return tuple(map(int, candidate.split("."))) > tuple(map(int, current.split(".")))
    except ValueError:
        return False


def _package_extension() -> str:
    return ".rpm" if shutil.which("dnf") else ".deb"


def _parse_release(value: dict, extension: str | None = None) -> Release | None:
    version = str(value.get("tag_name", "")).lstrip("v")
    if not re.fullmatch(r"\d+\.\d+\.\d+", version):
        return None
    extension = extension or _package_extension()
    for asset in value.get("assets", []):
        name = str(asset.get("name", ""))
        url = str(asset.get("browser_download_url", ""))
        digest = str(asset.get("digest", ""))
        parsed = urlparse(url)
        if ("linux" in name.casefold() and name.endswith(extension) and Path(name).name == name
                and parsed.scheme == "https" and parsed.netloc == "github.com"
                and parsed.path.startswith("/D1abloo/LockAPP/releases/download/")
                and re.fullmatch(r"sha256:[0-9a-f]{64}", digest)):
            return Release(version, name, url, digest.removeprefix("sha256:"), int(asset.get("size", 0)))
    return None


def latest_release() -> Release | None:
    request = urllib.request.Request(
        RELEASE_API, headers={"User-Agent": f"LockCode-Linux/{__version__}"},
    )
    try:
        with urllib.request.urlopen(request, timeout=8) as response:
            return _parse_release(json.load(response))
    except (OSError, ValueError, TypeError, urllib.error.HTTPError):
        return None


def download_package(release: Release, destination: Path, report: Progress) -> None:
    request = urllib.request.Request(
        release.url, headers={"User-Agent": f"LockCode-Linux/{__version__}"},
    )
    digest = hashlib.sha256()
    received = 0
    with urllib.request.urlopen(request, timeout=30) as response, destination.open("wb") as package:
        try:
            total = int(response.headers.get("Content-Length", release.size)) or release.size
        except (TypeError, ValueError):
            total = release.size
        while chunk := response.read(128 * 1024):
            package.write(chunk)
            digest.update(chunk)
            received += len(chunk)
            report(min(received / total, 1.0) if total else 0.0, "Descargando actualización…")
    if digest.hexdigest() != release.digest:
        destination.unlink(missing_ok=True)
        raise RuntimeError("La firma SHA-256 de la descarga no coincide.")
    report(1.0, "Descarga verificada")


def _apt_progress(line: str) -> tuple[float, str] | None:
    parts = line.rstrip().split(":", 3)
    if len(parts) != 4 or parts[0] not in {"dlstatus", "pmstatus"}:
        return None
    try:
        return max(0.0, min(float(parts[2]) / 100, 1.0)), parts[3] or "Instalando…"
    except ValueError:
        return None


def _rpm_progress(line: str) -> tuple[float, str] | None:
    match = re.search(r"(\d+)\s*/\s*(\d+)\]?\s*$", line)
    if not match or int(match.group(2)) == 0:
        return None
    return min(int(match.group(1)) / int(match.group(2)), 1.0), "Instalando paquete RPM…"


def install_package(package: Path, report: Progress) -> None:
    if shutil.which("pkexec") is None:
        raise RuntimeError("No se encontró pkexec para solicitar permisos de instalación.")
    if package.suffix == ".rpm":
        manager = shutil.which("dnf")
        if manager is None:
            raise RuntimeError("No se encontró DNF para instalar el paquete RPM.")
        command = ["pkexec", manager, "-y", "--nogpgcheck", "install", str(package)]
        parse_progress = _rpm_progress
    else:
        command = ["pkexec", "/usr/bin/apt-get", "-o", "APT::Status-Fd=1",
                   "-o", "Dpkg::Use-Pty=0", "-y", "install", str(package)]
        parse_progress = _apt_progress
    process = subprocess.Popen(
        command,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
    )
    assert process.stdout is not None
    report(0.0, "Esperando autorización del sistema…")
    for line in process.stdout:
        if progress := parse_progress(line):
            report(*progress)
    result = process.wait()
    if result in {126, 127}:
        raise RuntimeError("La autorización de instalación fue cancelada.")
    if result:
        raise RuntimeError("Ubuntu no pudo instalar la actualización.")
    report(1.0, "Actualización instalada. Reiniciando LockCode…")


def apply(release: Release, report: Progress) -> None:
    with tempfile.TemporaryDirectory(prefix="lockcode-update-") as directory:
        package = Path(directory) / release.name
        download_package(release, package, lambda value, text: report(value * 0.5, text))
        install_package(package, lambda value, text: report(0.5 + value * 0.5, text))
