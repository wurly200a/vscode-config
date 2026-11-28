# vscode-config

VS Code の設定を Git で管理し、どのマシンでも同じ環境にするためのリポジトリ。

メインエディタは Emacs のまま、VS Code は**用途ごとに分けた専用環境**として使う。
各用途の方針は「その用途に要るものだけ出す」。更新通知・Tips・Welcome・AI 系 UI などは出さない。

| 用途 | ランチャ | 内容 |
| --- | --- | --- |
| `viewer` | `code-viewer` | Markdown 閲覧（Mermaid・数式・画像込み） |

## 仕組み

用途ごとに `--user-data-dir` と `--extensions-dir` を分けて起動する（Emacs の `--init-directory` と同じ発想）。
設定・拡張・ウィンドウ状態は用途間で干渉せず、普通の `code` にも影響しない。

VS Code 標準の「プロファイル」機能は、設定ファイルがランダムな ID のディレクトリに置かれてシンボリックリンクで管理しにくいため使わない。

```
profiles/<name>/          ← このリポジトリ（Git 管理）
  settings.json
  keybindings.json        （任意）
  extensions.txt          （任意）
  profile.conf            （任意）ランチャの起動オプション

<BASE>/<name>/            ← 各マシンのデータ（Git 管理外）
  data/User/settings.json     → profiles/<name>/settings.json へのリンク
  data/User/keybindings.json  → profiles/<name>/keybindings.json へのリンク
  extensions/                 用途専用の拡張
```

| OS | `<BASE>` | ランチャの置き場所 |
| --- | --- | --- |
| Linux | `~/.local/share/vscode-profiles` | `~/.local/bin/code-<name>` |
| macOS | `~/Library/Application Support/vscode-profiles` | `~/.local/bin/code-<name>` |
| Windows | `%LOCALAPPDATA%\vscode-profiles` | `%LOCALAPPDATA%\vscode-profiles\bin\code-<name>.cmd` |

## セットアップ

### 1. VS Code 本体

**Windows**

```powershell
winget install Microsoft.VisualStudioCode
```

**Ubuntu**

公式の最新版 `.deb`（x64）をダウンロードしてインストールする:

```bash
# インストール時の「Microsoft の apt リポジトリを追加するか」の確認に、あらかじめ yes と答えておく
echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections

curl -fL -o /tmp/code.deb "https://go.microsoft.com/fwlink/?LinkID=760868"
sudo apt install /tmp/code.deb
rm /tmp/code.deb
```

Microsoft の apt リポジトリが追加され、以後は `apt upgrade` で更新される。

Arm64 の場合は URL を `https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-arm64` にする。

### 2. このリポジトリを適用

**Linux / macOS**

```bash
git clone git@github.com:wurly200a/vscode-config.git
cd vscode-config
./install.sh            # 全用途
./install.sh viewer     # 用途を指定する場合
```

`~/.local/bin` が PATH に入っていなければ追加する。

**Windows**（開発者モードを有効にするか、管理者 PowerShell で）

```powershell
git clone git@github.com:wurly200a/vscode-config.git
cd vscode-config
.\install.ps1           # 全用途
.\install.ps1 viewer    # 用途を指定する場合
```

ランチャのディレクトリはユーザー PATH に自動で追加される（新しいシェルから有効）。

既存の設定ファイルが実ファイルとしてあれば `*.bak` に退避してからリンクする。何度実行してもよい。

## 使い方

### viewer（Markdown 閲覧）

```bash
code-viewer plan.md
```

`.md` はソースを出さず、Markdown Preview Enhanced のプレビュー（Mermaid・数式・画像込み）だけで開く。
ファイルが外部（AI など）で更新されるとプレビューも追従する。

- ソースを見たいとき … コマンドパレット（`Ctrl+Shift+P`）→「View: Reopen Editor With...」→「Text Editor」
- プレビュー内のリンクから開いた `.md` もプレビューで開く（`previewMode: Previews Only`）。

#### 画像とフォルダ

Markdown Preview Enhanced のプレビューが読めるのは、**ワークスペースのフォルダ**と**その md のディレクトリ**の中だけ。
ファイル単体で開くと、`../images/a.png` のような親ディレクトリの画像や、`/docs/a.png` のようなルート起点の画像は表示されない。

