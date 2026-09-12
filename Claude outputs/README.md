# Quitly

Alle offenen Fenster auf einen Blick, jedes mit eigenem Schließen-Button. Hotkey: `Cmd + Alt + Ctrl + M`.

Hammerspoon ist die Engine im Hintergrund. Wer Quitly installiert, sieht davon nichts.

## Installation

Doppelklick auf `Quitly-1.0.0.pkg`. Das Paket ist unsigniert, deshalb meldet sich Gatekeeper beim ersten Mal:

- macOS 14 und älter: Rechtsklick auf die Datei, dann „Öffnen", dann im Dialog nochmal „Öffnen".
- macOS 15 und neuer: Doppelklick, Abbruchmeldung wegklicken, dann Systemeinstellungen, Datenschutz & Sicherheit, ganz unten „Trotzdem öffnen".

Danach läuft der normale Installer. Er zeigt vorab, was passiert, und am Ende die beiden Berechtigungen.

## Was das Paket macht

| Schritt | Wirkung |
|---|---|
| preinstall | beendet ein laufendes Hammerspoon |
| Payload | legt `Hammerspoon.app` nach `/Applications` und die Quitly-Quellen nach `/Library/Application Support/Quitly` |
| postinstall | kopiert die Lua-Dateien nach `~/.hammerspoon/quitly`, hängt eine Zeile an `~/.hammerspoon/init.lua`, startet Hammerspoon |

Eine bestehende Hammerspoon-Konfiguration bleibt erhalten. Das Postinstall legt vorher `init.lua.vor-quitly.bak` an und fügt nur diesen Block hinzu:

```lua
-- >>> Quitly <<< (Block nicht von Hand bearbeiten)
dofile(hs.configdir .. "/quitly/init.lua")
-- >>> Quitly Ende <<<
```

Hammerspoon startet ab dann mit der Anmeldung, sitzt in der Menüleiste und nicht im Dock.

## Berechtigungen

Nach der Installation erscheint ein Fenster mit zwei Knöpfen. Jeder Knopf öffnet direkt den passenden Bereich der Systemeinstellungen.

- **Bedienungshilfen**: Quitly holt Fenster nach vorn und schließt sie. Ohne diesen Haken passiert beim Klick nichts.
- **Bildschirmaufnahme**: `hs.window:snapshot()` erzeugt die Miniaturansichten. Ohne diesen Haken bleiben die Kacheln leer.

Setze in beiden Listen den Haken bei Hammerspoon. Für die Bildschirmaufnahme verlangt macOS anschließend einen Neustart der App.

## Signieren

Das Paket ist bewusst unsigniert ausgeliefert. So kommst du zu einer signierten Fassung.

**1. Mitgliedschaft.** Signieren geht nur mit dem Apple Developer Program, 99 Euro im Jahr. Ein kostenloser Apple-Account reicht für Xcode-Builds, nicht für Developer ID.

**2. Zertifikat.** Du brauchst ein **Developer ID Installer**-Zertifikat. Das ist ein anderes als „Developer ID Application", mit dem Apps signiert werden. Anlegen entweder in Xcode unter Settings, Accounts, Manage Certificates, Plus, oder auf developer.apple.com unter Certificates. Danach liegt es im Schlüsselbund. Namen auslesen:

```bash
security find-identity -v | grep "Developer ID Installer"
```

**3. Notariat vorbereiten.** Ein App-spezifisches Passwort auf appleid.apple.com erzeugen, dann einmalig hinterlegen:

```bash
xcrun notarytool store-credentials quitly-notary \
  --apple-id deine@apple-id.de \
  --team-id DEINETEAMID \
  --password xxxx-xxxx-xxxx-xxxx
```

**4. Werte eintragen und laufen lassen.** In `sign.sh` stehen `INSTALLER_CERT` und `TEAM_ID` als Platzhalter. Eintragen, dann:

```bash
bash sign.sh Quitly-1.0.0.pkg
```

Das Skript signiert mit `productsign`, schickt das Ergebnis an `notarytool`, wartet auf das Ticket und heftet es mit `stapler` an. Danach installiert das Paket auf jedem Mac ohne Gatekeeper-Umweg.

Ohne Mitgliedschaft bleibt der Rechtsklick-Weg aus dem Abschnitt Installation. Für dich selbst und für einzelne Kollegen reicht das. Für eine Verteilung über MDM oder eine Downloadseite nicht.

## Neu bauen

Auf dem Mac, mit Apples Bordmitteln:

```bash
bash build_on_mac.sh
```

Das Skript zieht Hammerspoon, baut die Komponente mit `pkgbuild` und das Produktarchiv mit `productbuild`. Gebraucht werden nur die Command Line Tools.

Der Ordner `build-linux/` enthält denselben Bau ohne macOS: `build_pkg.py` schreibt cpio, BOM und xar direkt. Damit ist das Paket in einer CI ohne Mac baubar. `verify_pkg.py` und `read_bom.py` prüfen das Ergebnis gegen die Quellen.

## Struktur

```
Quitly-1.0.0.pkg          fertiger Installer
build_on_mac.sh           Neubau mit pkgbuild/productbuild
sign.sh                   productsign + notarytool + stapler
src/
  payload/                was nach /Library/Application Support/Quitly geht
    window_overview.lua   die Fenster-Übersicht
    welcome.lua           Willkommensfenster mit den zwei Direktlinks
    init.lua              Einstiegspunkt, Autostart, Reload-Watcher
    uninstall.sh          Deinstallation
  scripts/
    preinstall            beendet Hammerspoon
    postinstall           Benutzerkonfiguration und Start
  resources/
    welcome.html          erste Seite im Installer
    conclusion.html       letzte Seite im Installer
  Distribution            Installer-Steuerdatei
build-linux/
  build_pkg.py            Paketbau ohne macOS
  verify_pkg.py           prüft xar, cpio, Scripts
  read_bom.py             BOM-Leser, Ersatz für lsbom
```

## Deinstallation

```bash
bash ~/.hammerspoon/quitly/uninstall.sh
```

Schneidet den Quitly-Block aus der `init.lua`, löscht `~/.hammerspoon/quitly` und den Systemanteil. Hammerspoon bleibt liegen, die letzte Zeile im Skript sagt, wie es auch verschwindet.

## Versionen

Quitly 1.0.0, Hammerspoon 1.1.1, Paket-Identifier `de.humandigitals.quitly`.
