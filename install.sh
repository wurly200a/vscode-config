#!/bin/sh
# Linux / macOS 用セットアップ
#
#   ./install.sh            # profiles/ 以下の全用途をインストール
#   ./install.sh viewer     # 指定した用途だけ
#
# 用途ごとに:
#   - データディレクトリを作り、settings.json / keybindings.json をシンボリックリンク
#   - extensions.txt の拡張をその用途専用の拡張ディレクトリにインストール
#   - ~/.local/bin/code-<name> ランチャを作成
set -e

SRC="$(cd "$(dirname "$0")" && pwd)"
case "$(uname)" in
  Darwin) BASE="$HOME/Library/Application Support/vscode-profiles" ;;
  *)      BASE="${XDG_DATA_HOME:-$HOME/.local/share}/vscode-profiles" ;;
esac
BIN="$HOME/.local/bin"

if [ $# -eq 0 ]; then
  set -- $(ls "$SRC/profiles")
fi

mkdir -p "$BIN"
chmod +x "$SRC/bin/code-profile"
ln -sfn "$SRC/bin/code-profile" "$BIN/code-profile"

for name in "$@"; do
  P="$SRC/profiles/$name"
  [ -d "$P" ] || { echo "no such profile: $name" >&2; exit 1; }
  echo "== $name"

  USER_DIR="$BASE/$name/data/User"
  EXT_DIR="$BASE/$name/extensions"
  mkdir -p "$USER_DIR" "$EXT_DIR"

  for f in settings.json keybindings.json; do
    [ -f "$P/$f" ] || continue
    if [ -e "$USER_DIR/$f" ] && [ ! -L "$USER_DIR/$f" ]; then
      mv "$USER_DIR/$f" "$USER_DIR/$f.bak"
      echo "backup: $USER_DIR/$f.bak"
    fi
    ln -sfn "$P/$f" "$USER_DIR/$f"
    echo "link:   $USER_DIR/$f"
  done

  if [ -f "$P/extensions.txt" ]; then
    grep -Ev '^[[:space:]]*(#|$)' "$P/extensions.txt" | while read -r ext; do
      code --user-data-dir "$BASE/$name/data" --extensions-dir "$EXT_DIR" --install-extension "$ext"
    done
  fi

  ln -sfn "$SRC/bin/code-profile" "$BIN/code-$name"
  echo "launcher: $BIN/code-$name"
done

case ":$PATH:" in
  *":$BIN:"*) ;;
  *) echo "note: $BIN is not in PATH" ;;
esac
