# -----------------------------
# Kombiniertes Netzwerk-, FPS-, RAM- und Software-Optimierungs-Skript
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

    Write-Host "🖥  CPU: $($cpu.Name)" -ForegroundColor Green
    Write-Host "🎮 GPU: $($gpu.Name)" -ForegroundColor Green
    Write-Host "💾 RAM: $ramTotal GB (Details unten)" -ForegroundColor Green
    $ramDetails | ForEach-Object { Write-Host "   - $_" -ForegroundColor Green }
    Write-Host "=================================" -ForegroundColor Yellow
    Start-Sleep 3
    Clear-Host
}

# Funktion zur FPS-Optimierung
function Apply-FPSOptimizations {
    Clear-Host
    Write-Host "`n$asciiLogo" -ForegroundColor Magenta
    Write-Host "`n🎮 FPS-Optimierung wird angewendet..." -ForegroundColor Cyan

    # Energieoptionen auf Höchstleistung setzen
    powercfg -setactive SCHEME_MIN
    Write-Host "✅ Energieoptionen auf Höchstleistung gesetzt." -ForegroundColor Green

    # Windows-Animationen deaktivieren
    reg add "HKCU\Control Panel\Desktop" /v "FontSmoothing" /t REG_SZ /d 2 /f | Out-Null  # Verhindert Ausgabe
    reg add "HKCU\Software\Microsoft\Windows\DWM" /v "EnableAeroPeek" /t REG_DWORD /d 0 /f | Out-Null  # Verhindert Ausgabe
    Write-Host "✅ Windows-Animationen und Aero Peek deaktiviert." -ForegroundColor Green

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
$global:networkOptimizedStartTime = $null
function Optimize-Network {
    Clear-Host
    Write-Host "`n$asciiLogo" -ForegroundColor Magenta
    Write-Host "`n🌐 Wende Netzwerk-Optimierungen an..." -ForegroundColor Cyan

    # Überprüfen, ob bereits eine Wartezeit läuft
    if ($global:networkOptimizedStartTime -ne $null) {
        $elapsedTime = (New-TimeSpan -Start $global:networkOptimizedStartTime).TotalSeconds
        $remainingTime = [math]::Max(600 - $elapsedTime, 0)  # 600 Sekunden (10 Minuten)
        
        if ($remainingTime -gt 0) {
            Write-Host "Du musst noch $([math]::Floor($remainingTime)) Sekunden warten, bevor du die Optimierung erneut durchführen kannst." -ForegroundColor Yellow
            return
        }
    }

    

     # Nagle-Algorithmus deaktivieren
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" -Name "TcpAckFrequency" -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" -Name "TCPNoDelay" -Value 1 -PropertyType DWord -Force | Out-Null
    Write-Host "✅ Nagle-Algorithmus deaktiviert." -ForegroundColor Green

    # TCP-Autotuning-Level anpassen
    netsh int tcp set global autotuninglevel=normal | Out-Null  # Verhindert Ausgabe
    Write-Host "✅ TCP-Autotuning-Level gesetzt." -ForegroundColor Green

    # DNS-Cache leeren (keine unnötige Ausgabe)
    ipconfig /flushdns | Out-Null  # Verhindert Ausgabe
    Write-Host "✅ DNS-Cache geleert." -ForegroundColor Green

    # Geschwindigkeit nach der Optimierung messen
	Write-Host "Speedtest wird durchgeführt..." -ForegroundColor Cyan
    $afterSpeed = Get-NetworkSpeed
    Write-Host "[Speedtest] Ping: $($afterSpeed.Ping) ms, Download: $($afterSpeed.Download) Mbps, Upload: $($afterSpeed.Upload) Mbps" -ForegroundColor Green

	
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

    # Hintergrundprozesse beenden
    $processesToKill = @("OneDrive", "Skype", "Discord", "Teams", "Steam", "EpicGamesLauncher", "Battle.net", "chrome", "firefox", "msedge", "opera", "brave")
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
    Start-Sleep 3
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
    Start-Sleep 3
    Clear-Host
}

# Menü anzeigen
function Show-Menu {
    Clear-Host
    Write-Host "`n$asciiLogo" -ForegroundColor Magenta
    Show-HardwareInfo  # Automatische Anzeige der Hardware-Informationen beim ersten Start
    
    while ($true) {
        Write-Host "`nBitte wählen Sie eine Option:"
        Write-Host "1. FPS Optimierung"
        Write-Host "2. Netzwerk Optimierung"
        Write-Host "3. RAM Optimierung"
        Write-Host "4. Software-Upgrade"
        Write-Host "5. Beenden"
        $selection = Read-Host "Geben Sie Ihre Wahl ein"

        switch ($selection) {
            "1" { Apply-FPSOptimizations }
            "2" { Optimize-Network }
            "3" { Optimize-RAM }
            "4" { Upgrade-Software }
            "5" { exit }
            default { Write-Host "Ungültige Auswahl, bitte wählen Sie erneut." -ForegroundColor Red }
        }
    }
}

# Skript starten
Show-Menu
# -----------------------------
# Kombiniertes Netzwerk-, FPS-, RAM- und Software-Optimierungs-Skript
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

    Write-Host "🖥  CPU: $($cpu.Name)" -ForegroundColor Green
    Write-Host "🎮 GPU: $($gpu.Name)" -ForegroundColor Green
    Write-Host "💾 RAM: $ramTotal GB (Details unten)" -ForegroundColor Green
    $ramDetails | ForEach-Object { Write-Host "   - $_" -ForegroundColor Green }
    Write-Host "=================================" -ForegroundColor Yellow
    Start-Sleep 3
    Clear-Host
}

