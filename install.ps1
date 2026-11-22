# Windows 用: 設定ファイルをシンボリックリンクし、拡張をインストールする
# シンボリックリンク作成には「開発者モード」有効化、または管理者 PowerShell が必要
$ErrorActionPreference = "Stop"

$src = $PSScriptRoot
$dst = "$env:APPDATA\Code\User"
New-Item -ItemType Directory -Force $dst | Out-Null

foreach ($f in "settings.json", "keybindings.json") {
  $target = Join-Path $dst $f
  $item = Get-Item $target -ErrorAction SilentlyContinue
  # 既存の実ファイルがあれば退避してからリンク
  if ($item -and -not $item.LinkType) {
    Move-Item -Force $target "$target.bak"
    Write-Host "backup: $target.bak"
  }
  New-Item -ItemType SymbolicLink -Force -Path $target -Target (Join-Path $src $f) | Out-Null
  Write-Host "link:   $target -> $(Join-Path $src $f)"
}

$exts = Get-Content (Join-Path $src "extensions.txt") | Where-Object { $_ -and -not $_.StartsWith("#") }
# Windows のみ: WSL 内のファイルを開くための拡張
$exts += "ms-vscode-remote.remote-wsl"
foreach ($e in $exts) { code --install-extension $e }
