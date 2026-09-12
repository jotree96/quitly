-- ============================================================
-- Quitly: Einstiegspunkt
-- ============================================================
-- Wird von ~/.hammerspoon/init.lua geladen. Alles, was Quitly
-- ausmacht, hängt an dieser Datei. Wer Quitly loswerden will,
-- löscht den Quitly-Block in ~/.hammerspoon/init.lua und den
-- Ordner ~/.hammerspoon/quitly.
-- ============================================================

local base = hs.configdir .. "/quitly/"

local Quitly = {}

Quitly.version = "1.0.0"

-- Hammerspoon startet mit der Anmeldung und bleibt in der Menüleiste,
-- im Dock taucht es nicht auf.
hs.autoLaunch(true)
hs.menuIcon(true)
hs.dockIcon(false)
hs.consoleOnTop(false)

-- Fenster-Übersicht laden. Die Datei bindet den Hotkey selbst.
Quitly.overview = dofile(base .. "window_overview.lua")

-- Willkommensfenster, einmalig nach der Installation
Quitly.welcome = dofile(base .. "welcome.lua")
Quitly.welcome.showIfFirstRun()

-- Konfiguration neu laden, sobald sich eine Datei ändert
Quitly.watcher = hs.pathwatcher.new(hs.configdir, function(files)
    for _, f in ipairs(files) do
        if f:sub(-4) == ".lua" then
            hs.reload()
            return
        end
    end
end):start()

return Quitly
