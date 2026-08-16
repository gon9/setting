#!/bin/sh
# Codex CLI のネイティブステータスラインを ~/.codex/config.toml に反映する。
# 既存の設定は保持し、[tui] の status_line だけを追加または置換する。

set -eu

CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
CONFIG="$CODEX_DIR/config.toml"
STATUS_LINE='status_line = ["model-with-reasoning", "project", "git-branch", "context-used", "approval-mode", "fast-mode"]'
TIMESTAMP=$(date +%Y%m%d%H%M%S)

mkdir -p "$CODEX_DIR"

if [ -f "$CONFIG" ]; then
  cp -p "$CONFIG" "$CONFIG.backup.$TIMESTAMP"
fi

TMP=$(mktemp "$CODEX_DIR/config.toml.tmp.XXXXXX")
trap 'rm -f "$TMP"' EXIT HUP INT TERM

if [ -f "$CONFIG" ]; then
  awk -v status_line="$STATUS_LINE" '
    function emit_status_line() {
      if (!status_written) {
        print status_line
        status_written = 1
      }
    }

    /^\[[^]]+\][[:space:]]*$/ {
      if (in_tui) {
        emit_status_line()
      }
      in_tui = ($0 == "[tui]")
      if (in_tui) {
        tui_seen = 1
      }
      print
      next
    }

    in_tui && /^[[:space:]]*status_line[[:space:]]*=/ {
      emit_status_line()
      next
    }

    { print }

    END {
      if (in_tui) {
        emit_status_line()
      } else if (!tui_seen) {
        print ""
        print "[tui]"
        emit_status_line()
      }
    }
  ' "$CONFIG" > "$TMP"
else
  printf '[tui]\n%s\n' "$STATUS_LINE" > "$TMP"
fi

mv "$TMP" "$CONFIG"
trap - EXIT HUP INT TERM

echo "Codex status line configured: $CONFIG"
echo "Restart Codex to apply it."
