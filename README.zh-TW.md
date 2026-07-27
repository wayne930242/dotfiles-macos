# macOS Dotfiles - 電馭叛客風格

個人 macOS 設定檔，打造電馭叛客風格的桌面環境。

## 元件

- **[AeroSpace](https://github.com/nikitabobko/AeroSpace)** - 平鋪式視窗管理器
- **[SketchyBar](https://github.com/FelixKratz/SketchyBar)** - 自訂選單列
- **[JankyBorders](https://github.com/FelixKratz/JankyBorders)** - 視窗邊框
- **[WezTerm](https://wezfurlong.org/wezterm/)** - 終端機，配置 tmux-like leader 快捷鍵與 unix-domain mux 持久會話
- **[tmux](https://github.com/tmux/tmux)** - 終端機多工器，鍵位對齊 WezTerm leader；附 `bin/zed-tmux` wrapper 讓 Zed 各專案有獨立的 persistent session
- **[LazyVim](https://www.lazyvim.org/)** - Neovim 設定，包含適合 CJK 的折行、Yazi、Sidekick、Snacks Explorer 與跨 pane 導航

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
2. 安裝 AeroSpace、SketchyBar、JankyBorders 及相依套件
3. 備份現有設定至 `~/.dotfiles-backup/`
4. 建立 symlinks，包括 `~/.config/nvim`
5. 啟動所有服務並重新啟動 AeroSpace，確保 CLI 與 app server 使用相同版本

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
brew tap FelixKratz/formulae
brew install sketchybar
brew install borders
brew install nowplaying-cli  # 媒體小工具需要
brew install --cask wezterm
brew install tmux
brew install neovim yazi
```

### 設定

```bash
# 複製此專案
git clone https://github.com/wayne930242/dotfiles-macos.git ~/dotfiles-macos

# 建立 symlinks
ln -sf ~/dotfiles-macos/sketchybar ~/.config/sketchybar
ln -sf ~/dotfiles-macos/borders ~/.config/borders
ln -sf ~/dotfiles-macos/nvim ~/.config/nvim
ln -sf ~/dotfiles-macos/.aerospace.toml ~/.aerospace.toml
ln -sf ~/dotfiles-macos/.wezterm.lua ~/.wezterm.lua
ln -sf ~/dotfiles-macos/.tmux.conf ~/.tmux.conf

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
| `alt-1` ~ `alt-5` | 1–5 | 一般使用 |
| `alt-w` | W | 終端機 (WezTerm) |
| `alt-c` | C | 瀏覽器 (Chrome / Comet) |
| `alt-g` | G | 遊戲 / 休閒 |
| `alt-s` | S | 社交 (Discord, Slack, Telegram) |
| `alt-q` | Q | 專案 (Linear + Slack) |
| `alt-d` | D | Docker |
| `alt-a` | A | AI / Agents |
| `alt-z` | Z | Obsidian (筆記) |
| `alt-x` | X | Xcode |

## SketchyBar 小工具

**左側：** 工作區 | 前景 App | Git 分支

**右側：** 日曆 | 音量/麥克風 | 輸入法 | 電池 | 天氣 | 網路 | 媒體 | CPU | 記憶體

## 主題配色

電馭叛客色票：
- 主色：`#00fff7` (霓虹青)
- 副色：`#ff00ff` (洋紅)
- 強調色：`#ff6600` (橘色)
- 背景：`#0a0a0f` (深色)

## 授權

MIT
