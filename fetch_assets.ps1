param(
    [string]$ListFile = "mirror_names.txt",
    [string]$OutDir = "D:\4399\zmxy3\run",
    [int]$Retry = 2
)

# 从 4399 CDN 批量抓取造梦西游3 资源 SWF
$ref = "https://www.4399.com/flash/zmhj.htm?g=3"
$base = "https://sda.4399.com/4399swf/upload_swf/ftp7/hanbao/20120107/6/"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$names = Get-Content $ListFile | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" } | Select-Object -Unique
$ok = 0; $skip = 0; $fail = @()
foreach ($n in $names) {
    $file = Join-Path $OutDir $n
    if ((Test-Path $file) -and (Get-Item $file).Length -gt 1000) { $skip++; continue }
    $done = $false
    for ($i = 0; $i -le $Retry -and -not $done; $i++) {
        $code = curl.exe -s --max-time 120 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120" `
            -e $ref -o $file -w "%{http_code}" "$base$n"
        if ($code -eq "200" -and (Test-Path $file) -and (Get-Item $file).Length -gt 1000) {
            $done = $true; $ok++
        } else {
            Remove-Item $file -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 300
        }
    }
    if (-not $done) { $fail += $n }
}

Write-Host ("downloaded={0} skipped={1} failed={2}" -f $ok, $skip, $fail.Count)
if ($fail.Count -gt 0) { $fail | Set-Content "$OutDir\_failed.txt"; Write-Host ("fail list -> $OutDir\_failed.txt") }
$total = (Get-ChildItem $OutDir -File | Measure-Object Length -Sum).Sum
Write-Host ("total size = {0:N1} MB" -f ($total / 1MB))
