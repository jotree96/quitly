# Veröffentlichen

Ablauf für ein Release auf GitHub und die Verlinkung auf der Website. Account und Paket-Identifier sind bereits eingesetzt: `jotree96` beziehungsweise `com.github.jotree96.quitly`.

## 0. GitHub CLI einrichten

Die Schritte unten nutzen `gh`. Das spart den Weg über den Browser, vor allem beim Hochladen der Release-Dateien.

```bash
brew install gh
gh auth login
```

Bei `gh auth login` wählst du GitHub.com, HTTPS, und lässt dich im Browser anmelden. Das richtet gleich die Git-Zugangsdaten mit ein.

Ohne Homebrew gibt es ein Installationspaket auf https://cli.github.com. Wer `gh` gar nicht will, findet unter Schritt 1b und 3b den Weg über den Browser.

## 1. Repository anlegen

Das `.pkg` gehört nicht in die Versionsverwaltung. Es kommt als Release-Asset dazu. `.gitignore` hält es draußen.

```bash
cd ~/Documents/00_Projects/Quitly
git init
git branch -M main
git add .
git commit -m "Quitly 1.0.0"
gh repo create quitly --public --source=. --remote=origin --push
```

### 1b. Ohne gh

Repository auf https://github.com/new anlegen, Name `quitly`, öffentlich, ohne README und ohne .gitignore. Dann lokal:

```bash
cd ~/Documents/00_Projects/Quitly
git init
git branch -M main
git add .
git commit -m "Quitly 1.0.0"
git remote add origin https://github.com/jotree96/quitly.git
git push -u origin main
```

Beim Push fragt Git nach Zugangsdaten. Das Kontopasswort funktioniert dort nicht. Du brauchst ein Personal Access Token aus den GitHub-Einstellungen unter Developer settings, Tokens, Scope `repo`. Das Token gibst du als Passwort ein.

## 2. Prüfsumme erzeugen

```bash
shasum -a 256 Quitly-1.0.0.pkg | tee SHA256SUMS
```

Aktueller Stand des ausgelieferten Pakets:

```
cff3b8ae107f9fdc4cc34ed58238cd71d8b014844ded80f777844701476e906d  Quitly-1.0.0.pkg
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

### 3b. Ohne gh

Im Repository auf Releases, dann „Draft a new release". Tag `v1.0.0` anlegen, Titel „Quitly 1.0.0", den Text aus `RELEASE-NOTES.md` einfügen. Die drei Dateien `Quitly-1.0.0.pkg`, `Quitly.pkg` und `SHA256SUMS` in das Feld „Attach binaries" ziehen. Veröffentlichen.

Der stabile Link für die Website lautet danach:

```
https://github.com/jotree96/quitly/releases/latest/download/Quitly.pkg
```

Er zeigt immer auf das neueste Release. Auf der Website ändert sich nichts mehr, wenn du Version 1.1 nachschiebst.

## 4. Website

`website/download.html` enthält den fertigen Abschnitt. Nach jedem Release die Prüfsumme darin nachziehen, der Downloadlink bleibt gleich.

Wichtig für die Seite: schreibe hin, dass das Paket unsigniert ist, und wie man es trotzdem öffnet. Wer das erst nach dem Fehlerdialog erfährt, lädt nicht zu Ende.

## 5. Optional: eigener Homebrew-Tap

Der bequemste Weg für technische Nutzer, und er umgeht den Gatekeeper-Dialog, weil Homebrew über die Kommandozeile installiert.

```bash
gh repo create homebrew-quitly --public
# Casks/quitly.rb aus diesem Ordner dort hineinlegen
```

Installation für den Nutzer:

```bash
brew tap jotree96/quitly
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
