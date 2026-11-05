#!/bin/bash
# Builds AlldebridStreaming.pkg in the repo root. Nothing is installed.
# Usage: bash installer/build.sh
set -euo pipefail

VERSION="1.1.0"
PKG_ID="org.AlldebridStreaming"

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(dirname "$HERE")"
BUILD="$HERE/build"
ROOT="$BUILD/root"
APP="$ROOT/Library/AlldebridStreaming"

export COPYFILE_DISABLE=1   # don't put ._ metadata files into the package

rm -rf "$BUILD"
mkdir -p "$APP"

cp "$HERE/files/host.js" "$HERE/files/messaging.js" "$APP/"
cp "$HERE/files/run.sh" "$HERE/files/uninstall.sh" \
   "$HERE/files/com.alld.node.chrome.json" "$HERE/files/com.alld.node.firefox.json" "$APP/"
chmod 755 "$APP/run.sh" "$APP/uninstall.sh"
chmod 644 "$APP"/*.js "$APP"/*.json
mkdir -p "$BUILD/scripts"
cp "$HERE/scripts/postinstall" "$BUILD/scripts/"
chmod 755 "$BUILD/scripts/postinstall"

# Build the component package by hand instead of with pkgbuild: pkgbuild stores
# macOS metadata (e.g. com.apple.provenance) as extra "._name" files that would get
# installed next to ours. cpio with COPYFILE_DISABLE=1 leaves them out.
COMP="$BUILD/component"
mkdir -p "$COMP"
(cd "$ROOT" && find . | sort | cpio -o --format odc -R 0:0 2>/dev/null | gzip -9 -c) > "$COMP/Payload"
# pkgutil --flatten expects Scripts as a plain folder (it archives it itself)
cp -R "$BUILD/scripts" "$COMP/Scripts"
# File list for the BOM, with everything owned by root:wheel
(cd "$ROOT" && find . | sort | while IFS= read -r f; do
  if [ -d "$f" ]; then
    printf '%s\t%s\t0/0\n' "$f" "$(stat -f '%p' "$f")"
  else
    read -r sum size _ < <(cksum "$f")
    printf '%s\t%s\t0/0\t%s\t%s\n' "$f" "$(stat -f '%p' "$f")" "$size" "$sum"
  fi
done) > "$BUILD/bom.txt"
mkbom -i "$BUILD/bom.txt" "$COMP/Bom" 2>&1 | tee "$BUILD/mkbom.log"
if [ -s "$BUILD/mkbom.log" ]; then echo "mkbom reported errors" >&2; exit 1; fi
NUM_FILES=$(find "$ROOT" | wc -l | tr -d ' ')
KBYTES=$(du -sk "$ROOT" | cut -f1)
cat > "$COMP/PackageInfo" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<pkg-info format-version="2" identifier="$PKG_ID" version="$VERSION" install-location="/" auth="root" overwrite-permissions="true" relocatable="false">
    <payload numberOfFiles="$NUM_FILES" installKBytes="$KBYTES"/>
    <scripts>
        <postinstall file="./postinstall"/>
    </scripts>
</pkg-info>
EOF
pkgutil --flatten "$COMP" "$BUILD/component.pkg"

sed "s/__VERSION__/$VERSION/" "$HERE/Distribution.xml" > "$BUILD/Distribution.xml"

productbuild \
  --distribution "$BUILD/Distribution.xml" \
  --resources "$HERE/resources" \
  --package-path "$BUILD" \
  "$REPO/AlldebridStreaming.pkg"

echo "Built $REPO/AlldebridStreaming.pkg (version $VERSION)"
