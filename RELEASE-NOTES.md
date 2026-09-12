Quitly zeigt alle offenen Fenster auf einen Blick, jedes mit eigenem Schließen-Button. Hotkey: **Cmd + Alt + Ctrl + M**.

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
683f800938df2155bfcaa1bd8f5fd29c9b3d67807a6cc0ca6dbca27feb8ff5b8  Quitly-1.0.0.pkg
```
