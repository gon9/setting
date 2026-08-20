# setting

Mac のローカル設定リポジトリ。

- `karabiner.json` / `assets/` … Karabiner-Elements 設定
- `tmux/` … tmux 設定
- `claude/` … Claude Code のステータスライン設定
- `codex/` … Codex CLI のステータスライン設定
- `notify/` … Claude Code / Codex CLI の macOS 通知設定

## Karabiner-Elements

別の Mac に適用する:

```bash
git clone https://github.com/gon9/setting.git ~/.config/karabiner
```

その後、Karabiner-Elements を再起動すると設定が反映される。

## tmux

このリポジトリを clone した状態で、反映スクリプトを実行する:

```bash
~/.config/karabiner/tmux/install.sh
```

スクリプトが行うこと:

1. `tmux/tmux.conf` を `~/.tmux.conf` にシンボリックリンク
   （既存の実ファイルがある場合は `.backup.<日時>` に退避）
2. Dracula テーマ、tmux-resurrect、tmux-continuumを
   `~/.config/tmux/plugins/` 以下に `git clone`

反映後、tmux 内で `prefix + r`（もしくは `tmux source-file ~/.tmux.conf`）で再読込する。

### 主な設定

- ペイン分割: `prefix + -`（横）/ `prefix + |`（縦）
- 設定再読込: `prefix + r`
- ステータスライン: Dracula（`cwd` 表示、高コントラスト）
- ウィンドウ名を「フォルダ:フォアグラウンドコマンド」で自動更新
- セッション保存/復元: `prefix + Ctrl-s` / `prefix + Ctrl-r`
- tmux-continuum: 5分ごとに自動保存し、tmux起動時に自動復元
- 復元対象: ペイン内容とnvimセッション
- `allow-passthrough on`: 組み込み通知とプログレスバーを外側のターミナルへ通す

## Claude Code

Claude Code のステータスラインに、使用中のモデル名・作業ディレクトリ・git ブランチ・
コンテキスト使用率を表示する。tmux で複数セッションを並べたときに、
どのペインがどのモデルで動いているか一目で分かる。

```
✳ Opus 5 | owlclaw feature/statusline* 10%
```

反映スクリプトを実行する:

```bash
~/.config/karabiner/claude/install.sh
```

スクリプトが行うこと:

1. `claude/statusline.sh` を `~/.claude/statusline.sh` にシンボリックリンク
   （既存の実ファイルがある場合は `.backup.<日時>` に退避）
2. `~/.claude/settings.json` に `statusLine` を登録
   （他のキーは変更しない。実行前に `.backup.<日時>` を作成）

反映後、Claude Code を再起動する。`jq` が必要（`brew install jq`）。

### 表示内容

| 項目 | 内容 |
|------|------|
| モデル名 | `model.display_name`。無ければ `model.id` |
| ディレクトリ | 作業ディレクトリのベース名 |
| git ブランチ | 未コミットの変更があれば `*` を付ける |
| コンテキスト使用率 | 60% でオレンジ、80% で赤 |
| 出力スタイル | `default` 以外のときだけ表示 |

### 実装メモ

- 起動タイミングは Claude Code のイベント駆動（アシスタントのメッセージ到着 /
  `/compact` 完了 / 権限モード変更 / vim モード切替）。定期実行はしないので
  アイドル中の負荷はゼロ
- git 情報は 5 秒キャッシュする。キャッシュのヒット判定は取得時刻を
  キャッシュファイルの 1 行目に持たせることで `stat` を不要にし、
  ヒット時のサブプロセス生成を 0 個にしている
  （9,730 ファイルのリポジトリで実測 50ms → 14ms）
- 端末幅は `COLUMNS` 環境変数で判定する（出力がキャプチャされるため
  `tput cols` は使えない）。狭いときはブランチ名を省略する
- 不正な JSON や空入力でも必ず何か出力して `exit 0` する
  （非ゼロ終了・無出力だとステータスラインが空白になる仕様のため）

## Codex CLI

Codex CLI のフッターに、Claude Code と対応するセッション情報を表示する。

