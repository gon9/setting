#!/usr/bin/env bash
#
# tmux 設定を反映するスクリプト
#   1. このリポジトリの tmux.conf を ~/.tmux.conf にシンボリックリンク
#   2. Dracula / tmux-resurrect / tmux-continuum を導入
#
# 使い方:
#   ./tmux/install.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/tmux.conf"
DEST="$HOME/.tmux.conf"
PLUGIN_ROOT="$HOME/.config/tmux/plugins"
DRACULA_DIR="$PLUGIN_ROOT/dracula/tmux"
RESURRECT_DIR="$PLUGIN_ROOT/tmux-resurrect"
CONTINUUM_DIR="$PLUGIN_ROOT/tmux-continuum"
DRACULA_REPO="https://github.com/dracula/tmux.git"
RESURRECT_REPO="https://github.com/tmux-plugins/tmux-resurrect.git"
CONTINUUM_REPO="https://github.com/tmux-plugins/tmux-continuum.git"

install_plugin() {
  label="$1"
  repo="$2"
  target="$3"
  marker="$4"

  if [ -e "$target/$marker" ]; then
    echo "$label は既に存在します: $target"
    return
  fi

  if [ -e "$target" ]; then
    echo "エラー: $label の配置先は存在しますが $marker がありません: $target" >&2
    exit 1
  fi

  echo "$label を取得します: $target"
  mkdir -p "$(dirname "$target")"
  git clone --depth 1 "$repo" "$target"
}

# 1. tmux.conf をシンボリックリンク
if [ -e "$DEST" ] && [ ! -L "$DEST" ]; then
  backup="$DEST.backup.$(date +%Y%m%d%H%M%S)"
  echo "既存の $DEST を $backup に退避します"
  mv "$DEST" "$backup"
fi
ln -sfn "$SRC" "$DEST"
echo "リンク作成: $DEST -> $SRC"

# 2. tmux.conf が run で参照するプラグイン
install_plugin "Dracula テーマ" "$DRACULA_REPO" "$DRACULA_DIR" "dracula.tmux"
install_plugin "tmux-resurrect" "$RESURRECT_REPO" "$RESURRECT_DIR" "resurrect.tmux"
install_plugin "tmux-continuum" "$CONTINUUM_REPO" "$CONTINUUM_DIR" "continuum.tmux"

echo ""
echo "完了しました。"
echo "  - tmux 起動中なら prefix + r で再読込"
echo "  - もしくは: tmux source-file ~/.tmux.conf"
