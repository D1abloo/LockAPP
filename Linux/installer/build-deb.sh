#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="0.1.5"
STAGE="$ROOT/build/lockcode_${VERSION}_all"
OUTPUT="$ROOT/build/lockcode-linux_${VERSION}_all.deb"

cd "$ROOT"
python3 -m unittest discover -s tests -v
python3 -m compileall -q lockcode
rm -rf "$STAGE"
install -d "$STAGE/DEBIAN" "$STAGE/usr/lib/lockcode" "$STAGE/usr/bin"
install -d "$STAGE/usr/share/applications" "$STAGE/usr/share/icons/hicolor/scalable/apps"
install -d "$STAGE/usr/lib/systemd/user"
cp -R lockcode "$STAGE/usr/lib/lockcode/"
find "$STAGE/usr/lib/lockcode" -type d -name __pycache__ -prune -exec rm -rf {} +
install -m 755 lockcode.py "$STAGE/usr/lib/lockcode/lockcode.py"
ln -s ../lib/lockcode/lockcode.py "$STAGE/usr/bin/lockcode"
install -m 644 assets/com.lockcode.Linux.desktop "$STAGE/usr/share/applications/"
install -m 644 assets/com.lockcode.Linux.svg "$STAGE/usr/share/icons/hicolor/scalable/apps/"
install -m 644 assets/lockcode.service "$STAGE/usr/lib/systemd/user/"

sed "s/@VERSION@/$VERSION/g" installer/control.in > "$STAGE/DEBIAN/control"
install -m 755 installer/postinst "$STAGE/DEBIAN/postinst"
install -m 755 installer/prerm "$STAGE/DEBIAN/prerm"
install -m 755 installer/postrm "$STAGE/DEBIAN/postrm"
dpkg-deb --build --root-owner-group "$STAGE" "$OUTPUT"
echo "Instalador creado: $OUTPUT"
