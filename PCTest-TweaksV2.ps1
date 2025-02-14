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
    reg add "HKCU\Control Panel\Desktop" /v "FontSmoothing" /t REG_SZ /d 2 /f | Out-Null  
    reg add "HKCU\Software\Microsoft\Windows\DWM" /v "EnableAeroPeek" /t REG_DWORD /d 0 /f | Out-Null  
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
function Optimize-Network {
    Clear-Host
    Write-Host "`n$asciiLogo" -ForegroundColor Magenta
    Write-Host "`n🌐 Wende Netzwerk-Optimierungen an..." -ForegroundColor Cyan

    # Nagle-Algorithmus deaktivieren
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\<Interface_ID>" -Name "TcpAckFrequency" -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\<Interface_ID>" -Name "TCPNoDelay" -Value 1 -PropertyType DWord -Force | Out-Null
    Write-Host "✅ Nagle-Algorithmus deaktiviert." -ForegroundColor Green

    # TCP-Autotuning-Level anpassen
    netsh int tcp set global autotuninglevel=normal | Out-Null  
    Write-Host "✅ TCP-Autotuning-Level gesetzt." -ForegroundColor Green

    # DNS-Cache leeren
    ipconfig /flushdns | Out-Null  
    Write-Host "✅ DNS-Cache geleert." -ForegroundColor Green

    Start-Sleep 3
    Clear-Host
}

# Funktion zum Speedtest
function Run-Speedtest {
    Clear-Host
    Write-Host "`n🚀 Speedtest wird durchgeführt..." -ForegroundColor Cyan
    $speed = Get-NetworkSpeed
    Write-Host "[Speedtest] Ping: $($speed.Ping) ms, Download: $($speed.Download) Mbps, Upload: $($speed.Upload) Mbps" -ForegroundColor Green
    Start-Sleep 5
}

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
        winget upgrade --all 
    } catch {
        Write-Host "[✖] Fehler beim Aktualisieren von Software." -ForegroundColor Red
    }
    Write-Host "[✔] Software-Upgrade abgeschlossen." -ForegroundColor Green
    Start-Sleep 3
    Clear-Host
}

# Funktion zur Datenträger-Optimierung
function Optimize-Storage {
    Clear-Host
    Write-Host "`n$asciiLogo" -ForegroundColor Magenta
    Write-Host "`n💾 Starte Datenträger-Optimierung..." -ForegroundColor Cyan

    # Ermittlung des freien Speicherplatzes vor der Optimierung
    $drive = Get-PSDrive C
    $beforeStorage = [math]::Round($drive.Free / 1MB, 2)
    Write-Host "[Vorher] Freier Speicherplatz: $beforeStorage MB" -ForegroundColor Red

    # Datenträgerbereinigung (ohne Löschen wichtiger Systemdateien)
    Write-Host "🧹 Führe Datenträgerbereinigung aus..." -ForegroundColor Yellow
    Start-Process -NoNewWindow -Wait -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1"

    # Defragmentierung (nur für HDDs, SSDs werden optimiert)
    Write-Host "🚀 Optimiere Laufwerk..." -ForegroundColor Yellow
    Optimize-Volume -DriveLetter C

    # Ermittlung des freien Speicherplatzes nach der Optimierung
    $drive = Get-PSDrive C
    $afterStorage = [math]::Round($drive.Free / 1MB, 2)
    Write-Host "[Nachher] Freier Speicherplatz: $afterStorage MB" -ForegroundColor Green

    Write-Host "✅ Datenträger-Optimierung abgeschlossen!" -ForegroundColor Yellow
    Start-Sleep 3
    Clear-Host
}



