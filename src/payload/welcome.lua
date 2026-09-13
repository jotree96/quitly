-- ============================================================
-- Quitly: Willkommensfenster nach der Installation
-- ============================================================
-- Wird genau einmal pro Installation gezeigt. Es erklärt die zwei
-- Berechtigungen, die Quitly braucht, und öffnet die passenden
-- Bereiche der Systemeinstellungen per Klick.
--
-- Bedienungshilfen  -> Fenster fokussieren und schließen
-- Bildschirmaufnahme -> Miniaturansichten der Fenster erzeugen
-- ============================================================

local M = {}

local FLAG = hs.configdir .. "/quitly/.welcome_done"

local URL_ACCESSIBILITY =
    "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
local URL_SCREEN_RECORDING =
    "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"

-- hs.urlevent.openURL() verlangt zwingend ein "://" in der URL und lehnt
-- Apples eigenes Schema (nur ein Doppelpunkt, wie bei "mailto:") ab.
-- /usr/bin/open kennt es und öffnet direkt die richtige Unterseite.
local function openSettingsURL(url)
    hs.execute("open '" .. url .. "'")
end

local HTML = [[
<!doctype html>
<html lang="de">
<head>
<meta charset="utf-8">
<style>
  :root {
    color-scheme: light dark;
    --bg: #ffffff;
    --fg: #1c1c1e;
    --muted: #6b6b70;
    --line: #e2e2e6;
    --accent: #0a63c9;
    --accent-fg: #ffffff;
    --chip: #f3f3f5;
    --warn-bg: #fff4e5;
    --warn-line: #f0d2a8;
    --warn-fg: #9a5b00;
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --bg: #1e1e20;
      --fg: #f2f2f4;
      --muted: #a0a0a6;
      --line: #37373b;
      --accent: #3a8cf0;
      --accent-fg: #ffffff;
      --chip: #2a2a2d;
      --warn-bg: #3a2b14;
      --warn-line: #5c4520;
      --warn-fg: #f0b357;
    }
  }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    padding: 28px 30px 22px;
    background: var(--bg);
    color: var(--fg);
    font: 13px/1.5 -apple-system, BlinkMacSystemFont, "Helvetica Neue", sans-serif;
    -webkit-user-select: none;
    cursor: default;
  }
  h1 { margin: 0 0 6px; font-size: 21px; letter-spacing: -0.2px; }
  .sub { margin: 0 0 16px; color: var(--muted); font-size: 13px; }
  .alert {
    margin: 0 0 18px; padding: 11px 14px; border-radius: 8px;
    background: var(--warn-bg); border: 1px solid var(--warn-line);
    color: var(--warn-fg); font-size: 12.5px;
  }
  .step {
    display: flex; align-items: center; gap: 14px;
    padding: 14px 0; border-top: 1px solid var(--line);
  }
  .step:last-of-type { border-bottom: 1px solid var(--line); }
  .step .txt { flex: 1; min-width: 0; }
  .step .name { font-weight: 600; }
  .step .why { color: var(--muted); font-size: 12px; }
  .step .fail { color: var(--warn-fg); font-size: 12px; margin-top: 2px; }
  .badge {
    display: inline-block; vertical-align: 1px; margin-left: 6px;
    background: var(--warn-fg); color: #fff; border-radius: 4px;
    padding: 1px 6px; font-size: 10px; font-weight: 700;
    text-transform: uppercase; letter-spacing: 0.4px;
  }
  .howto { margin: 16px 0 0; font-size: 12.5px; }
  .k {
    background: var(--chip); border: 1px solid var(--line); border-radius: 5px;
    padding: 2px 7px; font-weight: 600; white-space: nowrap;
  }
  button {
    font: inherit; font-weight: 500;
    border: 1px solid var(--line); border-radius: 6px;
    background: var(--chip); color: var(--fg);
    padding: 6px 12px; cursor: default; white-space: nowrap;
  }
  button:active { opacity: 0.6; }
  button.primary { background: var(--accent); color: var(--accent-fg); border-color: transparent; }
  .foot { display: flex; align-items: center; gap: 12px; margin-top: 20px; }
  .foot p { margin: 0; color: var(--muted); font-size: 12px; flex: 1; }
  .local {
    margin: 18px 0 0; padding-top: 14px; border-top: 1px solid var(--line);
    color: var(--muted); font-size: 11.5px;
  }
