#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="0.4.1"
TOPDIR="$ROOT/build/rpm"
SOURCE="$TOPDIR/SOURCES/lockcode-linux-$VERSION"
OUTPUT="$ROOT/RPM/output/lockcode-linux_${VERSION}_noarch.rpm"

command -v rpmbuild >/dev/null || {
  echo "Falta rpmbuild. Instálalo con: sudo dnf install rpm-build" >&2
  exit 1
}

cd "$ROOT"
python3 -m unittest discover -s tests -v
rm -rf "$TOPDIR"
mkdir -p "$(dirname "$OUTPUT")"
mkdir -p "$TOPDIR"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS} "$SOURCE"
cp -R lockcode lockcode.py assets "$SOURCE/"
find "$SOURCE" -type d -name __pycache__ -prune -exec rm -rf {} +
tar -czf "$TOPDIR/SOURCES/lockcode-linux-$VERSION.tar.gz" -C "$TOPDIR/SOURCES" "lockcode-linux-$VERSION"
sed "s/@VERSION@/$VERSION/g" RPM/lockcode.spec.in > "$TOPDIR/SPECS/lockcode.spec"
rpmbuild --define "_topdir $TOPDIR" -bb "$TOPDIR/SPECS/lockcode.spec"
cp "$TOPDIR/RPMS/noarch/lockcode-linux-$VERSION-1"*.noarch.rpm "$OUTPUT"
echo "Instalador creado: $OUTPUT"
