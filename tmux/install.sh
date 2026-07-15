#!/usr/bin/env bash
#
# tmux 設定を反映するスクリプト
#   1. このリポジトリの tmux.conf を ~/.tmux.conf にシンボリックリンク
#   2. Dracula テーマプラグイン（サードパーティ）を導入
#
# 使い方:
#   ./tmux/install.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/tmux.conf"
DEST="$HOME/.tmux.conf"
PLUGIN_DIR="$HOME/.config/tmux/plugins/dracula"
DRACULA_REPO="https://github.com/dracula/tmux.git"

# 1. tmux.conf をシンボリックリンク
if [ -e "$DEST" ] && [ ! -L "$DEST" ]; then
  backup="$DEST.backup.$(date +%Y%m%d%H%M%S)"
  echo "既存の $DEST を $backup に退避します"
  mv "$DEST" "$backup"
fi
ln -sfn "$SRC" "$DEST"
echo "リンク作成: $DEST -> $SRC"

# 2. Dracula テーマ（tmux.conf が run で参照）
if [ -d "$PLUGIN_DIR/.git" ]; then
  echo "Dracula テーマを更新します: $PLUGIN_DIR"
  git -C "$PLUGIN_DIR" pull --ff-only
else
  echo "Dracula テーマを取得します: $PLUGIN_DIR"
  git clone --depth 1 "$DRACULA_REPO" "$PLUGIN_DIR"
fi

echo ""
echo "完了しました。"
echo "  - tmux 起動中なら prefix + r で再読込"
echo "  - もしくは: tmux source-file ~/.tmux.conf"
