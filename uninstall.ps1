# Windows 用: install.ps1 で入れたものを外す
#
#   .\uninstall.ps1                    # インストール済みの全用途
#   .\uninstall.ps1 viewer             # 指定した用途だけ
#   .\uninstall.ps1 -Purge [viewer]    # データディレクトリ（拡張・ウィンドウ状態など）ごと削除
#
# 既定ではシンボリックリンクとランチャだけを外し、データディレクトリは残す。
# install.ps1 が退避した *.bak があれば元に戻す。
# このリポジトリ自体（profiles\ 以下）には触らない。
param([string[]]$Names, [switch]$Purge)
$ErrorActionPreference = "Stop"

$base = Join-Path $env:LOCALAPPDATA "vscode-profiles"
$bin  = Join-Path $base "bin"

if (-not (Test-Path $base)) { Write-Host "nothing installed ($base がない)"; exit 0 }
if (-not $Names) { $Names = Get-ChildItem $base -Directory | Where-Object Name -ne "bin" | ForEach-Object Name }

foreach ($name in $Names) {
  Write-Host "== $name"
  $userDir = Join-Path $base "$name\data\User"

  $launcher = Join-Path $bin "code-$name.cmd"
  if (Test-Path $launcher) {
    Remove-Item $launcher
    Write-Host "remove: $launcher"
  }

  if ($Purge) {
    $dir = Join-Path $base $name
    if (Test-Path $dir) {
      Remove-Item -Recurse -Force $dir
      Write-Host "purge:  $dir"
    }
    continue
  }

  foreach ($f in "settings.json", "keybindings.json") {
    $target = Join-Path $userDir $f
    $item = Get-Item $target -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType) {
      $item.Delete()
      Write-Host "unlink: $target"
    }
    if ((Test-Path "$target.bak") -and -not (Test-Path $target)) {
      Move-Item "$target.bak" $target
      Write-Host "restore: $target"
    }
  }
}

# ランチャが残っていなければ bin を消し、ユーザー PATH からも外す
if ((Test-Path $bin) -and -not (Get-ChildItem $bin -Filter "code-*.cmd")) {
  Remove-Item -Recurse -Force $bin
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  $newPath = (($userPath -split ";") | Where-Object { $_ -and $_ -ne $bin }) -join ";"
  if ($newPath -ne $userPath) {
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "removed from user PATH: $bin"
  }
}

# 空になった base は消す
if ((Test-Path $base) -and -not (Get-ChildItem $base)) { Remove-Item $base }
