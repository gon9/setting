#!/usr/bin/env bash
# Claude Code ステータスライン
#
# 起動タイミングは Claude Code 側のイベント駆動（アシスタントのメッセージ到着 /
# compact 完了 / 権限モード変更 / vim モード切替）。定期実行はしない。
#
# 設計方針（公式ドキュメントの Tips に準拠）:
#   - 出力は 1 行・短く保つ（右側に MCP エラー等の通知が重なるため余白を残す）
#   - git は遅いのでキャッシュする。キャッシュ機構自体もサブプロセスを使わず組む
#   - 幅は COLUMNS 環境変数で判定する（tput cols は使えない）
#   - 必ず 0 で終了し、必ず何か出力する（非ゼロ終了・無出力だと表示が消える）

set -uo pipefail

input=$(cat)

# --- JSON から必要な値を取り出す（値に空白を含みうるので改行区切りで受ける） ---
IFS=$'\n' read -r -d '' model dir ctx style < <(
  printf '%s' "$input" | jq -r '
    (.model.display_name // .model.id // "unknown"),
    (.workspace.current_dir // .cwd // "."),
    (.context_window.used_percentage // -1 | tostring),
    (.output_style.name // "default")
  ' 2>/dev/null
  printf '\0'
)
: "${model:=unknown}" "${dir:=.}" "${ctx:=-1}" "${style:=default}"

# --- git 情報（5 秒キャッシュ） ---------------------------------------------
# キャッシュファイルの 1 行目に「取得時刻 ブランチ名」を入れておく。
# こうすると mtime を見るための stat を呼ばずに済み、ヒット時はサブプロセス 0 個。
git_info() {
  local cache_dir cache now ts cached branch
  cache_dir="${TMPDIR:-/tmp}/claude-statusline"
  local key="${dir//\//_}"; key="${key//./_}"
  cache="$cache_dir/c${key}"
  now=${EPOCHSECONDS:-$(date +%s)}

  if [[ -r "$cache" ]] && read -r ts cached < "$cache" 2>/dev/null; then
    if [[ "$ts" =~ ^[0-9]+$ ]] && (( now - ts < 5 )); then
      printf '%s' "$cached"
      return 0
    fi
  fi

  [[ -d "$cache_dir" ]] || mkdir -p "$cache_dir" 2>/dev/null || return 0
  branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [[ -n "$branch" && -n $(git -C "$dir" status --porcelain --untracked-files=no 2>/dev/null | head -1) ]]; then
    branch="${branch}*"
  fi
  printf '%s %s\n' "$now" "$branch" > "$cache" 2>/dev/null
  printf '%s' "$branch"
}
branch=$(git_info)

# --- 色 ---------------------------------------------------------------------
e=$'\033'
c_model="${e}[1;38;5;213m"  # モデル名: マゼンタ太字
c_dim="${e}[38;5;245m"      # 補助情報: グレー
c_git="${e}[38;5;114m"      # git: グリーン
c_warn="${e}[38;5;215m"     # 注意: オレンジ
c_hot="${e}[38;5;203m"      # 逼迫: レッド
r="${e}[0m"

ctx_color="$c_dim"
if   [[ "$ctx" =~ ^[0-9]+$ ]] && (( ctx >= 80 )); then ctx_color="$c_hot"
elif [[ "$ctx" =~ ^[0-9]+$ ]] && (( ctx >= 60 )); then ctx_color="$c_warn"
fi

# --- 幅に応じて情報量を落とす（右端は通知用に 20 桁空ける） -------------------
base="${dir##*/}"
cols=${COLUMNS:-100}
budget=$((cols - 20))
(( budget < 20 )) && budget=20

plain="✳ $model | $base"
[[ -n "$branch" ]] && plain+=" $branch"
[[ "$ctx" =~ ^[0-9]+$ ]] && plain+=" ${ctx}%"

if (( ${#plain} > budget )) && [[ -n "$branch" ]]; then
  keep=$(( budget - ${#plain} + ${#branch} ))
  (( keep < 8 )) && keep=8
  (( ${#branch} > keep )) && branch="${branch:0:keep-1}…"
fi

out="${c_model}✳ ${model}${r} ${c_dim}| ${base}${r}"
[[ -n "$branch" ]] && out+=" ${c_git}${branch}${r}"
[[ "$ctx" =~ ^[0-9]+$ ]] && out+=" ${ctx_color}${ctx}%${r}"
[[ "$style" != "default" && "$style" != "null" ]] && out+=" ${c_dim}[${style}]${r}"

printf '%s' "$out"
exit 0
