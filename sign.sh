#!/bin/bash
# ============================================================
# Quitly.pkg signieren und notarisieren.
#
#   bash sign.sh Quitly-1.0.0.pkg
#
# Voraussetzungen stehen in der README, Abschnitt "Signieren".
# ============================================================
set -euo pipefail

PKG="${1:-Quitly-1.0.0.pkg}"
OUT="${PKG%.pkg}-signed.pkg"

# Trage hier deine Werte ein:
INSTALLER_CERT="Developer ID Installer: DEIN NAME (TEAMID)"
KEYCHAIN_PROFILE="quitly-notary"   # siehe README
TEAM_ID="TEAMID"

[ -f "$PKG" ] || { echo "Datei nicht gefunden: $PKG"; exit 1; }

echo "1/3  Signieren ..."
productsign --sign "$INSTALLER_CERT" "$PKG" "$OUT"
pkgutil --check-signature "$OUT"

echo
echo "2/3  Notarisieren (dauert meist ein bis zwei Minuten) ..."
xcrun notarytool submit "$OUT" --keychain-profile "$KEYCHAIN_PROFILE" --wait

echo
echo "3/3  Ticket anheften ..."
xcrun stapler staple "$OUT"
xcrun stapler validate "$OUT"

echo
echo "Fertig: $OUT"
echo "Gegenprobe:  spctl --assess -vv --type install \"$OUT\""
