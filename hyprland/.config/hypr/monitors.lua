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

if hostname == "omarchy-nflx" then
    local m1, m2, m3 = "DP-4", "DP-5", "HDMI-A-4"
    for _, ws in ipairs({"1", "2", "3"}) do
        hl.workspace_rule({ workspace = ws, monitor = m1 })
    end
    for _, ws in ipairs({"4", "5", "6"}) do
        hl.workspace_rule({ workspace = ws, monitor = m2 })
    end
    for _, ws in ipairs({"7", "8", "9", "10"}) do
        hl.workspace_rule({ workspace = ws, monitor = m3 })
    end
end