# Funktion zur FPS-Optimierung
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
$global:networkOptimizedStartTime = $null
function Optimize-Network {
    Clear-Host
    Write-Host "`n$asciiLogo" -ForegroundColor Magenta
    Write-Host "`n🌐 Wende Netzwerk-Optimierungen an..." -ForegroundColor Cyan

    # Überprüfen, ob bereits eine Wartezeit läuft
    if ($global:networkOptimizedStartTime -ne $null) {
        $elapsedTime = (New-TimeSpan -Start $global:networkOptimizedStartTime).TotalSeconds
        $remainingTime = [math]::Max(600 - $elapsedTime, 0)  # 600 Sekunden (10 Minuten)
        
        if ($remainingTime -gt 0) {
            Write-Host "Du musst noch $([math]::Floor($remainingTime)) Sekunden warten, bevor du die Optimierung erneut durchführen kannst." -ForegroundColor Yellow
            return
        }
    }

    

     # Nagle-Algorithmus deaktivieren
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" -Name "TcpAckFrequency" -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" -Name "TCPNoDelay" -Value 1 -PropertyType DWord -Force | Out-Null
    Write-Host "✅ Nagle-Algorithmus deaktiviert." -ForegroundColor Green

    # TCP-Autotuning-Level anpassen
    netsh int tcp set global autotuninglevel=normal | Out-Null  # Verhindert Ausgabe
    Write-Host "✅ TCP-Autotuning-Level gesetzt." -ForegroundColor Green

    # DNS-Cache leeren (keine unnötige Ausgabe)
    ipconfig /flushdns | Out-Null  # Verhindert Ausgabe
    Write-Host "✅ DNS-Cache geleert." -ForegroundColor Green

    # Geschwindigkeit nach der Optimierung messen
	Write-Host "Speedtest wird durchgeführt..." -ForegroundColor Cyan
    $afterSpeed = Get-NetworkSpeed
    Write-Host "[SPeedtest] Ping: $($afterSpeed.Ping) ms, Download: $($afterSpeed.Download) Mbps, Upload: $($afterSpeed.Upload) Mbps" -ForegroundColor Green

	
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

    # Hintergrundprozesse beenden
    $processesToKill = @("OneDrive", "Skype", "Discord", "Teams", "Steam", "EpicGamesLauncher", "Battle.net", "chrome", "firefox", "msedge", "opera", "brave")
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
    Start-Sleep 3
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
    Start-Sleep 3
    Clear-Host
}

# Menü anzeigen
function Show-Menu {
    Clear-Host
    Write-Host "`n$asciiLogo" -ForegroundColor Magenta
    Show-HardwareInfo  # Automatische Anzeige der Hardware-Informationen beim ersten Start
    
    while ($true) {
        Write-Host "`nBitte wählen Sie eine Option:"
        Write-Host "1. FPS Optimierung"
        Write-Host "2. Netzwerk Optimierung"
        Write-Host "3. RAM Optimierung"
        Write-Host "4. Software-Upgrade"
        Write-Host "5. Beenden"
        $selection = Read-Host "Geben Sie Ihre Wahl ein"

        switch ($selection) {
            "1" { Apply-FPSOptimizations }
            "2" { Optimize-Network }
            "3" { Optimize-RAM }
            "4" { Upgrade-Software }
            "5" { exit }
            default { Write-Host "Ungültige Auswahl, bitte wählen Sie erneut." -ForegroundColor Red }
        }
    }
}

# Skript starten
Show-Menu
