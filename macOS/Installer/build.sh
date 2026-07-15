#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VERSION="$(awk '/MARKETING_VERSION:/ {print $2; exit}' "$ROOT/project.yml")"
BUILD="$(awk '/CURRENT_PROJECT_VERSION:/ {print $2; exit}' "$ROOT/project.yml")"
WORK="$ROOT/.build/macOS-installer"
APP="$WORK/LockCode.app"
OUTPUT="$ROOT/macOS/Installer/output/LockCode-macOS-$VERSION.zip"
SOURCES=()
while IFS= read -r source; do SOURCES+=("$source"); done < <(find "$ROOT/LockCode" -name '*.swift' -print | sort)
FRAMEWORKS=(
  -framework AppKit -framework SwiftUI -framework Combine -framework CryptoKit
  -framework LocalAuthentication -framework Security -framework ServiceManagement
  -framework UserNotifications
)

rm -rf "$WORK"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$(dirname "$OUTPUT")"
for architecture in x86_64 arm64; do
  swiftc -O -whole-module-optimization -strict-concurrency=complete -warnings-as-errors \
    -parse-as-library -target "$architecture-apple-macosx13.0" \
    "${SOURCES[@]}" "${FRAMEWORKS[@]}" -o "$WORK/LockCode-$architecture"
done
lipo -create "$WORK/LockCode-x86_64" "$WORK/LockCode-arm64" -output "$APP/Contents/MacOS/LockCode"

cp "$ROOT/LockCode/Resources/Info.plist" "$APP/Contents/Info.plist"
plutil -replace CFBundleExecutable -string LockCode "$APP/Contents/Info.plist"
plutil -replace CFBundleIdentifier -string com.example.LockCode "$APP/Contents/Info.plist"
plutil -replace CFBundleName -string LockCode "$APP/Contents/Info.plist"
plutil -replace CFBundleShortVersionString -string "$VERSION" "$APP/Contents/Info.plist"
plutil -replace CFBundleVersion -string "$BUILD" "$APP/Contents/Info.plist"
plutil -replace LSMinimumSystemVersion -string 13.0 "$APP/Contents/Info.plist"
cp "$ROOT/LockCode/Resources/LockCode.icns" "$ROOT/LockCode/Resources/LockCodeLogo.png" "$APP/Contents/Resources/"

SIGN_IDENTITY="${SIGN_IDENTITY:-}"
if [[ -z "$SIGN_IDENTITY" ]] && security find-identity -v -p codesigning | grep -Fq '"LockCode Local Signing"'; then
  SIGN_IDENTITY="LockCode Local Signing"
fi
codesign --force --deep --options runtime --sign "${SIGN_IDENTITY:--}" \
  --entitlements "$ROOT/LockCode/Resources/LockCode.entitlements" "$APP"
codesign --verify --deep --strict "$APP"
rm -f "$OUTPUT"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$OUTPUT"
echo "Instalador creado: $OUTPUT"
