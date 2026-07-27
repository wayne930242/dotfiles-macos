-- WezTerm 配置檔
-- 位置: dotfiles-macos/.wezterm.lua → symlink 到 ~/.wezterm.lua

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

-- ============================================
-- 外觀設定
-- ============================================

-- MesloLGS NF 不含中文字。WezTerm 用 freetype/harfbuzz，取不到 macOS 的系統
-- font fallback，只能靠一份內建的猜測清單；猜不到時該有字的地方會直接變成空白
-- （官方 FAQ: "spaces where glyphs should be" 就是 fallback 問題）。
-- 這裡明確指定，並釘住 TC 變體 —— 隱式 fallback 會落到 PingFang HK，
-- 部分字形與台灣標準不同，而且它位於 MobileAsset 隨選下載路徑而非固定路徑。
config.font = wezterm.font_with_fallback({
	"MesloLGS NF",
	"PingFang TC",
	"Heiti TC",
})
config.font_size = 14.0

-- 主題列表: https://wezfurlong.org/wezterm/colorschemes/index.html
config.color_scheme = "Dracula (Official)"

config.window_padding = {
	left = 10,
	right = 10,
	top = 10,
	bottom = 10,
}
-- ============================================
-- 標籤列設定
-- ============================================

-- 保持 tab bar 常駐：right status (含 LEADER 指示) 是渲染在 tab bar 內，
-- 若隱藏會導致 leader 啟動時無處顯示
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false

-- 預設 16 glyphs，開多 tab 時標題很快被截斷
config.tab_max_width = 32

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

-- 模式指示器：key table (RESIZE) 優先於 LEADER，兩者共用同一個 right status
-- 注意：所有狀態必須寫在同一個 handler 內。WezTerm 允許重複註冊 update-status，
-- 但每個 handler 都會執行且都呼叫 set_right_status，後註冊的會直接蓋掉前面的結果
-- 注意：避免在此 handler 內呼叫 set_config_overrides，會觸發 window-config-reloaded
-- 進而造成重複渲染與閃爍
local function status_badge(bg, text)
	return wezterm.format({
		{ Background = { Color = bg } },
		{ Foreground = { Color = "#282a36" } },
		{ Attribute = { Intensity = "Bold" } },
		{ Text = " " .. text .. " " },
	})
end

