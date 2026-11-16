-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1.25

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
--

local handle = io.popen("hostname")
local hostname = handle:read("*a"):gsub("%s+", "")
handle:close()

-- The monitor each SUPER+number goes to, whichever monitor has focus; bindings.lua binds the
-- keys. Workspace rules can't pin numbers any more: Omarchy gives every monitor workspaces
-- 1-10 of its own and renumbers a workspace that sits on another monitor's.
if hostname == "omarchy-nflx" then
    local m1, m2, m3 = "DP-4", "DP-5", "HDMI-A-4"
    pinned_workspaces = { m1, m1, m1, m2, m2, m2, m3, m3, m3, m3 }
end

