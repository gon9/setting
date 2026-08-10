# setting

Mac のローカル設定リポジトリ。

- `karabiner.json` / `assets/` … Karabiner-Elements 設定
- `tmux/` … tmux 設定
- `claude/` … Claude Code のステータスライン設定

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
2. Dracula テーマプラグイン（サードパーティ / MIT）を
   `~/.config/tmux/plugins/dracula` に `git clone`

反映後、tmux 内で `prefix + r`（もしくは `tmux source-file ~/.tmux.conf`）で再読込する。

### 主な設定

- ペイン分割: `prefix + -`（横）/ `prefix + |`（縦）
- 設定再読込: `prefix + r`
- ステータスライン: Dracula（`cwd` 表示、高コントラスト）
- ウィンドウ名を「フォルダ:フォアグラウンドコマンド」で自動更新

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
