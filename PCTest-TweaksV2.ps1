# -----------------------------
# Netzwerk-, FPS-, RAM- und Software-Optimierungs-Skript
# -----------------------------

$asciiLogo = @"
 _______  _______ _________ _______  _______ _________
(  ____ )(  ____ \(  ____ \(  ____ \(  ____ \__   __/
| (    )|| (    \/   ) (   | (    \/| (    \/   ) (   
| (____)|| |         | |   | (__    | (_____    | |   
|  _____)| |         | |   |  __)   (_____  )   | |   
| (      | |         | |   | (            ) |   | |   
| )      | (____/\   | |   | (____/\/\____) |   | |   
|/       (_______/   )_(   (_______/\_______)   )_(   
                                                      
"@

# Funktion zur Anzeige der PC-Hardware
function Show-HardwareInfo {
    Clear-Host
    Write-Host "`n$asciiLogo" -ForegroundColor Magenta
    Write-Host "`n=================================" -ForegroundColor Yellow
    Write-Host "      💻 System-Informationen      " -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Yellow
    
    $ramModules = Get-CimInstance Win32_PhysicalMemory | Select-Object Manufacturer, Speed, Capacity
    $ramTotal = ($ramModules | Measure-Object -Property Capacity -Sum).Sum / 1GB
    $ramDetails = $ramModules | ForEach-Object { "$(($_.Capacity / 1GB) -as [int]) GB - $($_.Manufacturer) - $($_.Speed) MTs" }
	
    $cpu = Get-CimInstance Win32_Processor | Select-Object Name
    $gpu = Get-CimInstance Win32_VideoController | Select-Object Name

    Write-Host "🖥  CPU: $($cpu.Name)" -ForegroundColor Green
    Write-Host "🎮 GPU: $($gpu.Name)" -ForegroundColor Green
    Write-Host "💾 RAM: $ramTotal GB (Details unten)" -ForegroundColor Green
    $ramDetails | ForEach-Object { Write-Host "   - $_" -ForegroundColor Green }
    Write-Host "=================================" -ForegroundColor Yellow
    Start-Sleep 3
    Clear-Host
}

function Get-FPSSettings {
    return @{
        HwSchMode       = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name 'HwSchMode' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty HwSchMode
        LowLatencyMode  = Get-ItemProperty -Path 'HKCU:\Software\NVIDIA Corporation\Global\Settings' -Name 'LowLatencyMode' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty LowLatencyMode
        SyncToVBlank    = Get-ItemProperty -Path 'HKCU:\Software\NVIDIA Corporation\Global\Settings' -Name 'SyncToVBlank' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty SyncToVBlank
        TextureQuality  = Get-ItemProperty -Path 'HKCU:\Software\NVIDIA Corporation\Global\Settings' -Name 'TextureQuality' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty TextureQuality
    }
}

# Funktion zur Anwendung von FPS-Optimierungen
function Apply-FPSOptimizations {
    Clear-Host
    Write-Host "`n$asciiLogo" -ForegroundColor Magenta
    Write-Host "`n🎮 FPS-Optimierung wird angewendet..." -ForegroundColor Cyan

    # Energieoptionen auf Höchstleistung setzen
    powercfg -setactive SCHEME_MIN
    #Write-Host "✅ Energieoptionen auf Höchstleistung gesetzt." -ForegroundColor Green

    # Windows-Animationen deaktivieren
    reg add "HKCU\Control Panel\Desktop" /v "FontSmoothing" /t REG_SZ /d 2 /f
    reg add "HKCU\Software\Microsoft\Windows\DWM" /v "EnableAeroPeek" /t REG_DWORD /d 0 /f
   # Write-Host "✅ Windows-Animationen und Aero Peek deaktiviert." -ForegroundColor Green
	
	
    $beforeFPS = Get-FPSSettings
    #Write-Host "[Vorher] HwSchMode: $($beforeFPS.HwSchMode), LowLatencyMode: $($beforeFPS.LowLatencyMode), SyncToVBlank: $($beforeFPS.SyncToVBlank), TextureQuality: $($beforeFPS.TextureQuality)" -ForegroundColor Red

    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -Type DWord -Force
    Set-ItemProperty -Path "HKCU:\Software\NVIDIA Corporation\Global\Settings" -Name "LowLatencyMode" -Value 2 -Type DWord -Force
    Set-ItemProperty -Path "HKCU:\Software\NVIDIA Corporation\Global\Settings" -Name "SyncToVBlank" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path "HKCU:\Software\NVIDIA Corporation\Global\Settings" -Name "TextureQuality" -Value 0 -Type DWord -Force

   # $afterFPS = Get-FPSSettings
    #Write-Host "[Nachher] HwSchMode: $($afterFPS.HwSchMode), LowLatencyMode: $($afterFPS.LowLatencyMode), SyncToVBlank: $($afterFPS.SyncToVBlank), TextureQuality: $($afterFPS.TextureQuality)" -ForegroundColor Green

    Write-Host "🚀 FPS-Optimierung abgeschlossen!" -ForegroundColor Yellow
    Start-Sleep 3
    Clear-Host
}

# Funktion zur Messung der Netzwerkgeschwindigkeit
function Get-NetworkSpeed {
    $speedtestOutput = speedtest --progress=no --format=json | ConvertFrom-Json
    return @{
        Ping     = $speedtestOutput.ping.latency
        Download = [math]::Round($speedtestOutput.download.bandwidth / 125000, 2)
        Upload   = [math]::Round($speedtestOutput.upload.bandwidth / 125000, 2)
    }
}

# Funktion zur Netzwerkoptimierung
function Optimize-Network {
    Clear-Host
    Write-Host "`n$asciiLogo" -ForegroundColor Magenta
    Write-Host "`n🌐 Wende Netzwerk-Optimierungen an..." -ForegroundColor Cyan

    # Geschwindigkeit vor der Optimierung messen
	Write-Host "Speedtest wird durchgeführt..." -ForegroundColor Magenta
	
    $beforeSpeed = Get-NetworkSpeed
    Write-Host "[Vorher] Ping: $($beforeSpeed.Ping) ms, Download: $($beforeSpeed.Download) Mbps, Upload: $($beforeSpeed.Upload) Mbps" -ForegroundColor Red

# Finde den aktiven Netzwerkadapter mit der höchsten Geschwindigkeit
$interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Sort-Object -Property LinkSpeed -Descending | Select-Object -First 1

if ($interface) {
    $interfaceIndex = $interface.InterfaceIndex
    $interfaceGUID = (Get-NetAdapter -InterfaceIndex $interfaceIndex).InterfaceGuid

    # Setze TcpAckFrequency für den gefundenen Adapter
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$interfaceGUID"
    
    if (Test-Path $regPath) {
        Set-ItemProperty -Path $regPath -Name "TcpAckFrequency" -Value 1 -Type DWord -Force
        Write-Output "✅ Nagle-Algorithmus (TcpAckFrequency) für Interface $interfaceGUID deaktiviert." -ForegroundColor Green
    } else {
        Write-Output "⚠ Registrierungspfad nicht gefunden: $regPath"
    }
} else {
    Write-Output "⚠ Kein aktiver Netzwerkadapter gefunden!"
}

    # TCP-Autotuning-Level anpassen
    netsh int tcp set global autotuninglevel=normal > $null 2>&1
    Write-Host "✅ TCP-Autotuning-Level gesetzt." -ForegroundColor Green

    # DNS-Cache leeren
    Clear-DnsClientCache
    Write-Host "✅ DNS-Cache geleert." -ForegroundColor Green

    # Optimierungen setzen
    netsh interface ipv4 set subinterface "Ethernet" mtu=1500 store=persistent > $null 2>&1
    netsh int ip reset > $null 2>&1
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" -Name "NonBestEffortLimit" -Value 0 -PropertyType DWord -Force | Out-Null
    Write-Host "✅ Netzwerkoptimierungen angewendet." -ForegroundColor Green

    # Geschwindigkeit nach der Optimierung messen
	Write-Host "Speedtest wird erneut durchgeführt..." -ForegroundColor Magenta
    $afterSpeed = Get-NetworkSpeed
    Write-Host "[Nachher] Ping: $($afterSpeed.Ping) ms, Download: $($afterSpeed.Download) Mbps, Upload: $($afterSpeed.Upload) Mbps" -ForegroundColor Green
    Start-Sleep 3
    Clear-Host
}

# Funktion zur RAM-Optimierung
function Optimize-RAM {
    Clear-Host
    Write-Host "`n$asciiLogo" -ForegroundColor Magenta
    Write-Host "`n🧠 Starte RAM-Optimierung..." -ForegroundColor Cyan

    $beforeRAM = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1024
    Write-Host "[Vorher] Freier RAM: $beforeRAM MB" -ForegroundColor Red

    # RAM gezielt freigeben
    if (Test-Path "$env:SystemRoot\System32\EmptyStandbyList.exe") {
        Start-Process -NoNewWindow -Wait -FilePath "$env:SystemRoot\System32\EmptyStandbyList.exe" -ArgumentList "standbylist"
        Write-Host "`u2705 Standby-List Speicher erfolgreich geleert!" -ForegroundColor Green
    } else {
        Write-Host "`u26A0 'EmptyStandbyList.exe' wurde nicht gefunden!" -ForegroundColor Red
    }

    # Hintergrundprozesse beenden
    $processesToKill = @("OneDrive", "Skype", "Discord", "Teams", "Steam", "EpicGamesLauncher", "Battle.net", "AdobeUpdateService", "chrome", "firefox", "msedge", "opera", "brave")
    foreach ($proc in $processesToKill) {
        if (Get-Process -Name $proc -ErrorAction SilentlyContinue) {
            Stop-Process -Name $proc -Force
            Write-Host "`u2705 $proc wurde geschlossen!" -ForegroundColor Green
        }
    }

    # Speicherverwaltung optimieren
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -Value 1 -Type DWord -Force
    Write-Host "`u2705 Speicherverwaltung optimiert!" -ForegroundColor Green

    $afterRAM = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1024
    Write-Host "[Nachher] Freier RAM: $afterRAM MB" -ForegroundColor Green

    Write-Host "🚀 RAM-Optimierung abgeschlossen!" -ForegroundColor Yellow
    Start-Sleep 5
    Clear-Host
}

# Menü anzeigen
function Show-Menu {
    Clear-Host
    Write-Host "`n$asciiLogo" -ForegroundColor Magenta
    Show-HardwareInfo  # Automatische Anzeige der Hardware-Informationen beim ersten Start
    
    while ($true) {
        Write-Host "📌 ==== Optimierungs-Skript ==== " -ForegroundColor Cyan
        Write-Host "1️⃣ FPS-Optimierungen anwenden"
        Write-Host "2️⃣ Netzwerk-Optimierung"
        Write-Host "3️⃣ RAM-Optimierung"
        Write-Host "4️⃣ Software aktualisieren"
        Write-Host "5️⃣ Beenden"

        $choice = Read-Host "Wähle eine Option (1-5)"
        Clear-Host
        
        switch ($choice) {
            "1" { Apply-FPSOptimizations }
            "2" { Optimize-Network }
            "3" { Optimize-RAM }
            "4" { Upgrade-Software }
            "5" { exit }
            default { Write-Host "`u274C Ungültige Eingabe!" -ForegroundColor Red }
        }
    }
}

Show-Menu
