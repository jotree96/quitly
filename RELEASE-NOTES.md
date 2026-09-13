Quitly zeigt alle offenen Fenster auf einen Blick, jedes mit eigenem Schließen-Button. Hotkey: **Cmd + Alt + Ctrl + M**.

Alles läuft lokal auf deinem Mac. Kein Konto, kein Server, keine Telemetrie. Die Miniaturansichten entstehen im Arbeitsspeicher und werden danach verworfen. Hammerspoons Update-Prüfung schaltet Quitly ab, damit keine einzige Verbindung nach außen offen bleibt.

## Installation

Lade `Quitly.pkg` und öffne es. Das Paket ist unsigniert, deshalb blockt macOS beim ersten Mal:

- **macOS 15 und neuer:** Doppelklick, Meldung wegklicken, dann Systemeinstellungen → Datenschutz & Sicherheit → ganz unten „Trotzdem öffnen".
- **macOS 14 und älter:** Rechtsklick auf die Datei → „Öffnen" → im Dialog nochmal „Öffnen".

Oder ohne Dialog über das Terminal:

```bash
sudo installer -pkg ~/Downloads/Quitly.pkg -target /
```

## Was installiert wird

- Hammerspoon 1.1.1 nach `/Applications` (unverändert aus dem offiziellen Release, MIT)
- die Quitly-Konfiguration nach `~/.hammerspoon/quitly`

Eine vorhandene Hammerspoon-Konfiguration bleibt erhalten. Quitly hängt eine Zeile an deine `init.lua` und sichert die alte Fassung als `init.lua.vor-quitly.bak`.

## Berechtigungen

Nach der Installation erscheint ein Fenster mit zwei Knöpfen, die direkt in die passenden Systemeinstellungen führen:

- **Bedienungshilfen**, damit Fenster fokussiert und geschlossen werden können
- **Bildschirmaufnahme**, damit die Miniaturansichten entstehen

Setze in beiden Listen den Haken bei Hammerspoon.

## Deinstallation

```bash
bash ~/.hammerspoon/quitly/uninstall.sh
```

## Prüfsumme

```
cff3b8ae107f9fdc4cc34ed58238cd71d8b014844ded80f777844701476e906d  Quitly-1.0.0.pkg
```
