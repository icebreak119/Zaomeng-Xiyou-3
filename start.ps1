param(
    [switch]$Auto
)

# 造梦西游3 离线版一键启动
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$run  = Join-Path $root "run"
$player = "D:\4399\tools\flashplayer_sa.exe"

if (-not (Test-Path $player)) {
    Write-Host "找不到 Flash Player: $player" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path (Join-Path $run "gamefile.swf"))) {
    Write-Host "run\gamefile.swf 不存在，请先构建离线版" -ForegroundColor Red
    exit 1
}

# 关掉旧的本地服务
Get-Process -Name python -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -and $_.Path -like "*python*" } |
    ForEach-Object {
        try {
            $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId=$($_.Id)").CommandLine
            if ($cmd -like "*server.py*") { Stop-Process -Id $_.Id -Force }
        } catch { }
    }

Start-Process -FilePath "python" -ArgumentList (Join-Path $run "server.py") `
    -WorkingDirectory $run -WindowStyle Hidden
Start-Sleep -Milliseconds 800

$url = "http://127.0.0.1:8765/launcher.swf"
if ($Auto) { $url += "?auto=1" }
Start-Process -FilePath $player -ArgumentList $url
