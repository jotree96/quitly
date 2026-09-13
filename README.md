# Quitly

Alle offenen Fenster auf einen Blick, jedes mit eigenem Schließen-Button. Hotkey: `Cmd + Alt + Ctrl + M`.

Hammerspoon ist die Engine im Hintergrund. Wer Quitly installiert, sieht davon nichts.

Alles läuft lokal auf deinem Mac. Kein Konto, kein Server, keine Telemetrie.

## Installation

Doppelklick auf `Quitly-1.0.0.pkg`. Das Paket ist unsigniert, deshalb meldet sich Gatekeeper beim ersten Mal:

- macOS 14 und älter: Rechtsklick auf die Datei, dann „Öffnen", dann im Dialog nochmal „Öffnen".
- macOS 15 und neuer: Doppelklick, Abbruchmeldung wegklicken, dann Systemeinstellungen, Datenschutz & Sicherheit, ganz unten „Trotzdem öffnen".

Danach läuft der normale Installer. Er zeigt vorab, was passiert, und am Ende die beiden Berechtigungen.

Ohne jeden Dialog geht es über das Terminal. Die Kommandozeile kennt keinen Gatekeeper-Prompt:

```bash
sudo installer -pkg ~/Downloads/Quitly.pkg -target /
```

Prüfsumme des ausgelieferten Pakets:

```
cff3b8ae107f9fdc4cc34ed58238cd71d8b014844ded80f777844701476e906d  Quitly-1.0.0.pkg
```

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

## Alles bleibt lokal

Quitly läuft vollständig auf deinem Mac. Kein Konto, kein Server, keine Telemetrie, keine Analyse. Die Fenster-Miniaturansichten entstehen im Arbeitsspeicher, werden gezeichnet und danach verworfen. Nichts davon wird gespeichert oder verschickt.

Das Paket schaltet außerdem Hammerspoons eigene Update-Prüfung ab. Sie wäre die einzige ausgehende Verbindung. Die Version kommt über den Installer, deshalb braucht es sie nicht. Zurückholen kannst du sie jederzeit:

```lua
hs.automaticallyCheckForUpdates(true)
```

Nachprüfen lässt sich das: der gesamte Quitly-Code liegt in `src/payload` und umfasst rund 520 Zeilen Lua, Kommentare mitgezählt.

```bash
grep -nE "hs\.http|socket|hs\.task|io\.popen|os\.execute|hs\.execute" src/payload/*.lua
```

Zwei Treffer, beide `hs.execute("open '...'")` mit einer `x-apple.systempreferences:`-Adresse. Das öffnet die Systemeinstellungen und geht nirgendwo hin. (`hs.urlevent.openURL` scheidet für dieses Adressschema aus, siehe Kommentar an derselben Stelle im Code.)

## Nicht signiert

Das Paket trägt keine Apple-Signatur. Dafür bräuchte es das Apple Developer Program (99 Euro im Jahr) und ein Developer-ID-Installer-Zertifikat. Für die Verteilung heißt das: jeder Nutzer läuft einmal durch den Gatekeeper-Dialog aus dem Abschnitt Installation.

Der Weg über das Terminal umgeht ihn, weil `installer` keinen Gatekeeper-Prompt kennt. Dasselbe gilt für einen Homebrew-Cask, siehe `RELEASE.md`.

Falls du es später doch signieren willst: `sign.sh` ist fertig, du trägst Zertifikatsnamen und Team-ID ein und lässt es laufen. Es macht `productsign`, `notarytool submit --wait` und `stapler staple` in einem Durchgang.

## Veröffentlichen

`RELEASE.md` beschreibt den Weg auf GitHub und die Website Schritt für Schritt: Repository anlegen, Release mit stabilem Downloadlink, Homebrew-Tap, Ablauf für die nächste Version. `website/download.html` ist ein fertiger Abschnitt zum Einsetzen.

## Neu bauen

Auf dem Mac, mit Apples Bordmitteln:

```bash
bash build_on_mac.sh
```

Das Skript zieht Hammerspoon, baut die Komponente mit `pkgbuild` und das Produktarchiv mit `productbuild`. Gebraucht werden nur die Command Line Tools.

Der Ordner `build-linux/` enthält denselben Bau ohne macOS: `build_pkg.py` schreibt cpio, BOM und xar direkt. Damit ist das Paket in einer CI ohne Mac baubar. `verify_pkg.py` und `read_bom.py` prüfen das Ergebnis gegen die Quellen.

## Struktur

```
Quitly-1.0.0.pkg          fertiger Installer (nicht im Repository, nur als Release-Asset)
README.md                 diese Datei
RELEASE.md                Schritte für GitHub und Website
RELEASE-NOTES.md          Text für die Release-Seite
LICENSE                   MIT
THIRD-PARTY.md            Hammerspoon-Lizenz und Hinweis zu bomutils
build_on_mac.sh           Neubau mit pkgbuild/productbuild
sign.sh                   productsign + notarytool + stapler
Casks/quitly.rb           Homebrew-Cask für einen eigenen Tap
website/download.html     Download-Abschnitt zum Einsetzen
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

Quitly 1.0.0, Hammerspoon 1.1.1, Paket-Identifier `com.github.jotree96.quitly`.
