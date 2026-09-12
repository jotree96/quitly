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
  h1 { margin: 0 0 4px; font-size: 21px; letter-spacing: -0.2px; }
  .sub { margin: 0 0 20px; color: var(--muted); font-size: 13px; }
  .hotkey {
    display: inline-flex; gap: 4px; margin: 0 0 22px;
  }
  .hotkey span {
    background: var(--chip); border: 1px solid var(--line); border-radius: 5px;
    padding: 3px 8px; font-size: 12px; font-weight: 600;
  }
  .step {
    display: flex; align-items: center; gap: 14px;
    padding: 13px 0; border-top: 1px solid var(--line);
  }
  .step:last-of-type { border-bottom: 1px solid var(--line); }
  .step .txt { flex: 1; min-width: 0; }
  .step .name { font-weight: 600; }
  .step .why { color: var(--muted); font-size: 12px; }
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
</style>
</head>
<body>
  <h1>Quitly ist installiert</h1>
  <p class="sub">Alle offenen Fenster auf einen Blick, jedes mit eigenem Schließen-Button.</p>

  <div class="hotkey"><span>⌘</span><span>⌥</span><span>⌃</span><span>M</span></div>

  <div class="step">
    <div class="txt">
      <div class="name">Bedienungshilfen</div>
      <div class="why">Damit Quitly Fenster in den Vordergrund holen und schließen darf.</div>
    </div>
    <button class="primary" onclick="send('ax')">Öffnen</button>
  </div>

  <div class="step">
    <div class="txt">
      <div class="name">Bildschirmaufnahme</div>
      <div class="why">Damit die Miniaturansichten der Fenster erzeugt werden können.</div>
    </div>
    <button class="primary" onclick="send('sr')">Öffnen</button>
  </div>

  <div class="foot">
    <p>Setze in beiden Listen den Haken bei Hammerspoon. Danach Quitly einmal neu starten.</p>
    <button onclick="send('done')">Fertig</button>
  </div>

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
        "Quitly ist installiert",
        "Hotkey: Cmd + Alt + Ctrl + M\n\n" ..
        "Quitly braucht zwei Berechtigungen für Hammerspoon:\n" ..
        "Bedienungshilfen und Bildschirmaufnahme.",
        "Bedienungshilfen öffnen",
        "Später"
    )
    if choice == "Bedienungshilfen öffnen" then
        hs.urlevent.openURL(URL_ACCESSIBILITY)
        hs.timer.doAfter(1.5, function()
            hs.urlevent.openURL(URL_SCREEN_RECORDING)
        end)
    end
end

function M.show()
    if not hs.webview then
        showPlainDialog()
        markShown()
        return
    end

    local W, H = 560, 430
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
        if what == "ax" then
            hs.urlevent.openURL(URL_ACCESSIBILITY)
        elseif what == "sr" then
            hs.urlevent.openURL(URL_SCREEN_RECORDING)
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
    win:allowTextEntry(false)
    win:deleteOnClose(true)
    win:level(hs.drawing.windowLevels.floating)
    win:html(HTML)
    win:show()
    win:bringToFront(true)
    hs.timer.doAfter(0.3, function()
        local app = hs.application.get("Hammerspoon")
        if app then app:activate() end
    end)

    -- Referenz halten, sonst räumt der Garbage Collector das Fenster weg
    M.window = win
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
