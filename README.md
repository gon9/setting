# setting

Mac のローカル設定リポジトリ。

- `karabiner.json` / `assets/` … Karabiner-Elements 設定
- `tmux/` … tmux 設定

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
