local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

config.color_scheme = "Catppuccin Mocha"

-- Window
config.window_background_opacity = 0.93
config.macos_window_background_blur = 20
config.window_decorations = "RESIZE|INTEGRATED_BUTTONS"
config.integrated_title_button_style = "Windows" 
config.window_close_confirmation = "NeverPrompt"
config.adjust_window_size_when_changing_font_size = true
config.check_for_updates = false

-- Mica on Windows
config.win32_system_backdrop = "Acrylic"

-- Default window size
config.initial_cols = 140
config.initial_rows = 40

-- Font
config.font = wezterm.font_with_fallback({
	{ family = "Ubuntu Mono", weight = "Bold" },
	"Symbols Nerd Font Mono",
})
config.font_size = 16.0

-- Cursor
config.default_cursor_style = "SteadyBar"
config.cursor_thickness = 2.5

-- Tab bar
config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = false
config.enable_tab_bar = true
config.show_tab_index_in_tab_bar = false
config.tab_max_width = 32

-- Scrollbar
config.enable_scroll_bar = true
config.scrollback_lines = 10000

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

-- Disable Kitty keyboard protocol: causes Nushell prompt redraws to shift output upward in WezTerm
config.enable_kitty_keyboard = false

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
	{ key = "w", mods = "CTRL", action = act({ CloseCurrentPane = { confirm = false } }) },
	-- Paste
	{ key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
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

-- Custom tab title with powerline arrows, icons, and hover state
local known_shells = { bash = true, zsh = true, fish = true, nu = true, sh = true, pwsh = true, nushell = true, wslhost = true }

local function nf(name)
	return wezterm.nerdfonts[name] or ""
end

local process_icons = {
	nu      = utf8.char(0xE795),   -- nf-dev-terminal
	nushell = utf8.char(0xE795),
	bash    = utf8.char(0xE795),
	zsh     = utf8.char(0xE795),
	fish    = utf8.char(0xE795),
	nvim    = utf8.char(0xE62B),   -- nf-seti-vim
	vim     = utf8.char(0xE62B),
	ssh     = nf("md_server"),
	python  = nf("dev_python"),
	python3 = nf("dev_python"),
	node    = utf8.char(0xE617),   -- nf-dev-nodejs_small
	git     = utf8.char(0xE702),   -- nf-dev-git
	htop    = nf("fa_bar_chart"),
	btop    = nf("fa_bar_chart"),
}

local ARROW_R = nf("pl_right_hard_divider")
local ARROW_L = nf("pl_left_hard_divider")


wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local title = (tab.tab_title and tab.tab_title ~= "" and tab.tab_title) or "nu"
	local icon = process_icons[title:lower()] or utf8.char(0xE795)
	local label = icon .. " " .. title

	local bar_bg = "#1e1e2e"
	local bg, fg
	if tab.is_active then
		bg, fg = "#cba6f7", "#1e1e2e"
	elseif hover then
		bg, fg = "#45475a", "#cdd6f4"
	else
		bg, fg = "#313244", "#cdd6f4"
	end

	return {
		{ Background = { Color = bar_bg } },
		{ Foreground = { Color = bg } },
		{ Text = ARROW_R },
		{ Background = { Color = bg } },
		{ Foreground = { Color = fg } },
		{ Text = " " .. label .. " " },
		{ Background = { Color = bar_bg } },
		{ Foreground = { Color = bg } },
		{ Text = ARROW_L },
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

-- Fancy tab bar frame styling (Catppuccin Mocha)
config.window_frame = {
	font = wezterm.font_with_fallback({ { family = "Ubuntu Mono", weight = "Bold" }, "Symbols Nerd Font Mono" }),
	font_size = 13.0,
	active_titlebar_bg = "#1e1e2e",
	inactive_titlebar_bg = "#181825",
	active_titlebar_fg = "#cdd6f4",
	inactive_titlebar_fg = "#6c7086",
	active_titlebar_border_bottom = "#1e1e2e",
	inactive_titlebar_border_bottom = "#181825",
	button_fg = "#6c7086",
	button_bg = "#1e1e2e",
	button_hover_fg = "#cdd6f4",
	button_hover_bg = "#313244",
}

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
