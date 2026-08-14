-- Hammerspoon 設定檔
-- 位置: dotfiles-macos/hammerspoon/init.lua → symlink 到 ~/.hammerspoon/init.lua
--
-- 舊版 WezTerm scratchpad 功能（雙擊 CMD 召喚/收回）已撤銷：測試過程中疑似與
-- AeroSpace focus/WezTerm 渲染互相影響，導致 WezTerm 一度完全無法輸入，根因
-- 當時沒查清楚。這裡改用完全不同的實作方式重做：只監聽 flagsChanged 事件
-- 判斷雙擊 CMD，偵測到後單純送出一個合成按鍵 (F19)，不碰任何視窗/focus API，
-- 交給 Ghostty 自己的 global keybind 去開關 quick terminal——風險面比舊版小
-- 很多，但仍是同一個「雙擊 CMD」手勢，上線後要留意輸入是否正常。

-- 雙擊 CMD 召喚 Ghostty quick terminal (見 ghostty/config 的 global:f19 keybind)
local DOUBLE_TAP_WINDOW = 0.35
local lastCmdUpAt = 0
local cmdWasAloneThisPress = false
local otherKeyDuringCmd = false

local function resetCmdTapState()
	cmdWasAloneThisPress = false
	otherKeyDuringCmd = false
end

cmdDoubleTapFlagsWatcher = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(event)
	local flags = event:getFlags()
	local cmdOnly = flags.cmd and not flags.shift and not flags.alt and not flags.ctrl and not flags.fn

	if cmdOnly then
		-- CMD 剛按下，且沒有夾其他 modifier
		cmdWasAloneThisPress = true
		otherKeyDuringCmd = false
	elseif not flags.cmd and cmdWasAloneThisPress then
		-- CMD 剛放開，且這次按壓期間沒有夾雜其他鍵，才算一次有效的「單擊 CMD」
		local now = hs.timer.secondsSinceEpoch()
		if not otherKeyDuringCmd and (now - lastCmdUpAt) < DOUBLE_TAP_WINDOW then
			hs.eventtap.keyStroke({}, "F19")
			lastCmdUpAt = 0
		else
			lastCmdUpAt = now
		end
		resetCmdTapState()
	else
		resetCmdTapState()
	end
	return false
end)

-- CMD 按著期間如果夾了其他鍵 (例如 CMD+C)，代表這是個組合鍵而不是單純點一下 CMD，
-- 這次按壓不該被算進雙擊判斷，避免快速連續按 CMD+C / CMD+V 誤觸發
cmdDoubleTapKeyDownWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(_)
	if cmdWasAloneThisPress then
		otherKeyDuringCmd = true
	end
	return false
end)

cmdDoubleTapFlagsWatcher:start()
cmdDoubleTapKeyDownWatcher:start()

-- CMD+1~9 多視窗切換器停用：改用 herdr 管 tab/workspace，Ghostty 只剩一個
-- NSWindow 可切，CMD+1-9 現在由 native-shortcuts-herd 裝的 Ghostty keybind
-- sidecar（~/.config/native-shortcuts-herd/ghostty.conf）直接轉成 escape
-- sequence 送給 herdr，不需要 Hammerspoon 代勞了。留著沒啟用是因為如果哪天
-- 放棄 herdr、要走回多視窗模式，這段邏輯還能直接復用。
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
