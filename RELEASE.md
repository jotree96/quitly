# Veröffentlichen

Ablauf für ein Release auf GitHub und die Verlinkung auf der Website. Ersetze `DEIN-GITHUB-NAME` überall durch deinen Account.

## 1. Repository anlegen

Das `.pkg` gehört nicht in die Versionsverwaltung. Es kommt als Release-Asset dazu. `.gitignore` hält es draußen.

```bash
cd ~/Documents/00_Projects/Quitly
git init
git add .
git commit -m "Quitly 1.0.0"
gh repo create quitly --public --source=. --remote=origin --push
```

Ohne `gh`: Repository auf github.com anlegen, dann `git remote add origin ...` und `git push -u origin main`.

## 2. Prüfsumme erzeugen

```bash
shasum -a 256 Quitly-1.0.0.pkg | tee SHA256SUMS
```

Aktueller Stand des ausgelieferten Pakets:

```
683f800938df2155bfcaa1bd8f5fd29c9b3d67807a6cc0ca6dbca27feb8ff5b8  Quitly-1.0.0.pkg
```

## 3. Release mit stabilem Downloadlink

Lade das Paket zweimal hoch: einmal mit Version im Namen für die Nachvollziehbarkeit, einmal ohne für einen Link, der nach jedem Update weiter funktioniert.

```bash
cp Quitly-1.0.0.pkg Quitly.pkg

gh release create v1.0.0 \
  Quitly-1.0.0.pkg Quitly.pkg SHA256SUMS \
  --title "Quitly 1.0.0" \
  --notes-file RELEASE-NOTES.md
```

Der stabile Link für die Website lautet danach:

```
https://github.com/DEIN-GITHUB-NAME/quitly/releases/latest/download/Quitly.pkg
```

Er zeigt immer auf das neueste Release. Auf der Website ändert sich nichts mehr, wenn du Version 1.1 nachschiebst.

## 4. Website

`website/download.html` enthält einen fertigen Abschnitt zum Einsetzen. Zwei Dinge musst du darin anpassen: den GitHub-Namen im Link und die Prüfsumme.

Wichtig für die Seite: schreibe hin, dass das Paket unsigniert ist, und wie man es trotzdem öffnet. Wer das erst nach dem Fehlerdialog erfährt, lädt nicht zu Ende.

## 5. Optional: eigener Homebrew-Tap

Der bequemste Weg für technische Nutzer, und er umgeht den Gatekeeper-Dialog, weil Homebrew über die Kommandozeile installiert.

```bash
gh repo create homebrew-quitly --public
# Casks/quitly.rb aus diesem Ordner dort hineinlegen, GitHub-Namen anpassen
```

Installation für den Nutzer:

```bash
brew tap DEIN-GITHUB-NAME/quitly
brew install --cask quitly
```

Falls die Installation an der Quarantäne hängen bleibt: `brew install --cask --no-quarantine quitly`.

## 6. Bei jeder neuen Version

1. Versionsnummer in `build_on_mac.sh`, `Casks/quitly.rb` und `src/Distribution` hochziehen
2. `bash build_on_mac.sh`
3. `shasum -a 256 Quitly-<neu>.pkg`
4. `gh release create v<neu> ...` wie oben, wieder mit der Kopie `Quitly.pkg`
5. `sha256` und `version` im Cask nachziehen

Der Website-Link bleibt unverändert.
