param(
    [string]$Scale = "1.5",   # 1 / 1.5 / 2
    [switch]$Fps,             # 显示帧率
    [switch]$Sharp,           # 关闭位图平滑（像素更锐利）
    [switch]$Pillar,          # 全屏时保持比例（两侧留黑边），默认拉伸铺满
    [switch]$Auto             # 自动测试流程
)

# 造梦西游3 离线版一键启动
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$run  = Join-Path $root "run"

$player = Join-Path $root "tools\flashplayer_sa.exe"
if (-not (Test-Path $player)) { $player = "D:\4399\tools\flashplayer_sa.exe" }
$winsize = Join-Path $root "bin\winsize.exe"

if (-not (Test-Path $player)) {
    Write-Host "找不到 Flash Player，请放到 tools\flashplayer_sa.exe 或修改 start.ps1" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path (Join-Path $run "gamefile.swf"))) {
    Write-Host "run\gamefile.swf 不存在" -ForegroundColor Red
    exit 1
}

# 让 Flash Player 按物理像素渲染（避免 Windows 150% 缩放导致的模糊）
if (Test-Path $winsize) {
    $key = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
    if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
    Set-ItemProperty -Path $key -Name $player -Value "~ HIGHDPIAWARE"
}

# 关掉旧的本地服务
Get-Process -Name python -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId=$($_.Id)").CommandLine
        if ($cmd -like "*server.py*") { Stop-Process -Id $_.Id -Force }
    } catch { }
}

Start-Process -FilePath "python" -ArgumentList (Join-Path $run "server.py") `
    -WorkingDirectory $run -WindowStyle Hidden
Start-Sleep -Milliseconds 800

$url = "http://127.0.0.1:8765/launcher.swf?q=best"
if ($Fps)   { $url += "&fps=1" }
if ($Sharp) { $url += "&smooth=0" }
if ($Pillar) { $url += "&fit=pillar" }
if ($Auto)  { $url += "&auto=1" }

$p = Start-Process -FilePath $player -ArgumentList $url -PassThru

if ((Test-Path $winsize) -and ([double]$Scale -ne 1.0)) {
    Start-Sleep -Seconds 2
    $w = [int](940 * [double]$Scale)
    $h = [int](590 * [double]$Scale)
    & $winsize $p.Id $w $h | Out-Null
}
