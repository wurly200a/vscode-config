#!/bin/sh
# Linux / macOS 用: install.sh で入れたものを外す
#
#   ./uninstall.sh                  # インストール済みの全用途
#   ./uninstall.sh viewer           # 指定した用途だけ
#   ./uninstall.sh --purge [name]   # データディレクトリ（拡張・ウィンドウ状態など）ごと削除
#
# 既定ではシンボリックリンクとランチャだけを外し、データディレクトリは残す。
# install.sh が退避した *.bak があれば元に戻す。
# このリポジトリ自体（profiles/ 以下）には触らない。
set -e

PURGE=0
if [ "$1" = "--purge" ]; then
  PURGE=1
  shift
fi

case "$(uname)" in
  Darwin) BASE="$HOME/Library/Application Support/vscode-profiles" ;;
  *)      BASE="${XDG_DATA_HOME:-$HOME/.local/share}/vscode-profiles" ;;
esac
BIN="$HOME/.local/bin"

if [ $# -eq 0 ]; then
  [ -d "$BASE" ] || { echo "nothing installed ($BASE がない)"; exit 0; }
  set -- $(ls "$BASE")
fi

for name in "$@"; do
  echo "== $name"
  USER_DIR="$BASE/$name/data/User"

  if [ -L "$BIN/code-$name" ]; then
    rm "$BIN/code-$name"
    echo "remove: $BIN/code-$name"
  fi

  if [ "$PURGE" -eq 1 ]; then
    if [ -d "$BASE/$name" ]; then
      rm -rf "$BASE/$name"
      echo "purge:  $BASE/$name"
    fi
    continue
  fi

  for f in settings.json keybindings.json; do
    if [ -L "$USER_DIR/$f" ]; then
      rm "$USER_DIR/$f"
      echo "unlink: $USER_DIR/$f"
    fi
    if [ -e "$USER_DIR/$f.bak" ] && [ ! -e "$USER_DIR/$f" ]; then
      mv "$USER_DIR/$f.bak" "$USER_DIR/$f"
      echo "restore: $USER_DIR/$f"
    fi
  done
done

# 残っている用途ランチャがなければ code-profile も外す
if [ -L "$BIN/code-profile" ]; then
  if ! ls "$BIN"/code-* 2>/dev/null | grep -v '/code-profile$' | while read -r l; do
       [ -L "$l" ] && [ "$(readlink "$l")" = "$(readlink "$BIN/code-profile")" ] && echo x
     done | grep -q x; then
    rm "$BIN/code-profile"
    echo "remove: $BIN/code-profile"
  fi
fi

# 空になった BASE は消す
rmdir "$BASE" 2>/dev/null || true
