#!/bin/sh
# Linux / macOS 用: 設定ファイルをシンボリックリンクし、拡張をインストールする
set -e

SRC="$(cd "$(dirname "$0")" && pwd)"
case "$(uname)" in
  Darwin) DST="$HOME/Library/Application Support/Code/User" ;;
  *)      DST="$HOME/.config/Code/User" ;;
esac

mkdir -p "$DST"
for f in settings.json keybindings.json; do
  # 既存の実ファイルがあれば退避してからリンク
  if [ -e "$DST/$f" ] && [ ! -L "$DST/$f" ]; then
    mv "$DST/$f" "$DST/$f.bak"
    echo "backup: $DST/$f.bak"
  fi
  ln -sfn "$SRC/$f" "$DST/$f"
  echo "link:   $DST/$f -> $SRC/$f"
done

grep -Ev '^[[:space:]]*(#|$)' "$SRC/extensions.txt" | while read -r ext; do
  code --install-extension "$ext"
done
