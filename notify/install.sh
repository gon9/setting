#!/usr/bin/env bash
#
# Claude Code / Codex CLI の macOS 通知設定を反映するスクリプト
#   1. notify/agent-notify, notify/agent-notify-codex を ~/.local/bin にシンボリックリンク
#   2. ~/.claude/settings.json の hooks に Notification / Stop を登録（既存の他フックは保持）
#   3. ~/.codex/config.toml の [tui] 通知設定と notify を登録（既存設定は保持）
#
# 使い方:
#   ./notify/install.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
CODEX_CONFIG="${CODEX_HOME:-$HOME/.codex}/config.toml"
STAMP="$(date +%Y%m%d%H%M%S)"

# settings.json には $HOME を残す。ユーザ名が違う Mac でもそのまま動くようにするため。
# フックは sh -c 経由で実行されるので $HOME は実行時に展開される。
NOTIFY_BIN='"$HOME/.local/bin/agent-notify"'
CODEX_NOTIFY_BIN="$BIN_DIR/agent-notify-codex"

if ! command -v jq >/dev/null 2>&1; then
  echo "エラー: jq が必要です" >&2
  echo "  brew install jq" >&2
  exit 1
fi

# ---------------------------------------------------------------- 1. リンク
mkdir -p "$BIN_DIR"
for name in agent-notify agent-notify-codex; do
  src="$SCRIPT_DIR/$name"
  dest="$BIN_DIR/$name"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "既存の $dest を $dest.backup.$STAMP に退避します"
    mv "$dest" "$dest.backup.$STAMP"
  fi
  ln -sfn "$src" "$dest"
  echo "リンク作成: $dest -> $src"
done

# ------------------------------------------------------- 2. Claude Code hooks
mkdir -p "$(dirname "$CLAUDE_SETTINGS")"
if [ ! -f "$CLAUDE_SETTINGS" ]; then
  echo '{}' > "$CLAUDE_SETTINGS"
  echo "新規作成: $CLAUDE_SETTINGS"
else
  cp "$CLAUDE_SETTINGS" "$CLAUDE_SETTINGS.backup.$STAMP"
  echo "バックアップ: $CLAUDE_SETTINGS.backup.$STAMP"
fi

# agent-notify を指す既存エントリは一度取り除いてから入れ直す。
# 何度実行しても重複せず、旧バージョンの絶対パス直書きも自動で置き換わる。
tmp="$(mktemp)"
jq \
  --arg notification "$NOTIFY_BIN \"Claude Code\" \"入力/許可待ち\" \"操作を待っています\"" \
  --arg stop "$NOTIFY_BIN \"Claude Code\" \"完了\" \"応答が完了しました\"" '
  def prune:
    (. // [])
    | map(.hooks |= (map(select((.command // "") | test("agent-notify") | not))))
    | map(select((.hooks // []) | length > 0));

  .hooks //= {}
  | .hooks.Notification = (.hooks.Notification | prune) + [{hooks: [{type: "command", command: $notification}]}]
  | .hooks.Stop         = (.hooks.Stop         | prune) + [{hooks: [{type: "command", command: $stop}]}]
' "$CLAUDE_SETTINGS" > "$tmp"
mv "$tmp" "$CLAUDE_SETTINGS"
echo "登録: settings.json の hooks.Notification / hooks.Stop -> \$HOME/.local/bin/agent-notify"

# -------------------------------------------------------- 3. Codex CLI 通知
mkdir -p "$(dirname "$CODEX_CONFIG")"
if [ -f "$CODEX_CONFIG" ]; then
  cp -p "$CODEX_CONFIG" "$CODEX_CONFIG.backup.$STAMP"
  echo "バックアップ: $CODEX_CONFIG.backup.$STAMP"
else
  : > "$CODEX_CONFIG"
  echo "新規作成: $CODEX_CONFIG"
fi

# root の notify は既存の値を尊重する。Codex Computer Use などが自前の
# ラッパを噛ませている場合があり、上書きするとそちらが壊れるため。
notify_state="add"
if grep -q 'agent-notify-codex' "$CODEX_CONFIG"; then
  notify_state="present"
elif grep -qE '^[[:space:]]*notify[[:space:]]*=' "$CODEX_CONFIG"; then
  notify_state="foreign"
fi

tmp="$(mktemp)"
awk -v notify_line="notify = [\"$CODEX_NOTIFY_BIN\"]" -v add_notify="$notify_state" '
  function emit_tui_keys() {
    if (!tui_written) {
      print "notifications = true"
      print "notification_condition = \"unfocused\""
      print "notification_method = \"auto\""
      tui_written = 1
    }
  }

  # テーブル見出し
  /^\[[^]]+\][[:space:]]*$/ {
    if (in_tui) emit_tui_keys()
    # root の notify は最初のテーブルより前に置く
    if (!past_root) {
      if (add_notify == "add" && !notify_written) {
        print notify_line
        notify_written = 1
      }
      past_root = 1
    }
    in_tui = ($0 == "[tui]")
    if (in_tui) tui_seen = 1
    print
    next
  }

  # [tui] 内の対象キーは落として末尾でまとめて出し直す
  in_tui && /^[[:space:]]*(notifications|notification_condition|notification_method)[[:space:]]*=/ {
    next
  }

  { print }

  END {
    if (in_tui) emit_tui_keys()
    if (!past_root && add_notify == "add" && !notify_written) {
      print notify_line
      notify_written = 1
    }
    if (!tui_seen) {
      print ""
      print "[tui]"
      emit_tui_keys()
    }
  }
' "$CODEX_CONFIG" > "$tmp"
mv "$tmp" "$CODEX_CONFIG"

echo "登録: config.toml の [tui] notifications / notification_condition / notification_method"
case "$notify_state" in
  add)     echo "登録: config.toml の notify -> $CODEX_NOTIFY_BIN" ;;
  present) echo "スキップ: notify は既に agent-notify-codex を参照しています" ;;
  foreign) echo "スキップ: notify に別のコマンドが設定済みです。必要なら手動で $CODEX_NOTIFY_BIN を繋いでください" ;;
esac

# ------------------------------------------------------------------ 後処理
echo ""
echo "完了しました。残りは Mac ごとに手動で確認してください。"
echo ""
echo "  1. terminal-notifier を入れると通知にサウンドとサブタイトルが付きます（任意）"
echo "       brew install terminal-notifier"
echo "     未インストールなら osascript にフォールバックします（通知元は Script Editor）"
echo "  2. 通知テスト:"
echo "       $BIN_DIR/agent-notify \"Claude Code\" \"テスト\" \"通知が出れば成功\""
echo "  3. ポップアップが出ない場合は システム設定 > 通知 で"
echo "     terminal-notifier / Script Editor の通知を許可し、集中モードも確認する"
echo "  4. Claude Code と Codex を再起動する"
