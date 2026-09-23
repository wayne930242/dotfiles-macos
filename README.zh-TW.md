# macOS Dotfiles - 電馭叛客風格

個人 macOS 設定檔，打造電馭叛客風格的桌面環境。

## 元件

- **[AeroSpace](https://github.com/nikitabobko/AeroSpace)** - 平鋪式視窗管理器
- **[SketchyBar](https://github.com/FelixKratz/SketchyBar)** - 自訂選單列
- **[JankyBorders](https://github.com/FelixKratz/JankyBorders)** - 視窗邊框
- **[Ghostty](https://ghostty.org/)** - 終端機，只當 herdr 的宿主 surface：啟動直接進 herdr，原生 tab/split 快捷鍵全部 unbind、關閉視窗裝飾，macOS 層級只會看到一個視窗
- **[herdr](https://herdr.dev)** - Agent multiplexer，workspace/tab/pane 全部在單一 persistent session 裡管理（預設 `Ctrl+B` prefix）
- **[Hammerspoon](https://www.hammerspoon.org/)** - 偵測雙擊 CMD 後送出 F19，由 Ghostty 的 global keybind 開關 quick terminal
- **[tmux](https://github.com/tmux/tmux)** - 選用、需要時才手動開：`bin/tm [名稱]` 接到指定名稱的 session，`bin/zed-tmux` 讓 Zed 各專案有獨立的 persistent session
- **[LazyVim](https://www.lazyvim.org/)** - Neovim 設定，包含適合 CJK 的折行與拼字檢查、Yazi、Snacks Explorer（顯示 git 與 submodule 狀態）、Claude Code 整合、依目錄自動還原 session，以及 smart-splits 視窗導航

## 截圖

![電馭叛客桌面](screenshot.png)

## 快速安裝

```bash
git clone https://github.com/wayne930242/dotfiles-macos.git ~/dotfiles-macos
cd ~/dotfiles-macos
./install.sh
```

安裝腳本會自動：
1. 安裝 Homebrew（如未安裝）
2. 安裝 AeroSpace、Hammerspoon、SketchyBar、JankyBorders、nowplaying-cli、Neovim 與 Yazi
3. 備份現有設定至 `~/.dotfiles-backup/`
4. 建立 SketchyBar、JankyBorders、Neovim、Ghostty、AeroSpace、tmux、Hammerspoon 與 herdr 的 symlinks
5. 啟動所有服務並重新啟動 AeroSpace，確保 CLI 與 app server 使用相同版本

Ghostty、herdr、tmux 與字型不在腳本安裝範圍內，請見[前置需求](#前置需求)。

安裝完成後，先開一次 Hammerspoon、授予輔助使用權限，再從選單列圖示啟用「Launch at Login」。

### 其他指令

```bash
./install.sh install    # 安裝（預設）
./install.sh uninstall  # 移除 symlinks 並停止服務
./install.sh restore    # 從備份還原
./install.sh help       # 顯示說明
```

## 手動安裝

### 前置需求

```bash
brew install --cask nikitabobko/tap/aerospace
brew install --cask hammerspoon
brew tap FelixKratz/formulae
brew install sketchybar
brew install borders
brew install nowplaying-cli  # 媒體小工具需要
brew install --cask ghostty
brew install herdr
brew install tmux            # 選用，bin/tm 與 bin/zed-tmux 需要
brew install neovim yazi
brew install --cask font-iansui  # Ghostty 的台、客語缺字備援
```

Ghostty 另外需要 `MesloLGS NF`，SketchyBar 使用 `Hack Nerd Font Mono`。

### 設定

```bash
# 複製此專案
git clone https://github.com/wayne930242/dotfiles-macos.git ~/dotfiles-macos

# 建立 symlinks
ln -sf ~/dotfiles-macos/sketchybar ~/.config/sketchybar
ln -sf ~/dotfiles-macos/borders ~/.config/borders
ln -sf ~/dotfiles-macos/nvim ~/.config/nvim
ln -sf ~/dotfiles-macos/ghostty ~/.config/ghostty
ln -sf ~/dotfiles-macos/.aerospace.toml ~/.aerospace.toml
ln -sf ~/dotfiles-macos/.tmux.conf ~/.tmux.conf
ln -sf ~/dotfiles-macos/hammerspoon ~/.hammerspoon
mkdir -p ~/.config/herdr
ln -sf ~/dotfiles-macos/herdr/config.toml ~/.config/herdr/config.toml

# 啟動服務
brew services start sketchybar
brew services start borders
```

第一次啟動 Neovim 時，LazyVim 會自動啟動 `lazy.nvim`，並安裝 `nvim/lazy-lock.json` 鎖定的外掛版本。

## Zed 整合

`bin/zed-tmux` wrapper 讓 Zed terminal panel 接到專案專屬的 tmux session(命名為 `zed-<專案資料夾名>`),每個專案各自保留 shell 狀態,跨 Zed 重啟仍持續。

在 `~/.config/zed/settings.json` 加上:

```jsonc
"terminal": {
  "shell": {
    "with_arguments": {
      "program": "/Users/<你>/dotfiles-macos/bin/zed-tmux",
      "args": []
    }
  }
}
```

## 工作區

| 快捷鍵 | 工作區 | 用途 |
|--------|--------|------|
| `alt-1` | 1 | 終端機 (Ghostty) |
| `alt-2` ~ `alt-3` | 2–3 | 一般使用 |
| `alt-c` | C | 瀏覽器 (Chrome / Comet) |
| `alt-g` | G | 遊戲 / 休閒 |
| `alt-s` | S | 社交 (Discord, Telegram) |
| `alt-q` | Q | 專案 (Linear + Slack) |
| `alt-d` | D | Docker |
| `alt-a` | A | AI / Agents |
| `alt-z` | Z | Obsidian (筆記) |
| `alt-x` | X | Xcode（含 Simulator 與 Android Studio） |

有外接螢幕時，工作區 1–3 放在副螢幕；字母工作區固定在主螢幕。
`alt-enter` 開啟 Ghostty，`alt-shift-;` 進入 service mode（按 `esc` 重新載入設定）。

## SketchyBar 小工具

**左側：** 模式指示（service mode）| 工作區 | 前景 App

**右側：** 日曆 | 音訊（音量 + 麥克風）| 電池 | 溫度 | 輸入法 | 網路 | 媒體 | CPU / 記憶體

## 主題配色

SketchyBar 與 JankyBorders 使用電馭叛客色票：
- 主色：`#00fff7` (霓虹青)
- 副色：`#ff00ff` (洋紅)
- 強調色：`#ff6600` (橘色)
- 背景：`#0a0a0f` (深色)

Ghostty 使用 `Dracula` 主題，90% 不透明度加模糊；herdr 使用 `vesper`。

## 測試

`tests/` 放的是 AeroSpace 設定、安裝腳本與主題設定的 shell contract 檢查：

```bash
for t in tests/*.sh; do bash "$t"; done
```

## 授權

MIT
