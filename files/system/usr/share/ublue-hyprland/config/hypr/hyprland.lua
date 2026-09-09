-- ============================================================
--  ublue-hyprland minimal config (Hyprland 0.56, Lua)
--  BASIC by design: stock behavior + Noctalia shell autostart.
--  Mirrors the structure of Lee's desktop hyprland.lua
--  (verified on the same 0.56.2 that this image ships).
-- ============================================================

------------------ AUTOSTART ------------------
-- Noctalia is the shell (bar/launcher/session/OSD/lock/
-- notifications/wallpaper). Polkit agent for privilege prompts.
hl.on("hyprland.start", function()
    hl.exec_cmd("noctalia")
end)

------------------ LOOK (minimal) ------------------
hl.config({
    decoration = {
        rounding = 0,          -- flat, Noctalia-style
    },
    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,   -- Noctalia draws the wallpaper
    },
})

------------------ KEYBINDS (basic set) ------------------
local mainMod = "SUPER"

-- terminal & launcher
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("ghostty"))
hl.bind(mainMod .. " + D",      hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))

-- focus & window ops
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + space", hl.dsp.layout("cyclenext"))
hl.bind(mainMod .. " + Q",     hl.dsp.window.close())
hl.bind(mainMod .. " + F",     hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + T",     hl.dsp.window.float())

-- workspaces 1-9
for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
