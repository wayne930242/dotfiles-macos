-- Hammerspoon 設定檔
-- 位置: dotfiles-macos/hammerspoon/init.lua → symlink 到 ~/.hammerspoon/init.lua
--
-- 雙擊 CMD 召喚 quick terminal 已移除：改由 Ghostty 自己的 global:ctrl+grave_accent
-- 處理（見 ghostty/config），Hammerspoon 目前沒有啟用中的功能。

-- CMD+1~9 多視窗切換器停用：改用 herdr 管 tab/workspace，Ghostty 只剩一個
-- NSWindow 可切，tab 切換改用 herdr 原生的 Ctrl+B prefix。留著沒啟用是因為
-- 如果哪天放棄 herdr、要走回多視窗模式，這段邏輯還能直接復用。
--[[
local AEROSPACE_BIN = "/opt/homebrew/bin/aerospace"
local GHOSTTY_BUNDLE_ID = "com.mitchellh.ghostty"

local function focusGhosttyWindowByIndex(index)
	local output, ok =
		hs.execute(AEROSPACE_BIN .. " list-windows --monitor all --app-bundle-id " .. GHOSTTY_BUNDLE_ID .. " --json")
	if not ok or not output then
		return
	end
	local windows = hs.json.decode(output)
	if not windows or #windows == 0 then
		return
	end
	table.sort(windows, function(a, b)
		return a["window-id"] < b["window-id"]
	end)
	local target = (index == 9) and windows[#windows] or windows[index]
	if not target then
		return
	end
	hs.execute(AEROSPACE_BIN .. " focus --window-id " .. target["window-id"])
end

ghosttyNumberHotkeys = {}
for i = 1, 9 do
	ghosttyNumberHotkeys[i] = hs.hotkey.new({ "cmd" }, tostring(i), function()
		focusGhosttyWindowByIndex(i)
	end)
end

ghosttyAppWatcher = hs.application.watcher.new(function(_, eventType, app)
	if eventType ~= hs.application.watcher.activated then
		return
	end
	local isGhostty = app and app:bundleID() == GHOSTTY_BUNDLE_ID
	for _, hotkey in ipairs(ghosttyNumberHotkeys) do
		if isGhostty then
			hotkey:enable()
		else
			hotkey:disable()
		end
	end
end)
ghosttyAppWatcher:start()
--]]
