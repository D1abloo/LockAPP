from __future__ import annotations

import json
import urllib.error
import urllib.request

from . import __version__


def latest_version() -> str | None:
    request = urllib.request.Request(
        "https://api.github.com/repos/D1abloo/LockAPP/releases/latest",
        headers={"User-Agent": f"LockCode-Linux/{__version__}"},
    )
    try:
        with urllib.request.urlopen(request, timeout=8) as response:
            release = json.load(response)
            if not any("linux" in asset.get("name", "").casefold() for asset in release.get("assets", [])):
                return None
            tag = release.get("tag_name", "").lstrip("v")
            return tag or None
    except (OSError, ValueError, urllib.error.HTTPError):
        return None