```
gpt-5.6-sol medium · owlclaw · main · Context 12% used · Ask for approval · Fast off
```

反映スクリプトを実行する:

```bash
~/.config/karabiner/codex/install.sh
```

スクリプトは `~/.codex/config.toml` の既存設定を保持したまま、`[tui]` の
`status_line` だけを追加または更新する。変更前の設定は
`config.toml.backup.<日時>` に退避する。反映後、新しく起動した Codex セッションから
表示が有効になる。

### 表示内容

| 項目 | Codex の識別子 |
|------|----------------|
| モデル名と推論レベル | `model-with-reasoning` |
| プロジェクト名 | `project` |
| git ブランチ | `git-branch` |
| コンテキスト使用率 | `context-used` |
| 承認モード | `approval-mode` |
| Fast モード | `fast-mode` |

Codex CLI のステータスラインはネイティブ項目の順序指定であり、Claude Code の
コマンド型ステータスラインとは異なる。現行の `git-branch` はワークツリーの
未コミット状態を `*` では表示しない。

## 通知（Claude Code / Codex CLI）

Claude Code と Codex CLI が「完了した」「許可を待っている」ときに macOS の通知を出す。
別ウィンドウで作業していてもターミナルを覗きに行かずに済む。

反映スクリプトを実行する:

```bash
~/.config/karabiner/notify/install.sh
```

スクリプトが行うこと:

1. `notify/agent-notify` と `notify/agent-notify-codex` を `~/.local/bin/` にシンボリックリンク
   （既存の実ファイルがある場合は `.backup.<日時>` に退避）
2. `~/.claude/settings.json` の `hooks.Notification` / `hooks.Stop` を登録
3. `~/.codex/config.toml` の `[tui]` 通知設定と `notify` を登録

`jq` が必要（`brew install jq`）。何度実行しても重複しない。

### 手動で必要な設定

macOS の通知許可はリポジトリで持ち回せないので、Mac ごとに一度だけ設定する:

1. `brew install terminal-notifier`（任意。サウンドとサブタイトルが付く。
   未インストールなら `osascript` にフォールバックし、通知元は Script Editor になる）
2. 通知テスト: `~/.local/bin/agent-notify "Claude Code" "テスト" "通知が出れば成功"`
3. ポップアップが出ないときは **システム設定 > 通知** で terminal-notifier
   （または Script Editor）の通知を許可する。「通知の要約」と集中モードも確認する
4. Claude Code と Codex を再起動する

### 発火タイミング

| CLI | イベント | いつ鳴るか |
|-----|----------|------------|
| Claude Code | `Stop` フック | 応答が終わるたびに即時 |
| Claude Code | `Notification` フック（`permission_prompt`） | 許可プロンプトが出て約6秒、キー入力がなければ |
| Claude Code | `Notification` フック（`idle_prompt`） | 応答完了から約60秒、キー入力がなければ |
| Codex CLI | `[tui] notifications` | ターミナルが非フォアグラウンドのときだけ（`notification_condition = "unfocused"`） |
| Codex CLI | `notify` | ターン完了時に外部コマンドへ JSON を渡す |

離席時は Claude Code の `Stop` と `idle_prompt` が両方鳴る。完了通知を離席時だけに
絞りたい場合は `hooks.Stop` を外す（`idle_prompt` が完了通知を兼ねる）。

### 設計メモ

- `settings.json` には `"$HOME/.local/bin/agent-notify"` と書く。フックは `sh -c` 経由で
  実行されるので `$HOME` が展開され、ユーザ名の違う Mac でも設定ファイルがそのまま動く
- tmux 経由だと Claude Code / Codex の**組み込み通知**（エスケープシーケンス方式）は
  握り潰される。フックは別プロセスを起動するので tmux を貫通する。
  組み込み通知も使いたい場合は `tmux/tmux.conf` の `allow-passthrough on` が必要
- `config.toml` の `notify` は既に別のコマンドが入っていれば上書きしない。
  Codex Computer Use が自前のラッパを噛ませていることがあり、壊すと困るため
- `agent-notify-codex` は同じディレクトリの `agent-notify` を呼ぶので、
  2つは必ず同じ場所に置く