function Enable-SystemRestore {
    Write-Host "📝 Überprüfe, ob die Systemwiederherstellung aktiviert ist..." -ForegroundColor Cyan
    
    $restoreStatus = Get-WmiObject -Class Win32_OperatingSystem
    if ($restoreStatus.SystemRestore) {
        Write-Host "✅ Systemwiederherstellung ist bereits aktiviert!" -ForegroundColor Green
        return $true
    } else {
        Write-Host "❌ Systemwiederherstellung ist nicht aktiviert. Versuche, sie zu aktivieren..." -ForegroundColor Red
        try {
            Enable-ComputerRestore -Drive "C:"
            Write-Host "✅ Systemwiederherstellung wurde erfolgreich aktiviert!" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Host "❌ Fehler beim Aktivieren der Systemwiederherstellung: $_" -ForegroundColor Red
            return $false
        }
    }
}

function Create-RestorePoint {
    Write-Host "📝 Erstelle Wiederherstellungspunkt..." -ForegroundColor Cyan

    try {
        if (Enable-SystemRestore) {
            $result = CheckPoint-Computer -Description "Vor Optimierung" -RestorePointType "MODIFY_SETTINGS"
            if ($result -eq $null) {
                Write-Host "❌ Es gab ein Problem beim Erstellen des Wiederherstellungspunkts." -ForegroundColor Red
                return $false
            }
            Write-Host "✅ Wiederherstellungspunkt erstellt!" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Systemwiederherstellung konnte nicht aktiviert werden!" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Fehler beim Erstellen des Wiederherstellungspunkts: $_" -ForegroundColor Red
        return $false
    }
}

# Hauptmenü mit der einmaligen Frage nach dem Wiederherstellungspunkt
function Show-Menu {
    Clear-Host
    Write-Host "`n$asciiLogo" -ForegroundColor Magenta

    # Frage nach Wiederherstellungspunkt nur einmal stellen
    $createRestorePoint = Read-Host "Möchten Sie einen Wiederherstellungspunkt erstellen? (J/N)"
    if ($createRestorePoint -eq "J" -or $createRestorePoint -eq "j") {
        Create-RestorePoint
    }

    while ($true) {
        Clear-Host
        Write-Host "`n$asciiLogo" -ForegroundColor Magenta
        Write-Host "`n=================================" -ForegroundColor Yellow
        Write-Host "`nBitte wählen Sie eine Option:" -ForegroundColor Cyan
        Write-Host "1. FPS Optimierung" -ForegroundColor Cyan
        Write-Host "2. Netzwerk Menü" -ForegroundColor Cyan
        Write-Host "3. RAM Optimierung" -ForegroundColor Cyan
        Write-Host "4. Software-Update" -ForegroundColor Cyan
        Write-Host "5. Datenträger-Optimierung" -ForegroundColor Cyan
        Write-Host "6. Beenden" -ForegroundColor Cyan
        $selection = Read-Host "Geben Sie Ihre Wahl ein" 

        switch ($selection) {
            "1" { Apply-FPSOptimizations }
            "2" { Show-NetworkMenu }
            "3" { Optimize-RAM }
            "4" { Upgrade-Software }
            "5" { Optimize-Storage }
            "6" { exit }
            default { Write-Host "Ungültige Auswahl, bitte wählen Sie erneut." -ForegroundColor Red }
        }
    }
}

# Netzwerk-Untermenü
function Show-NetworkMenu {
    while ($true) {
        Clear-Host
        Write-Host "`n$asciiLogo" -ForegroundColor Magenta
        Write-Host "`n=================================" -ForegroundColor Yellow
        Write-Host "`n🌐 Netzwerk-Menü:" -ForegroundColor Cyan
        Write-Host "1. Netzwerk optimieren" -ForegroundColor Cyan
        Write-Host "2. Speedtest ausführen" -ForegroundColor Cyan
        Write-Host "3. Zurück zum Hauptmenü" -ForegroundColor Cyan
        $networkSelection = Read-Host "Geben Sie Ihre Wahl ein" 

        switch ($networkSelection) {
            "1" { Optimize-Network }
            "2" { Run-Speedtest }
            "3" { return }
            default { Write-Host "Ungültige Auswahl, bitte wählen Sie erneut." -ForegroundColor Red }
        }
    }
}

# Starte das Skript mit dem Hauptmenü
Show-Menu