wezterm.on("update-status", function(window, _)
	if window:active_key_table() == "resize_pane" then
		window:set_right_status(status_badge("#bd93f9", "RESIZE hjkl"))
	elseif window:leader_is_active() then
		window:set_right_status(status_badge("#ffb86c", "LEADER"))
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

	-- ─── Pane 分割 ───
	-- 佈局模型：一個 tab 的 panes 是二元樹，每次分割是「把某個節點一分為二」。
	-- 沒有 tmux 的 layout preset，也沒有把既有 pane 搬到別層的動作 ——
	-- 所以順序是「先用 \ _ 立最外層骨架，再用 | - 往內切細節」。
	--
	-- 記法：同一顆實體鍵管同一個分割方向，另一個 shift 狀態 = 貫穿最外層
	--   backslash 鍵 → 左右分割 (垂直分隔線)：| 切當前 pane、\ 貫穿整個 tab
	--   minus     鍵 → 上下分割 (水平分隔線)：- 切當前 pane、_ 貫穿整個 tab
	--
	-- 全部統一用 SplitPane：舊的 SplitHorizontal/SplitVertical 固定 50/50，
	-- 不支援 size 與 top_level。命名也易誤讀 —— SplitHorizontal 指的是
	-- 「水平方向排列」即左右分割，畫出來是一條垂直線
	{ key = "|", mods = "LEADER", action = act.SplitPane({ direction = "Right", size = { Percent = 50 } }) },
	{ key = "-", mods = "LEADER", action = act.SplitPane({ direction = "Down", size = { Percent = 50 } }) },
	-- top_level = true：忽略當前 pane 在樹的哪個位置，直接切 tab 的根節點。
	-- 這是在「已經有上下分割」的情況下，唯一能開出全高右側欄的方法
	{
		key = "\\",
		mods = "LEADER",
		action = act.SplitPane({ direction = "Right", size = { Percent = 35 }, top_level = true }),
	},
	{
		key = "_",
		mods = "LEADER",
		action = act.SplitPane({ direction = "Down", size = { Percent = 30 }, top_level = true }),
	},

	-- ─── Pane 導航 (vim 風格) ───
	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
	{ key = ";", mods = "LEADER", action = act.ActivatePaneDirection("Prev") },
	-- q: 標記選擇 (對應 tmux display-panes)。pane 多時比連按方向鍵快，
	-- 字母表限定 home row，手不必離開基準位置
	{ key = "q", mods = "LEADER", action = act.PaneSelect({ alphabet = "asdfghjkl;" }) },
	-- Q: 同樣的標記選擇，但把選中的 pane 與當前 pane 對調位置。
	-- 樹形切錯了無法搬移節點，但「內容放錯格子」用這個換回來，不必重切
	{ key = "Q", mods = "LEADER", action = act.PaneSelect({ mode = "SwapWithActive", alphabet = "asdfghjkl;" }) },

	-- ─── Pane 大小調整 ───
	-- r: 進入 resize 模式後 hjkl / 方向鍵可連按，Esc / Enter / q 離開。
	-- 單次綁定 (每調一次重按一次 leader) 已移除，大小調整只留這一個入口。
	--
	-- 刻意不設 timeout：逾時自動退出會造成「調完大小後幾秒內打的 h/j/k/l
	-- 被當成 resize 吃掉」這種隨機行為。改成模式必須明確退出，狀態由
	-- tab bar 的 RESIZE 指示器呈現。
	-- until_unknown = true 是保險：忘了退出時，打第一個非 hjkl/方向鍵的字
	-- 會自動 pop 並照常輸入，不會整段打字被吞
	{
		key = "r",
		mods = "LEADER",
		action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false, until_unknown = true }),
	},

	-- ─── Pane 操作 ───
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = false }) },
	{ key = "Space", mods = "LEADER", action = act.RotatePanes("Clockwise") },
	-- !: 把選中的 pane 拆到新 tab (對應 tmux break-pane)。
	-- 同一個 tab 內無法把 pane 移到樹的別層 (無 tmux join-pane 等價物)，
	-- 但整格拆出去獨立是做得到的
	{ key = "!", mods = "LEADER", action = act.PaneSelect({ mode = "MoveToNewTab", alphabet = "asdfghjkl;" }) },

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
				if line and #line > 0 then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},

	-- ─── Tab 順序調整 (對應 tmux swap-window) ───
	{ key = "<", mods = "LEADER", action = act.MoveTabRelative(-1) },
	{ key = ">", mods = "LEADER", action = act.MoveTabRelative(1) },
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
	-- automatically_reload_config 預設 true，存檔即自動 reload，
	-- 手動 reload 幾乎用不到，把好按的 r 讓給 resize 模式
	{ key = "r", mods = "LEADER|CTRL", action = act.ReloadConfiguration },
	-- 連按兩次 CTRL+a 送出真正的 CTRL+a 給應用程式 (例如 tmux/screen 內)
	{ key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },
}

-- ============================================
-- Key tables (模式化操作)
-- ============================================

-- resize 模式：以 one_shot = false 進入後不退出，hjkl 可連按調整。
-- 步進 3 而非單次綁定時的 5 —— 連按下較細的步進反而更好對位
config.key_tables = {
	resize_pane = {
		{ key = "h", action = act.AdjustPaneSize({ "Left", 3 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 3 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 3 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 3 }) },
		{ key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 3 }) },
		{ key = "DownArrow", action = act.AdjustPaneSize({ "Down", 3 }) },
		{ key = "UpArrow", action = act.AdjustPaneSize({ "Up", 3 }) },
		{ key = "RightArrow", action = act.AdjustPaneSize({ "Right", 3 }) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },
		{ key = "q", action = "PopKeyTable" },
	},
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
