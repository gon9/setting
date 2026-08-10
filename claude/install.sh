#!/usr/bin/env bash
#
# Claude Code のステータスライン設定を反映するスクリプト
#   1. このリポジトリの statusline.sh を ~/.claude/statusline.sh にシンボリックリンク
#   2. ~/.claude/settings.json に statusLine の設定を追記（既存設定は保持）
#
# 使い方:
#   ./claude/install.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/statusline.sh"
CLAUDE_DIR="$HOME/.claude"
DEST="$CLAUDE_DIR/statusline.sh"
SETTINGS="$CLAUDE_DIR/settings.json"

if ! command -v jq >/dev/null 2>&1; then
  echo "エラー: jq が必要です（statusline.sh も jq を使います）" >&2
  echo "  brew install jq" >&2
  exit 1
fi

mkdir -p "$CLAUDE_DIR"

# 1. statusline.sh をシンボリックリンク
if [ -e "$DEST" ] && [ ! -L "$DEST" ]; then
  backup="$DEST.backup.$(date +%Y%m%d%H%M%S)"
  echo "既存の $DEST を $backup に退避します"
  mv "$DEST" "$backup"
fi
ln -sfn "$SRC" "$DEST"
echo "リンク作成: $DEST -> $SRC"

# 2. settings.json に statusLine を登録（他のキーは触らない）
if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
  echo "新規作成: $SETTINGS"
else
  backup="$SETTINGS.backup.$(date +%Y%m%d%H%M%S)"
  cp "$SETTINGS" "$backup"
  echo "バックアップ: $backup"
fi

tmp="$(mktemp)"
jq --arg cmd "$DEST" \
  '.statusLine = {type: "command", command: $cmd, padding: 0}' \
  "$SETTINGS" > "$tmp"
mv "$tmp" "$SETTINGS"
echo "登録: settings.json の statusLine -> $DEST"

echo ""
echo "完了しました。Claude Code を再起動すると反映されます。"