- `code-viewer <file>` は、ファイルの Git リポジトリのルート（Git 管理外ならファイルのディレクトリ）を
  フォルダとして一緒に開く（`profiles/viewer/profile.conf` の `OPEN_FILE_ROOT=1`）。
  左にエクスプローラが出たら `Ctrl+B` で閉じる（状態は覚えられる）。
- GUI から開くときは「File → Open File...」ではなく、**「File → Open Folder...」でリポジトリを開いてから**
  エクスプローラ（`Ctrl+Shift+E`）や `Ctrl+P` で md を開く。空のウィンドウで md だけを開くと画像が欠ける。

#### 初回のみ: 自分のフォルダを「信頼済み」に登録する（マシンごと）

Markdown Preview Enhanced は VS Code の制限モード（Restricted Mode）では動かない。
信頼していないフォルダのファイルは制限モードで開かれ、**プレビューが表示されない**
（viewer では案内バナーを消しているので、見た目では分からない）。

自分のリポジトリを置いている親フォルダを一度だけ登録しておく。配下のフォルダもすべて信頼済みになる。

1. `code-viewer` を起動する（ファイルは開かなくてよい）
2. コマンドパレット（`Ctrl+Shift+P`）→「Workspaces: Manage Workspace Trust」
3. 「Trusted Folders & Workspaces」の「Add Folder」で `~/projects` などを追加する
   - Ubuntu（GTK）のダイアログでは、一覧でフォルダを選んで「Open」を押すと中に移動してしまうことがある。
     **追加したいフォルダの中に入り、何も選択せずに「Open」**を押すか、`Ctrl+L` でパス（`~/projects/`）を入力して「Open」を押す

- 登録内容は設定ファイルではなく VS Code の内部状態（`<BASE>/viewer/data/` 以下）に保存されるため、Git では管理できない。
  マシンごとに 1 回行う。`uninstall.sh --purge` で消える。
- 用途ごとにデータディレクトリが分かれているので、viewer で登録しても他の用途や普通の `code` には影響しない。
- 出どころの分からない md（ダウンロードしたものなど）は、登録したフォルダの外に置けば制限モードのまま開ける（プレビューは出ないので、ソースで見る）。

## アンインストール

```bash
./uninstall.sh                  # インストール済みの全用途
./uninstall.sh viewer           # 指定した用途だけ
./uninstall.sh --purge viewer   # データディレクトリ（拡張・ウィンドウ状態など）ごと削除
```

Windows は `.\uninstall.ps1` / `.\uninstall.ps1 viewer` / `.\uninstall.ps1 -Purge viewer`。

- 既定では、設定のシンボリックリンクとランチャだけを外し、データディレクトリは残す（再インストールすると元の状態に戻る）。
- install で `*.bak` に退避した設定ファイルがあれば元に戻す。
- ランチャが 1 つも残らなければ `code-profile`（Windows はランチャのディレクトリとユーザー PATH の登録）も外す。
- このリポジトリ（`profiles/` 以下）には触らない。

## 用途を追加する

```bash
cp -r profiles/viewer profiles/<name>
# settings.json / extensions.txt を用途に合わせて編集
./install.sh <name>
```

用途間で設定の継承はない。共通にしたい項目（更新通知オフなど）は各 `settings.json` に書く。

## 運用メモ

- **Settings Sync は有効にしない。** Git 管理と二重になり競合する。
- GUI で設定を変えると、リンク経由でこのリポジトリのファイルが書き換わる。`git diff` で確認して commit する。
- 拡張を追加したら一覧を更新して commit:

  ```bash
  code-viewer --list-extensions > profiles/viewer/extensions.txt
  ```

- OS ごとの条件分岐は書けない。`terminal.integrated.profiles.linux` / `.windows` のように、キー名で OS を分けている設定は同居できる。
- 本体と拡張の更新は自動にしていないので、気が向いたときに apt / winget と拡張ビューから更新する。
  Markdown Preview Enhanced には Markdown の内容から突ける脆弱性が報告されたことがあるので、拡張は定期的に更新する。

## 未対応

- WSL 内のファイルを Windows 側の `code-<name>` で開く連携（Remote - WSL と専用データディレクトリの組み合わせ）は未整備。
- `profile.conf`（`OPEN_FILE_ROOT` など）は Linux / macOS のランチャだけが読む。Windows の `code-<name>.cmd` は引数をそのまま渡す。
