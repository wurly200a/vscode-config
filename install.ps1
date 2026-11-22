# Windows 用セットアップ
#
#   .\install.ps1            # profiles\ 以下の全用途をインストール
#   .\install.ps1 viewer     # 指定した用途だけ
#
# 用途ごとに:
#   - データディレクトリを作り、settings.json / keybindings.json をシンボリックリンク
#   - extensions.txt の拡張をその用途専用の拡張ディレクトリにインストール
#   - %LOCALAPPDATA%\vscode-profiles\bin\code-<name>.cmd ランチャを作成（bin はユーザー PATH に追加）
#
# シンボリックリンク作成には「開発者モード」有効化、または管理者 PowerShell が必要
param([string[]]$Names)
$ErrorActionPreference = "Stop"

$src  = $PSScriptRoot
$base = Join-Path $env:LOCALAPPDATA "vscode-profiles"
$bin  = Join-Path $base "bin"

if (-not $Names) { $Names = Get-ChildItem (Join-Path $src "profiles") -Directory | ForEach-Object Name }
New-Item -ItemType Directory -Force $bin | Out-Null

foreach ($name in $Names) {
  $p = Join-Path $src "profiles\$name"
  if (-not (Test-Path $p)) { throw "no such profile: $name" }
  Write-Host "== $name"

  $dataDir = Join-Path $base "$name\data"
  $userDir = Join-Path $dataDir "User"
  $extDir  = Join-Path $base "$name\extensions"
  New-Item -ItemType Directory -Force $userDir, $extDir | Out-Null

  foreach ($f in "settings.json", "keybindings.json") {
    $from = Join-Path $p $f
    if (-not (Test-Path $from)) { continue }
    $target = Join-Path $userDir $f
    $item = Get-Item $target -ErrorAction SilentlyContinue
    if ($item -and -not $item.LinkType) {
      Move-Item -Force $target "$target.bak"
      Write-Host "backup: $target.bak"
    }
    New-Item -ItemType SymbolicLink -Force -Path $target -Target $from | Out-Null
    Write-Host "link:   $target"
  }

  $extFile = Join-Path $p "extensions.txt"
  if (Test-Path $extFile) {
    Get-Content $extFile | Where-Object { $_.Trim() -and -not $_.Trim().StartsWith("#") } | ForEach-Object {
      code --user-data-dir $dataDir --extensions-dir $extDir --install-extension $_.Trim()
    }
  }

  $launcher = Join-Path $bin "code-$name.cmd"
  Set-Content -Encoding ASCII $launcher "@code --user-data-dir `"$dataDir`" --extensions-dir `"$extDir`" %*"
  Write-Host "launcher: $launcher"
}

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (($userPath -split ";") -notcontains $bin) {
  [Environment]::SetEnvironmentVariable("Path", "$userPath;$bin", "User")
  Write-Host "added to user PATH: $bin (新しいシェルから有効)"
}
