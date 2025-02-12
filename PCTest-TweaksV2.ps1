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
    $ramDetails = $ramModules | ForEach-Object { "$(($_.Capacity / 1GB) -as [int]) GB - $($_.Manufacturer) - $($_.Speed) MHz" }
	
    $cpu = Get-CimInstance Win32_Processor | Select-Object Name
    $gpu = Get-CimInstance Win32_VideoController | Select-Object Name
    $ramTotal = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB
    Write-Host "🖥  CPU: $($cpu.Name)" -ForegroundColor Green
    Write-Host "🎮 GPU: $($gpu.Name)" -ForegroundColor Green
    Write-Host "💾 RAM: $ramTotal GB (Details unten)" -ForegroundColor Green
    $ramDetails | ForEach-Object { Write-Host "   - $_" -ForegroundColor Green }
    Write-Host "=================================" -ForegroundColor Yellow
    Start-Sleep 10
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
    Write-Host "✅ Energieoptionen auf Höchstleistung gesetzt." -ForegroundColor Green

    # Windows-Animationen deaktivieren
    reg add "HKCU\Control Panel\Desktop" /v "FontSmoothing" /t REG_SZ /d 2 /f
    reg add "HKCU\Software\Microsoft\Windows\DWM" /v "EnableAeroPeek" /t REG_DWORD /d 0 /f
    Write-Host "✅ Windows-Animationen und Aero Peek deaktiviert." -ForegroundColor Green
	
	
    $beforeFPS = Get-FPSSettings
    Write-Host "[Vorher] HwSchMode: $($beforeFPS.HwSchMode), LowLatencyMode: $($beforeFPS.LowLatencyMode), SyncToVBlank: $($beforeFPS.SyncToVBlank), TextureQuality: $($beforeFPS.TextureQuality)" -ForegroundColor Red

    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -Type DWord -Force
    Set-ItemProperty -Path "HKCU:\Software\NVIDIA Corporation\Global\Settings" -Name "LowLatencyMode" -Value 2 -Type DWord -Force
    Set-ItemProperty -Path "HKCU:\Software\NVIDIA Corporation\Global\Settings" -Name "SyncToVBlank" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path "HKCU:\Software\NVIDIA Corporation\Global\Settings" -Name "TextureQuality" -Value 0 -Type DWord -Force

    $afterFPS = Get-FPSSettings
    Write-Host "[Nachher] HwSchMode: $($afterFPS.HwSchMode), LowLatencyMode: $($afterFPS.LowLatencyMode), SyncToVBlank: $($afterFPS.SyncToVBlank), TextureQuality: $($afterFPS.TextureQuality)" -ForegroundColor Green

    Write-Host "🚀 FPS-Optimierung abgeschlossen!" -ForegroundColor Yellow
    Start-Sleep 3
    Clear-Host
}

# Funktion zur Netzwerkoptimierung
function Optimize-Network {
    Clear-Host
    Write-Host "`n$asciiLogo" -ForegroundColor Magenta
    Write-Host "`n🌐 Wende Netzwerk-Optimierungen an..." -ForegroundColor Cyan

    # Nagle-Algorithmus deaktivieren
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" -Name "TcpAckFrequency" -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" -Name "TCPNoDelay" -Value 1 -PropertyType DWord -Force | Out-Null
    Write-Host "✅ Nagle-Algorithmus deaktiviert." -ForegroundColor Green

    # TCP-Autotuning-Level anpassen
    netsh int tcp set global autotuninglevel=normal
    Write-Host "✅ TCP-Autotuning-Level gesetzt." -ForegroundColor Green

    # DNS-Cache leeren
    ipconfig /flushdns
    Write-Host "✅ DNS-Cache geleert." -ForegroundColor Green

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
        Write-Host "✅ Standby-List Speicher erfolgreich geleert!" -ForegroundColor Green
    } else {
        Write-Host "⚠️ 'EmptyStandbyList.exe' wurde nicht gefunden!" -ForegroundColor Red
    }

    # Hintergrundprozesse beenden
    $processesToKill = @("OneDrive", "Skype", "Discord", "Teams", "Steam", "EpicGamesLauncher", "Battle.net", "AdobeUpdateService")
    foreach ($proc in $processesToKill) {
        if (Get-Process -Name $proc -ErrorAction SilentlyContinue) {
            Stop-Process -Name $proc -Force
            Write-Host "✅ $proc wurde geschlossen!" -ForegroundColor Green
        }
    }

    # Speicherverwaltung optimieren
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -Value 1 -Type DWord -Force
    Write-Host "✅ Speicherverwaltung optimiert!" -ForegroundColor Green

    $afterRAM = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1024
    Write-Host "[Nachher] Freier RAM: $afterRAM MB" -ForegroundColor Green

    Write-Host "🚀 RAM-Optimierung abgeschlossen!" -ForegroundColor Yellow
    Start-Sleep 5
    Clear-Host
}

# Funktion zum Aktualisieren von Software mit winget
function Upgrade-Software {
    Clear-Host
    Write-Host "`n[+] Aktualisiere installierte Software..." -ForegroundColor Cyan
    try {
        Write-Host "[+] Starte Upgrade für alle installierten Pakete..." -ForegroundColor Yellow
        winget upgrade --all 
    } catch {
        Write-Host "[✖] Fehler beim Aktualisieren von Software." -ForegroundColor Red
    }
    Write-Host "[✔] Software-Upgrade abgeschlossen." -ForegroundColor Green
    Start-Sleep -Seconds 5
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
            default { Write-Host "❌ Ungültige Eingabe!" -ForegroundColor Red }
        }
    }
}

Show-Menu
