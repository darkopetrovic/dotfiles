local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

config.color_scheme = "Catppuccin Mocha"

-- Window
config.window_background_opacity = 0.93
config.macos_window_background_blur = 20
config.window_decorations = "RESIZE|INTEGRATED_BUTTONS"
config.window_close_confirmation = "NeverPrompt"
config.adjust_window_size_when_changing_font_size = false
config.check_for_updates = false

-- Mica on Windows
config.win32_system_backdrop = "Acrylic"

-- Default window size
config.initial_cols = 140
config.initial_rows = 40

-- Font
config.font = wezterm.font("Ubuntu Mono", { weight = "Bold" })
config.font_size = 16.0

-- Cursor
config.default_cursor_style = "SteadyBar"
config.cursor_thickness = 2.5

-- Tab bar
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.enable_tab_bar = true
config.show_tab_index_in_tab_bar = false
config.tab_max_width = 32

-- Padding
config.window_padding = {
	left = 12,
	right = 12,
	top = 8,
	bottom = 8,
}

-- WSL default domain
config.default_domain = "WSL:Ubuntu-26.04"

-- Automatically reload config on save
config.automatically_reload_config = true

-- Keybindings
config.keys = {
	{ key = "Enter", mods = "CTRL", action = wezterm.action({ SendString = "\x1b[13;5u" }) },
	{ key = "Enter", mods = "SHIFT", action = wezterm.action({ SendString = "\x1b[13;2u" }) },
	-- Tab navigation
	{ key = "Tab", mods = "CTRL", action = act({ ActivateTabRelative = 1 }) },
	{ key = "Tab", mods = "CTRL|SHIFT", action = act({ ActivateTabRelative = -1 }) },
	{ key = "LeftArrow", mods = "CTRL|ALT", action = act({ ActivateTabRelative = -1 }) },
	{ key = "RightArrow", mods = "CTRL|ALT", action = act({ ActivateTabRelative = 1 }) },
	{ key = "1", mods = "ALT", action = act({ ActivateTab = 0 }) },
	{ key = "2", mods = "ALT", action = act({ ActivateTab = 1 }) },
	{ key = "3", mods = "ALT", action = act({ ActivateTab = 2 }) },
	{ key = "4", mods = "ALT", action = act({ ActivateTab = 3 }) },
	{ key = "5", mods = "ALT", action = act({ ActivateTab = 4 }) },
	{ key = "6", mods = "ALT", action = act({ ActivateTab = 5 }) },
	{ key = "7", mods = "ALT", action = act({ ActivateTab = 6 }) },
	{ key = "8", mods = "ALT", action = act({ ActivateTab = 7 }) },
	{ key = "9", mods = "ALT", action = act({ ActivateTab = 8 }) },
	-- Splits
	{ key = "-", mods = "ALT|SHIFT", action = act({ SplitVertical = { domain = "CurrentPaneDomain" } }) },
	{ key = "/", mods = "ALT|SHIFT", action = act({ SplitHorizontal = { domain = "CurrentPaneDomain" } }) },
	-- Pane navigation
	{ key = "UpArrow", mods = "ALT", action = act({ ActivatePaneDirection = "Up" }) },
	{ key = "DownArrow", mods = "ALT", action = act({ ActivatePaneDirection = "Down" }) },
	{ key = "LeftArrow", mods = "ALT", action = act({ ActivatePaneDirection = "Left" }) },
	{ key = "RightArrow", mods = "ALT", action = act({ ActivatePaneDirection = "Right" }) },
	-- tmux: forward Ctrl+Shift+Left/Right for tmux window navigation
	{ key = "LeftArrow", mods = "CTRL|SHIFT", action = act({ SendString = "\x1b[1;6D" }) },
	{ key = "RightArrow", mods = "CTRL|SHIFT", action = act({ SendString = "\x1b[1;6C" }) },
	-- Close pane
	{ key = "w", mods = "ALT|SHIFT", action = act({ CloseCurrentPane = { confirm = true } }) },
}

-- Hyperlinks
config.hyperlink_rules = {
	{
		regex = "\\((\\w+://\\S+)\\)",
		format = "$1",
		highlight = 1,
	},
	{
		regex = "\\[(\\w+://\\S+)\\]",
		format = "$1",
		highlight = 1,
	},
	{
		regex = "\\{(\\w+://\\S+)\\}",
		format = "$1",
		highlight = 1,
	},
	{
		regex = "<(\\w+://\\S+)>",
		format = "$1",
		highlight = 1,
	},
	{
		regex = "[^(]\\b(\\w+://\\S+[)/a-zA-Z0-9-]+)",
		format = "$1",
		highlight = 1,
	},
}

-- Custom tab title with padding and naming support
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local title = tab.tab_title
	if not title or title == "" then
		local pane = tab.active_pane
		local process = pane.foreground_process_name or ""
		title = process:gsub(".*[/\\]", "")
		if title == "" or title == "wslhost.exe" or title:find("%.exe$") then
			title = "bash"
		end
	end
	local colors = { bg = "#585b70", fg = "#cdd6f4" }
	if tab.is_active then
		colors = { bg = "#cba6f7", fg = "#1e1e2e" }
	end
	return {
		{ Background = { Color = colors.bg } },
		{ Text = "  " .. title .. "  " },
	}
end)

-- Rename tab keybinding
table.insert(config.keys, {
	key = "r",
	mods = "CTRL|SHIFT",
	action = wezterm.action({ PromptInputLine = {
		description = "Enter new name for tab",
		action = wezterm.action_callback(function(window, pane, line)
			if line then
				window:mux_window():active_tab():set_title(line)
			end
		end),
	} }),
})

-- Tab bar styling
config.colors = {
	tab_bar = {
		background = "#1e1e2e",
		active_tab = {
			bg_color = "#cba6f7",
			fg_color = "#1e1e2e",
			intensity = "Normal",
			underline = "None",
			italic = false,
			strikethrough = false,
		},
		inactive_tab = {
			bg_color = "#181825",
			fg_color = "#a6adc8",
			intensity = "Normal",
			underline = "None",
			italic = false,
			strikethrough = false,
		},
		inactive_tab_hover = {
			bg_color = "#313244",
			fg_color = "#cdd6f4",
			intensity = "Normal",
			underline = "None",
			italic = false,
			strikethrough = false,
		},
		new_tab = {
			bg_color = "#1e1e2e",
			fg_color = "#cba6f7",
		},
		new_tab_hover = {
			bg_color = "#313244",
			fg_color = "#cba6f7",
		},
	},
}

-- Modern status area (bottom-right)
wezterm.on("update-status", function(window, pane)
	local date = wezterm.strftime("%a %b %d")
	local time = wezterm.strftime("%H:%M")

	local cwd = pane:get_current_working_dir()
	local dir = ""
	if cwd then
		dir = cwd.file_path:gsub(".*/", "")
	end

	window:set_right_status(wezterm.format({
		{ Foreground = { Color = "#f5c2e7" } },
		{ Text = " " },
		{ Foreground = { Color = "#fab387" } },
		{ Text = dir },
		{ Foreground = { Color = "#6c7086" } },
		{ Text = " \u{2502} " },
		{ Foreground = { Color = "#89b4fa" } },
		{ Text = date },
		{ Foreground = { Color = "#6c7086" } },
		{ Text = " " },
		{ Foreground = { Color = "#f2cdcd" } },
		{ Text = time },
		{ Foreground = { Color = "#6c7086" } },
		{ Text = "  " },
	}))
end)

return config
