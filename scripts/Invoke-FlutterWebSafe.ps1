# Dot-source: . "$PSScriptRoot\scripts\Invoke-FlutterWebSafe.ps1"
# Avoids "Failed to bind... port 65106" when a Flutter web dev server is already running.

function Test-WebPortListening {
    param([int]$Port)
    $conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
        Select-Object -First 1
    return $null -ne $conn
}

function Find-FreeWebPort {
    param(
        [int]$Preferred,
        [int[]]$Fallbacks = @(65107, 65108, 65110, 65111)
    )
    if (-not (Test-WebPortListening $Preferred)) { return $Preferred }
    foreach ($p in $Fallbacks) {
        if (-not (Test-WebPortListening $p)) { return $p }
    }
    return $null
}

function Stop-WebPortListener {
    param([int]$Port)
    $conns = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    foreach ($c in $conns) {
        $pid = $c.OwningProcess
        if ($pid -and $pid -gt 0) {
            Write-Host "  Freeing port $Port (pid $pid)..." -ForegroundColor Yellow
            Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
        }
    }
    Start-Sleep -Seconds 2
}

function Invoke-FlutterWebSafe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [Parameter(Mandatory = $true)]
        [int]$Port,
        [Parameter(Mandatory = $true)]
        [string[]]$FlutterArgs,
        [switch]$PickAlternateIfBusy,
        [switch]$OpenBrowser,
        [switch]$ForceRestart
    )

    if ($ForceRestart -and (Test-WebPortListening $Port)) {
        Write-Host "$Label - restarting (port $Port was in use; plain flutter run may lack dart-defines)." -ForegroundColor Yellow
        & "$PSScriptRoot\Stop-FlutterWorkers.ps1"
        Stop-WebPortListener -Port $Port
    }

    $webPort = $Port
    if (Test-WebPortListening $Port) {
        if ($PickAlternateIfBusy) {
            $alt = Find-FreeWebPort -Preferred $Port
            if ($null -ne $alt -and $alt -ne $Port) {
                $webPort = $alt
                Write-Host "$Label port ${Port} busy - using ${webPort} instead." -ForegroundColor Yellow
            } else {
                $url = "http://127.0.0.1:$Port/"
                Write-Host ""
                Write-Host "$Label already running (port $Port in use)." -ForegroundColor Green
                Write-Host "  Open: $url" -ForegroundColor Cyan
                Write-Host "  Restart: press q in the Flutter terminal, then run this script again." -ForegroundColor DarkGray
                if ($OpenBrowser) {
                    try { Start-Process "msedge" $url } catch { try { Start-Process $url } catch {} }
                }
                exit 0
            }
        } else {
            $url = "http://127.0.0.1:$Port/"
            Write-Host ""
            Write-Host "$Label already running (port $Port in use)." -ForegroundColor Green
            Write-Host "  Open: $url" -ForegroundColor Cyan
            Write-Host "  Restart: press q in the Flutter terminal, then run this script again." -ForegroundColor DarkGray
            if ($OpenBrowser) {
                try { Start-Process "msedge" $url } catch { try { Start-Process $url } catch {} }
            }
            exit 0
        }
    }

    $allArgs = @('run', '-d', 'edge', "--web-port=$webPort") + $FlutterArgs
    Write-Host "Open: http://127.0.0.1:${webPort}" -ForegroundColor Cyan
    & flutter @allArgs
    exit $LASTEXITCODE
}
