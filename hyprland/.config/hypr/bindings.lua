-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Dropdown Terminal
o.bind("SUPER + ALT + grave", "Dropdown terminal", hl.dsp.global("io.github.tuthan.dropdown-terminal:toggle"))

-- Dictation keys from before Alt + Space and Right Alt became the defaults.
-- Remove these lines to give the keys back to applications.
if o.dictation_installed and o.dictation_installed() then
  o.bind("SUPER + CTRL + X", "Toggle dictation", "omarchy-dictation toggle")
  o.bind_hold("F9", "Start dictation (push-to-talk)", "omarchy-dictation start", "Stop dictation (push-to-talk)", "omarchy-dictation stop")
end

-- Omarchy gives every monitor its own workspaces 1-10, and SUPER+number goes to that number on
-- the focused monitor. Where monitors.lua pins each number to a monitor, SUPER+number goes to
-- that monitor's workspace from anywhere, as global workspaces did. The bars keep labelling
-- each monitor's workspaces by number, so they read 1-3, 4-6, 7-10.
if pinned_workspaces then
  -- The pinned monitor, or the focused one while that one is unplugged.
  local function monitor_for(n)
    return hl.get_monitor(pinned_workspaces[n]) or hl.get_active_monitor()
  end

  local function focus(n)
    local pinned, here = o.workspaces.focus(n, pinned_workspaces[n]), o.workspaces.focus(n)
    local fn = function()
      if hl.get_monitor(pinned_workspaces[n]) then pinned() else here() end
    end
    o.bind_expressions[fn] = o.bind_expressions[pinned] -- what the keybindings menu runs
    return fn
  end

  -- A workspace the move creates starts on the focused monitor, so it goes to its own after.
  local function move_window(n, follow)
    return function()
      local window, monitor = hl.get_active_window(), monitor_for(n)
      if not window or not monitor then
        return
      end

      local id = o.workspaces.workspace_id(monitor, n)
      local address = "address:" .. window.address
      hl.dispatch(hl.dsp.window.move({ workspace = tostring(id), follow = false, window = address }))

      local workspace = hl.get_workspace(id)
      if workspace and workspace.monitor and workspace.monitor.name ~= monitor.name then
        hl.dispatch(hl.dsp.workspace.move({ workspace = tostring(id), monitor = monitor.name }))
      end
      if follow then
        hl.dispatch(hl.dsp.focus({ window = address }))
      end
    end
  end

  for n in ipairs(pinned_workspaces) do
    local key = "code:" .. (n + 9)
    o.rebind("SUPER + " .. key, "Switch to workspace " .. n, focus(n))
    o.rebind("SUPER + SHIFT + " .. key, "Move window to workspace " .. n, move_window(n, true))
    o.rebind("SUPER + SHIFT + ALT + " .. key, "Move window silently to workspace " .. n, move_window(n, false))
  end

  -- Omarchy starts every monitor on its workspace 1; start each on its first pinned number.
  hl.on("hyprland.start", function()
    local focused, started = hl.get_active_monitor(), {}
    for n, name in ipairs(pinned_workspaces) do
      if not started[name] and hl.get_monitor(name) then
        started[name] = true
        o.workspaces.focus(n, name)()
      end
    end
    if focused then
      hl.dispatch(hl.dsp.focus({ monitor = focused.name }))
    end
  end)
end