</style>
</head>
<body>
  <h1>Noch zwei Schritte, dann läuft Quitly</h1>
  <p class="sub">Quitly ist installiert, aber macOS hat die zwei nötigen Berechtigungen noch nicht freigegeben. Solange sie fehlen, passiert beim Tastendruck nichts.</p>

  <div class="alert">
    <b>Beide Berechtigungen sind Pflicht.</b> Ohne sie startet Quitly zwar, zeigt aber leere Kacheln und schließt keine Fenster.
  </div>

  <div class="step">
    <div class="txt">
      <div class="name">Bedienungshilfen <span class="badge">erforderlich</span></div>
      <div class="why">Erlaubt Quitly, Fenster in den Vordergrund zu holen und zu schließen.</div>
      <div class="fail">Fehlt sie, bleibt jeder Klick auf eine Kachel wirkungslos.</div>
    </div>
    <button class="primary" onclick="send('ax')">Einstellungen öffnen</button>
  </div>

  <div class="step">
    <div class="txt">
      <div class="name">Bildschirmaufnahme <span class="badge">erforderlich</span></div>
      <div class="why">Erlaubt Quitly, die Miniaturansichten der Fenster zu erzeugen.</div>
      <div class="fail">Fehlt sie, bleiben alle Kacheln leer.</div>
    </div>
    <button class="primary" onclick="send('sr')">Einstellungen öffnen</button>
  </div>

  <p class="howto">Setze in beiden Listen den Haken bei <b>Hammerspoon</b>. Bei der Bildschirmaufnahme fragt macOS danach nach einem Neustart der App, das bestätigst du. Erst dann liegt die Übersicht auf <span class="k">⌘⌥⌃M</span>.</p>

  <div class="foot">
    <p>Du kommst später jederzeit über Systemeinstellungen, Datenschutz &amp; Sicherheit dorthin.</p>
    <button onclick="send('done')">Später</button>
  </div>

  <p class="local">Quitly läuft vollständig auf deinem Mac. Kein Konto, kein Server, keine Datenübertragung. Die Fensterbilder verlassen nie den Arbeitsspeicher.</p>

<script>
function send(what) {
  try { window.webkit.messageHandlers.quitly.postMessage(what); } catch (e) {}
}
</script>
</body>
</html>
]]

local function markShown()
    local f = io.open(FLAG, "w")
    if f then
        f:write(os.date("%Y-%m-%d %H:%M:%S"))
        f:close()
    end
end

-- Rückfallebene, falls hs.webview auf diesem System nicht verfügbar ist
local function showPlainDialog()
    local choice = hs.dialog.blockAlert(
        "Noch zwei Schritte, dann läuft Quitly",
        "Quitly braucht zwei Berechtigungen für Hammerspoon. Beide sind Pflicht:\n\n" ..
        "Bedienungshilfen, sonst bleibt jeder Klick auf eine Kachel wirkungslos.\n" ..
        "Bildschirmaufnahme, sonst bleiben alle Kacheln leer.\n\n" ..
        "Setze in beiden Listen den Haken bei Hammerspoon. " ..
        "Danach liegt die Übersicht auf Cmd + Alt + Ctrl + M.",
        "Einstellungen öffnen",
        "Später"
    )
    if choice == "Einstellungen öffnen" then
        openSettingsURL(URL_ACCESSIBILITY)
        hs.timer.doAfter(1.5, function()
            openSettingsURL(URL_SCREEN_RECORDING)
        end)
    end
end

function M.show()
    if not hs.webview then
        showPlainDialog()
        markShown()
        return
    end

    local W, H = 580, 650
    local scr = hs.screen.mainScreen():frame()
    local rect = {
        x = scr.x + (scr.w - W) / 2,
        y = scr.y + (scr.h - H) / 3,
        w = W,
        h = H,
    }

    local uc = hs.webview.usercontent.new("quitly")
    uc:setCallback(function(msg)
        local what = msg and msg.body
        print("[Quitly] Willkommensfenster: Aktion " .. tostring(what))
        if what == "ax" then
            openSettingsURL(URL_ACCESSIBILITY)
        elseif what == "sr" then
            openSettingsURL(URL_SCREEN_RECORDING)
        elseif what == "done" then
            if M.window then
                M.window:delete()
                M.window = nil
            end
        end
    end)

    local win = hs.webview.new(rect, { developerExtrasEnabled = false }, uc)
    win:windowStyle({ "titled", "closable" })
    win:windowTitle("Quitly")
    -- Trotz des Namens entscheidet das auch darüber, ob das Fenster
    -- "key window" werden kann. Ohne das liefert WebKit Klicks nicht
    -- an das DOM aus, Buttons bleiben wirkungslos.
    win:allowTextEntry(true)
    win:deleteOnClose(true)
    win:level(hs.drawing.windowLevels.floating)
    win:html(HTML)
    win:show()
    win:bringToFront(true)
    hs.timer.doAfter(0.3, function()
        local app = hs.application.get("Hammerspoon")
        if app then app:activate() end
    end)

    -- Referenzen halten, sonst räumt der Garbage Collector Fenster
    -- oder Message-Handler weg
    M.window = win
    M.usercontent = uc
    markShown()
end

function M.showIfFirstRun()
    if hs.fs.attributes(FLAG) then return end
    hs.timer.doAfter(1.0, function()
        local ok, err = pcall(M.show)
        if not ok then
            print("[Quitly] Willkommensfenster fehlgeschlagen: " .. tostring(err))
            markShown()
        end
    end)
end

return M
