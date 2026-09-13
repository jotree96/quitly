#!/bin/bash
# ============================================================
# Quitly auf dem Mac neu bauen, mit Apples Bordmitteln.
# Braucht nur die Command Line Tools, kein Xcode-Projekt.
#
#   bash build_on_mac.sh
#
# Ergebnis: Quitly-<VERSION>.pkg neben diesem Skript.
# ============================================================
set -euo pipefail

VERSION="1.0.0"
IDENTIFIER="com.github.jotree96.quitly"
HS_VERSION="1.1.1"
HS_URL="https://github.com/Hammerspoon/hammerspoon/releases/download/${HS_VERSION}/Hammerspoon-${HS_VERSION}.zip"

HERE="$(cd "$(dirname "$0")" && pwd)"
BUILD="$HERE/build"
ROOT="$BUILD/root"
COMPONENTS="$BUILD/components"

rm -rf "$BUILD"
mkdir -p "$ROOT/Applications" "$ROOT/Library/Application Support/Quitly" "$COMPONENTS"

# ---- Hammerspoon besorgen -----------------------------------------------
CACHE="$HERE/.cache"
mkdir -p "$CACHE"
if [ ! -d "$CACHE/Hammerspoon.app" ]; then
    echo "Lade Hammerspoon $HS_VERSION ..."
    curl -fsSL -o "$CACHE/hs.zip" "$HS_URL"
    /usr/bin/ditto -x -k "$CACHE/hs.zip" "$CACHE"
fi
/usr/bin/ditto "$CACHE/Hammerspoon.app" "$ROOT/Applications/Hammerspoon.app"

# ---- Quitly-Dateien ------------------------------------------------------
for f in window_overview.lua welcome.lua init.lua uninstall.sh; do
    cp "$HERE/src/payload/$f" "$ROOT/Library/Application Support/Quitly/$f"
done
chmod 644 "$ROOT/Library/Application Support/Quitly/"*.lua
chmod 755 "$ROOT/Library/Application Support/Quitly/uninstall.sh"

# ---- Komponente ----------------------------------------------------------
chmod 755 "$HERE/src/scripts/preinstall" "$HERE/src/scripts/postinstall"

pkgbuild \
    --root "$ROOT" \
    --scripts "$HERE/src/scripts" \
    --identifier "$IDENTIFIER" \
    --version "$VERSION" \
    --install-location "/" \
    --ownership recommended \
    "$COMPONENTS/quitly.pkg"

# ---- Produktarchiv -------------------------------------------------------
productbuild \
    --distribution "$HERE/src/Distribution" \
    --resources "$HERE/src/resources" \
    --package-path "$COMPONENTS" \
    "$HERE/Quitly-${VERSION}.pkg"

echo
echo "Fertig: $HERE/Quitly-${VERSION}.pkg"
echo "Prüfen:  pkgutil --expand \"$HERE/Quitly-${VERSION}.pkg\" /tmp/quitly-check && ls -R /tmp/quitly-check"
