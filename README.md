# vscode-config

VS Code の設定を Git で管理し、どのマシンでも同じ環境にするためのリポジトリ。

メインエディタは Emacs のまま、VS Code は主に **Markdown の閲覧（Mermaid・数式・画像込み）** に使う。
そのため設定の方針は「静かにする」こと。更新通知・Tips・Welcome・AI 系 UI などは出さない。

## 構成

| ファイル | 内容 |
| --- | --- |
| `settings.json` | 設定本体（コメント付き JSONC） |
| `keybindings.json` | キーバインド |
| `extensions.txt` | インストールする拡張の一覧 |
| `install.sh` | Linux / macOS 用セットアップ |
| `install.ps1` | Windows 用セットアップ |

`settings.json` と `keybindings.json` は VS Code のユーザー設定ディレクトリへシンボリックリンクされる。
既存の実ファイルがあれば `*.bak` に退避してからリンクする。

| OS | リンク先 |
| --- | --- |
| Linux | `~/.config/Code/User/` |
| macOS | `~/Library/Application Support/Code/User/` |
| Windows | `%APPDATA%\Code\User\` |

## セットアップ

### 1. VS Code 本体

**Windows**

```powershell
winget install Microsoft.VisualStudioCode
```

**Ubuntu**

公式サイトから `.deb` をダウンロードして:

```bash
sudo apt install ./code_*.deb
```

Microsoft の apt リポジトリが追加され、以後は `apt upgrade` で更新される。

### 2. このリポジトリを適用

**Linux / macOS**

```bash
git clone git@github.com:wurly200a/vscode-config.git
cd vscode-config
./install.sh
```

**Windows**（開発者モードを有効にするか、管理者 PowerShell で）

```powershell
git clone git@github.com:wurly200a/vscode-config.git
cd vscode-config
.\install.ps1
```

Windows では `ms-vscode-remote.remote-wsl` も追加でインストールされ、WSL のシェルから `code foo.md` で開ける。

## 使い方（Markdown 閲覧）

```bash
code plan.md
```

- `Ctrl+K V` … 標準プレビューを横に表示
- 右クリック →「Markdown Preview Enhanced: Open Preview to the Side」… Mermaid・数式込みのプレビュー

ファイルが外部（AI など）で更新されるとプレビューも追従する。

## 運用メモ

- **組み込みの Settings Sync は有効にしない。** Git 管理と二重になり競合する。
- GUI で設定を変えると、リンク経由でこのリポジトリのファイルが書き換わる。`git diff` で確認して commit する。
- 拡張を追加したら一覧を更新して commit:

  ```bash
  code --list-extensions > extensions.txt
  ```

  （Windows 専用の `ms-vscode-remote.remote-wsl` は `install.ps1` 側で入れるので、一覧からは外しておく）
- OS ごとの条件分岐は書けない。`terminal.integrated.profiles.linux` / `.windows` のように、キー名で OS を分けている設定は同居できる。
- 本体と拡張の更新は自動にしていないので、気が向いたときに apt / winget と拡張ビューから更新する。
