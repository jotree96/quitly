#!/bin/bash
# Quitly entfernen. Ohne Argumente ausführen:
#   bash ~/.hammerspoon/quitly/uninstall.sh
# Hammerspoon selbst bleibt liegen, das letzte rm kommentiert das ab.

set -u

HS_DIR="$HOME/.hammerspoon"
INIT="$HS_DIR/init.lua"

/usr/bin/pkill -x Hammerspoon >/dev/null 2>&1

# Quitly-Block aus der init.lua schneiden
if [ -f "$INIT" ]; then
    /usr/bin/sed -i '' '/^-- >>> Quitly <<</,/^-- >>> Quitly Ende <<</d' "$INIT"
    echo "Quitly-Block aus init.lua entfernt"
fi

/bin/rm -rf "$HS_DIR/quitly"
echo "~/.hammerspoon/quitly gelöscht"

if [ -d "/Library/Application Support/Quitly" ]; then
    echo "Für den Rest werden Administratorrechte gebraucht:"
    /usr/bin/sudo /bin/rm -rf "/Library/Application Support/Quitly"
    /usr/bin/sudo /usr/sbin/pkgutil --forget com.github.jotree96.quitly >/dev/null 2>&1
    echo "Systemanteil entfernt"
fi

echo
echo "Hammerspoon liegt weiterhin in /Applications."
echo "Zum Löschen: rm -rf /Applications/Hammerspoon.app"
