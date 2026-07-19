-- WezTerm 配置檔
-- 位置: dotfiles-macos/.wezterm.lua → symlink 到 ~/.wezterm.lua

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

-- ============================================
-- 外觀設定
-- ============================================

config.font = wezterm.font("MesloLGS NF")
config.font_size = 14.0

-- 主題列表: https://wezfurlong.org/wezterm/colorschemes/index.html
config.color_scheme = "Catppuccin Mocha"

config.window_padding = {
	left = 10,
	right = 10,
	top = 10,
	bottom = 10,
}
config.window_background_opacity = 0.95
config.macos_window_background_blur = 10

-- ============================================
-- 標籤列設定
-- ============================================

-- 保持 tab bar 常駐：right status (含 LEADER 指示) 是渲染在 tab bar 內，
-- 若隱藏會導致 leader 啟動時無處顯示
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false

-- ============================================
-- Multiplex / 持久會話 (對應 tmux session persistence)
-- ============================================

-- 註冊一個 unix domain mux server。
-- 模型：tabs/panes 跑在背景 mux server (daemon)，wezterm GUI 只是 client。
-- 關掉視窗 → server 仍在背景；再開 wezterm 自動 attach 回去，
-- 執行中的 vim/ssh/REPL 都會保留。對應 tmux 的 detach/attach。
-- 備註：系統重開機後 mux server 不會自動拉起，需要再開 wezterm 重建。
config.unix_domains = {
	{ name = "unix" },
}

-- GUI 啟動時自動連線到 unix domain mux (沒在跑會自動 spawn)
config.default_gui_startup_args = { "connect", "unix" }

-- ============================================
-- Leader 鍵設定 (類似 tmux 的 prefix)
-- ============================================

-- CTRL+a 為 leader，按下後 2 秒內接收下個鍵
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 2000 }

-- Leader active 時於 tab bar 右側顯示橘色 LEADER 指示
-- 注意：避免在此 handler 內呼叫 set_config_overrides，會觸發 window-config-reloaded
-- 進而造成重複渲染與閃爍
wezterm.on("update-status", function(window, _)
	if window:leader_is_active() then
		window:set_right_status(wezterm.format({
			{ Background = { Color = "#fab387" } },
			{ Foreground = { Color = "#11111b" } },
			{ Attribute = { Intensity = "Bold" } },
			{ Text = " LEADER " },
		}))
	else
		window:set_right_status("")
	end
end)

-- ============================================
-- Neovim 無縫導航 (smart-splits.nvim)
-- ============================================

-- smart-splits.nvim 啟動時會設定 IS_NVIM user var；靠它判斷目前 pane 是否在跑 nvim
local function is_vim(pane)
	return pane:get_user_vars().IS_NVIM == "true"
end

local direction_keys = {
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
}

-- CTRL+h/j/k/l：在 nvim 內原樣送入 (由 smart-splits 處理)，否則切換 wezterm pane
local function split_nav(key)
	return {
		key = key,
		mods = "CTRL",
		action = wezterm.action_callback(function(win, pane)
			if is_vim(pane) then
				win:perform_action({ SendKey = { key = key, mods = "CTRL" } }, pane)
			else
				win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
			end
		end),
	}
end

-- ============================================
-- 快捷鍵設定
-- ============================================

config.keys = {
	-- ─── Neovim 無縫導航 ───
	split_nav("h"),
	split_nav("j"),
	split_nav("k"),
	split_nav("l"),
	-- ─── macOS 慣例 (CMD-based) ───
	{ key = "t", mods = "CMD", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "w", mods = "CMD", action = act.CloseCurrentPane({ confirm = false }) },
	{ key = "k", mods = "CMD", action = act.ClearScrollback("ScrollbackAndViewport") },
	{ key = "1", mods = "CMD", action = act.ActivateTab(0) },
	{ key = "2", mods = "CMD", action = act.ActivateTab(1) },
	{ key = "3", mods = "CMD", action = act.ActivateTab(2) },
	{ key = "4", mods = "CMD", action = act.ActivateTab(3) },
	{ key = "5", mods = "CMD", action = act.ActivateTab(4) },

	-- ─── Pane 分割 (tmux 慣例) ───
	{ key = "|", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

	-- ─── Pane 導航 (vim 風格) ───
	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
	{ key = ";", mods = "LEADER", action = act.ActivatePaneDirection("Prev") },

	-- ─── Pane 大小調整 ───
	{ key = "LeftArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Left", 5 }) },
	{ key = "RightArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Right", 5 }) },
	{ key = "UpArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Up", 5 }) },
	{ key = "DownArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Down", 5 }) },

	-- ─── Pane 操作 ───
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = false }) },
	{ key = "Space", mods = "LEADER", action = act.RotatePanes("Clockwise") },

	-- ─── Tab 操作 (tmux 慣例) ───
	{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "&", mods = "LEADER", action = act.CloseCurrentTab({ confirm = false }) },
	{ key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
	{ key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{
		key = ",",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "重新命名 tab",
			action = wezterm.action_callback(function(window, _, line)
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},
	{ key = "1", mods = "LEADER", action = act.ActivateTab(0) },
	{ key = "2", mods = "LEADER", action = act.ActivateTab(1) },
	{ key = "3", mods = "LEADER", action = act.ActivateTab(2) },
	{ key = "4", mods = "LEADER", action = act.ActivateTab(3) },
	{ key = "5", mods = "LEADER", action = act.ActivateTab(4) },
	{ key = "6", mods = "LEADER", action = act.ActivateTab(5) },
	{ key = "7", mods = "LEADER", action = act.ActivateTab(6) },
	{ key = "8", mods = "LEADER", action = act.ActivateTab(7) },
	{ key = "9", mods = "LEADER", action = act.ActivateTab(8) },

	-- ─── Copy / Paste ───
	{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = "]", mods = "LEADER", action = act.PasteFrom("Clipboard") },

	-- ─── 命令面板 / 快速鍵查詢 ───
	{ key = ":", mods = "LEADER", action = act.ActivateCommandPalette },
	{ key = "?", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|KEY_ASSIGNMENTS" }) },

	-- ─── Workspace (對應 tmux session) ───
	-- s: 切換 workspace (launcher 內也可輸入新名稱直接建立)
	{ key = "s", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
	-- $: 重新命名當前 workspace (tmux 慣例)
	{
		key = "$",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "重新命名 workspace",
			action = wezterm.action_callback(function(_, _, line)
				if line and #line > 0 then
					wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
				end
			end),
		}),
	},
	-- 備註：關閉視窗 (CMD+Q 或紅綠燈) 即等於 tmux detach，
	-- mux server 與所有 panes/程序留在背景，下次開 wezterm 自動 attach 回來

	-- ─── Reload / 送出 leader 字面 ───
	{ key = "r", mods = "LEADER", action = act.ReloadConfiguration },
	-- 連按兩次 CTRL+a 送出真正的 CTRL+a 給應用程式 (例如 tmux/screen 內)
	{ key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },
}

-- ============================================
-- 其他設定
-- ============================================

-- 把左/右 Alt 當成 Meta，而非系統的特殊字元組合鍵
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

config.window_close_confirmation = "NeverPrompt"
config.scrollback_lines = 10000

config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 500

config.check_for_updates = false

return config
