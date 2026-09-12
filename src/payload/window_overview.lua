-- ============================================================
-- Eigene Fenster-Übersicht mit echten Schließen-Buttons
-- ============================================================
-- Zeigt alle offenen Fenster als Miniaturansicht. Klick auf ein
-- Thumbnail aktiviert das Fenster, Klick auf den roten Button
-- schließt es sofort. Der Button verhält sich wie das native
-- macOS-Ampel-Symbol: Er zeigt das × erst, wenn die Maus darüber
-- steht. Klick auf den Hintergrund blendet die Übersicht aus.
--
-- Aufruf per Hotkey: Cmd + Alt + Ctrl + M (weiter unten änderbar)
-- ============================================================

local overview = {}

local THUMB_W = 340
local THUMB_H = 220
local PADDING = 32
local LABEL_H = 48
local BUTTON_RADIUS = 8
local BUTTON_MARGIN = 16

-- macOS-Rot für den Schließen-Button, plus die dunkle Farbe,
-- in der das × beim Hover erscheint (genau wie beim Original)
local CLOSE_COLOR = { red = 1.0, green = 0.373, blue = 0.341, alpha = 1 }
local CLOSE_ICON_COLOR = { red = 0.30, green = 0.0, blue = 0.01, alpha = 1 }

-- Sammelt alle "normalen" Fenster (keine Paletten, Popups, Widgets etc.)
local function getWindowList()
    local result = {}
    for _, w in ipairs(hs.window.visibleWindows()) do
        if w:isStandard() and w:title() ~= "" then
            table.insert(result, w)
        end
    end
    return result
end

function overview.hide()
    if overview.canvas then
        overview.canvas:delete()
        overview.canvas = nil
    end
    overview.windows = nil
end

function overview.show()
    -- Zweiter Aufruf des Hotkeys schließt die Übersicht wieder
    if overview.canvas then
        overview.hide()
        return
    end

    local windows = getWindowList()
    if #windows == 0 then
        hs.alert.show("Keine offenen Fenster gefunden")
        return
    end
    overview.windows = windows

    local screen = hs.screen.mainScreen():frame()
    local cols = math.max(1, math.floor(screen.w / (THUMB_W + PADDING)))

    local c = hs.canvas.new(screen)
    c:level(hs.canvas.windowLevels.overlay)
    c:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)

    -- Abgedunkelter Hintergrund, Klick darauf schließt die Übersicht
    c[#c + 1] = {
        type = "rectangle",
        action = "fill",
        fillColor = { red = 0, green = 0, blue = 0, alpha = 0.75 },
        frame = { x = 0, y = 0, w = screen.w, h = screen.h },
        trackMouseDown = true,
        id = "background",
    }

    for i, w in ipairs(windows) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local x = PADDING + col * (THUMB_W + PADDING)
        local y = PADDING + row * (THUMB_H + LABEL_H + PADDING)

        local ok, img = pcall(function() return w:snapshot() end)

        -- Fenster-Thumbnail: Klick aktiviert das Fenster
        c[#c + 1] = {
            type = "image",
            image = ok and img or nil,
            imageScaling = "scaleProportionally",
            frame = { x = x, y = y, w = THUMB_W, h = THUMB_H },
            trackMouseDown = true,
            id = "win_" .. i,
        }

        -- Dezenter Rahmen um das Thumbnail
        c[#c + 1] = {
            type = "rectangle",
            action = "stroke",
            strokeColor = { white = 1, alpha = 0.25 },
            strokeWidth = 1,
            frame = { x = x, y = y, w = THUMB_W, h = THUMB_H },
        }

        -- App-Name, groß und fett unter dem Thumbnail
        local appName = w:application() and w:application():name() or "?"
        c[#c + 1] = {
            type = "text",
            text = appName,
            textSize = 18,
            textColor = { white = 1 },
            textLineBreak = "truncateTail",
            frame = { x = x, y = y + THUMB_H + 6, w = THUMB_W, h = 24 },
        }

        -- Fenstertitel, kleiner und gedimmt darunter
        c[#c + 1] = {
            type = "text",
            text = w:title(),
            textSize = 13,
            textColor = { white = 1, alpha = 0.6 },
            textLineBreak = "truncateTail",
            frame = { x = x, y = y + THUMB_H + 28, w = THUMB_W, h = 18 },
        }

        -- Schließen-Button im macOS-Stil: nur der rote Punkt,
        -- das × erscheint erst beim Hover (siehe mouseCallback unten)
        local bx = x + BUTTON_MARGIN
        local by = y + BUTTON_MARGIN
        c[#c + 1] = {
            type = "circle",
            action = "fill",
            fillColor = CLOSE_COLOR,
            center = { x = bx, y = by },
            radius = BUTTON_RADIUS,
            withShadow = true,
            trackMouseDown = true,
            trackMouseEnterExit = true,
            id = "close_" .. i,
        }
        c[#c + 1] = {
            type = "text",
            text = "×",
            textSize = 13,
            textColor = CLOSE_ICON_COLOR,
            textAlignment = "center",
            action = "skip", -- unsichtbar, bis der Hover es einblendet
            frame = { x = bx - BUTTON_RADIUS, y = by - BUTTON_RADIUS - 1, w = BUTTON_RADIUS * 2, h = BUTTON_RADIUS * 2 },
            id = "closeicon_" .. i,
        }
    end

    c:mouseCallback(function(canvasObj, message, id)
        if message == "mouseDown" then
            if id == "background" then
                overview.hide()
                return
            end

            local closeIdx = tostring(id):match("^close_(%d+)$")
            if closeIdx then
                local w = overview.windows[tonumber(closeIdx)]
                if w then w:close() end
                overview.hide()
                overview.show()
                return
            end

            local winIdx = tostring(id):match("^win_(%d+)$")
            if winIdx then
                local w = overview.windows[tonumber(winIdx)]
                if w then w:focus() end
                overview.hide()
                return
            end
        elseif message == "mouseEnter" or message == "mouseExit" then
            local n = tostring(id):match("^close_(%d+)$")
            if n then
                canvasObj["closeicon_" .. n].action = (message == "mouseEnter") and "fill" or "skip"
            end
        end
    end)

    c:show()
    overview.canvas = c
end

-- Hotkey zum Ein- und Ausblenden der Übersicht
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "M", function()
    overview.show()
end)

return overview
