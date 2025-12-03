# ============================================================
# 🌙 MOONSTONE CONNECTION TOOL - PowerShell
# ============================================================
# Autor: DevSan | Data: 30/11/2025
# Dispositivo: POCO X5 5G (Moonstone) | ADB ID: 72e24d130223
# ============================================================

param(
    [Parameter(Position=0)]
    [ValidateSet("ssh", "adb", "root", "status", "sync", "ip", "termux", "reboot", "screenshot", "menu")]
    [string]$Action = "menu",
    
    [string]$Command,
    [switch]$Force
)

# === CONFIGURAÇÕES ===
$DEVICE_ID = "72e24d130223"
$SSH_USER = "u0_a575"
$SSH_PORT = 8022
$SSH_KEY = "$env:USERPROFILE\.ssh\id_ed25519"
$WORKSPACE_LOCAL = "C:\Projetos\Android"
$WORKSPACE_REMOTE = "/data/data/com.termux/files/home/Android"
$SCREENSHOT_DIR = "C:\Projetos\Screenshots"

# === FUNÇÕES AUXILIARES ===

function Write-Banner {
    Write-Host @"

    ╔═══════════════════════════════════════════════════════════╗
    ║          🌙 MOONSTONE CONNECTION TOOL v1.0                ║
    ║          POCO X5 5G | Darkmoon-KSU | Android 16           ║
    ╚═══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan
}

function Test-AdbConnection {
    $devices = adb devices 2>$null | Select-String $DEVICE_ID
    return $null -ne $devices
}

function Get-DeviceIP {
    if (-not (Test-AdbConnection)) {
        return $null
    }
    $ip = adb -s $DEVICE_ID shell "ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print `$2}' | cut -d/ -f1" 2>$null
    return $ip.Trim()
}

function Get-NetworkType {
    $ip = Get-DeviceIP
    if ($ip -match "^192\.168\.25\.") { return "Casa" }
    if ($ip -match "^172\.17\.") { return "UFRB" }
    if ($ip -match "^10\.") { return "Mobile" }
    return "Desconhecida"
}

function Show-Status {
    Write-Banner
    
    $adbConnected = Test-AdbConnection
    $ip = Get-DeviceIP
    $network = Get-NetworkType
    
    Write-Host "  📱 DISPOSITIVO" -ForegroundColor Yellow
    Write-Host "  ├─ ID: $DEVICE_ID"
    Write-Host "  ├─ ADB: $(if ($adbConnected) { '✅ Conectado' } else { '❌ Desconectado' })"
    Write-Host "  └─ Status: $(if ($adbConnected) { (adb -s $DEVICE_ID get-state 2>$null) } else { 'N/A' })"
    Write-Host ""
    
    Write-Host "  📡 REDE" -ForegroundColor Yellow
    Write-Host "  ├─ IP: $(if ($ip) { $ip } else { 'N/A' })"
    Write-Host "  ├─ Tipo: $network"
    Write-Host "  └─ SSH: ${SSH_USER}@${ip}:${SSH_PORT}"
    Write-Host ""
    
    if ($adbConnected) {
        Write-Host "  💾 SISTEMA" -ForegroundColor Yellow
        $kernel = adb -s $DEVICE_ID shell "uname -r" 2>$null
        $uptime = adb -s $DEVICE_ID shell "uptime -p" 2>$null
        $battery = adb -s $DEVICE_ID shell "dumpsys battery | grep level" 2>$null | ForEach-Object { $_ -replace '.*: ', '' }
        
        Write-Host "  ├─ Kernel: $($kernel.Trim())"
        Write-Host "  ├─ Uptime: $($uptime.Trim())"
        Write-Host "  └─ Bateria: ${battery}%"
    }
    Write-Host ""
}

function Connect-SSH {
    $ip = Get-DeviceIP
    if (-not $ip) {
        Write-Host "❌ Não foi possível detectar IP do dispositivo" -ForegroundColor Red
        Write-Host "💡 Verifique se o dispositivo está conectado via USB e ADB está funcionando" -ForegroundColor Yellow
        return
    }
    
    Write-Host "📡 IP detectado: $ip ($( Get-NetworkType ))" -ForegroundColor Green
    Write-Host "🔐 Conectando via SSH..." -ForegroundColor Cyan
    
    if (Test-Path $SSH_KEY) {
        ssh -i $SSH_KEY -p $SSH_PORT -o StrictHostKeyChecking=no "${SSH_USER}@${ip}"
    } else {
        ssh -p $SSH_PORT -o StrictHostKeyChecking=no "${SSH_USER}@${ip}"
    }
}

function Connect-ADB {
    param([switch]$Root, [string]$Cmd)
    
    if (-not (Test-AdbConnection)) {
        Write-Host "❌ Dispositivo não encontrado" -ForegroundColor Red
        return
    }
    
    Write-Host "🔌 Conectando via ADB..." -ForegroundColor Cyan
    
    if ($Root) {
        if ($Cmd) {
            adb -s $DEVICE_ID shell "su -c '$Cmd'"
        } else {
            adb -s $DEVICE_ID shell "su -c 'cd /data/data/com.termux/files/home && exec /data/data/com.termux/files/usr/bin/zsh -l'"
        }
    } else {
        if ($Cmd) {
            adb -s $DEVICE_ID shell $Cmd
        } else {
            adb -s $DEVICE_ID shell
        }
    }
}

function Sync-Workspace {
    param([switch]$Pull, [switch]$Push)
    
    if (-not (Test-AdbConnection)) {
        Write-Host "❌ Dispositivo não conectado" -ForegroundColor Red
        return
    }
    
    if ($Push -or (-not $Pull -and -not $Push)) {
        Write-Host "📤 Enviando workspace para dispositivo..." -ForegroundColor Yellow
        adb -s $DEVICE_ID push "$WORKSPACE_LOCAL\." $WORKSPACE_REMOTE
        Write-Host "✅ Push completo!" -ForegroundColor Green
    }
    
    if ($Pull) {
        Write-Host "📥 Baixando workspace do dispositivo..." -ForegroundColor Yellow
        adb -s $DEVICE_ID pull "$WORKSPACE_REMOTE\." $WORKSPACE_LOCAL
        Write-Host "✅ Pull completo!" -ForegroundColor Green
    }
}

function Open-Termux {
    if (-not (Test-AdbConnection)) {
        Write-Host "❌ Dispositivo não conectado" -ForegroundColor Red
        return
    }
    
    Write-Host "📱 Abrindo Termux..." -ForegroundColor Cyan
    adb -s $DEVICE_ID shell "am start -n com.termux/.app.TermuxActivity"
    Write-Host "✅ Termux aberto!" -ForegroundColor Green
}

function Take-Screenshot {
    if (-not (Test-AdbConnection)) {
        Write-Host "❌ Dispositivo não conectado" -ForegroundColor Red
        return
    }
    
    if (-not (Test-Path $SCREENSHOT_DIR)) {
        New-Item -ItemType Directory -Path $SCREENSHOT_DIR -Force | Out-Null
    }
    
    $date = Get-Date -Format "yyyyMMdd_HHmmss"
    $file = "$SCREENSHOT_DIR\moon_$date.png"
    
    Write-Host "📸 Capturando tela..." -ForegroundColor Cyan
    adb -s $DEVICE_ID exec-out screencap -p > $file
    Write-Host "✅ Screenshot salvo: $file" -ForegroundColor Green
    
    # Abrir imagem
    Start-Process $file
}

function Restart-Device {
    param([switch]$Bootloader, [switch]$Recovery)
    
    if (-not (Test-AdbConnection)) {
        Write-Host "❌ Dispositivo não conectado" -ForegroundColor Red
        return
    }
    
    if ($Bootloader) {
        Write-Host "🔄 Reiniciando para Bootloader..." -ForegroundColor Yellow
        adb -s $DEVICE_ID reboot bootloader
    } elseif ($Recovery) {
        Write-Host "🔄 Reiniciando para Recovery..." -ForegroundColor Yellow
        adb -s $DEVICE_ID reboot recovery
    } else {
        Write-Host "🔄 Reiniciando dispositivo..." -ForegroundColor Yellow
        adb -s $DEVICE_ID reboot
    }
}

function Show-Menu {
    Write-Banner
    
    Write-Host "  📋 MENU PRINCIPAL" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. 🔐 SSH (Auto IP detect)"
    Write-Host "  2. 🔌 ADB Shell"
    Write-Host "  3. 👑 ADB Root Shell (su + zsh)"
    Write-Host "  4. 📊 Status do Dispositivo"
    Write-Host "  5. 📤 Sync Workspace (Push)"
    Write-Host "  6. 📸 Screenshot"
    Write-Host "  7. 📱 Abrir Termux"
    Write-Host "  8. 🔄 Reiniciar"
    Write-Host "  0. ❌ Sair"
    Write-Host ""
    
    $choice = Read-Host "  Escolha uma opção"
    
    switch ($choice) {
        "1" { Connect-SSH }
        "2" { Connect-ADB }
        "3" { Connect-ADB -Root }
        "4" { Show-Status; Read-Host "Pressione Enter para continuar" }
        "5" { Sync-Workspace -Push }
        "6" { Take-Screenshot }
        "7" { Open-Termux }
        "8" { Restart-Device }
        "0" { exit }
        default { 
            Write-Host "❌ Opção inválida" -ForegroundColor Red
            Start-Sleep -Seconds 1
            Show-Menu 
        }
    }
}

# === EXECUÇÃO PRINCIPAL ===

switch ($Action) {
    "ssh" { Connect-SSH }
    "adb" { Connect-ADB -Cmd $Command }
    "root" { Connect-ADB -Root -Cmd $Command }
    "status" { Show-Status }
    "sync" { Sync-Workspace }
    "ip" { 
        $ip = Get-DeviceIP
        if ($ip) { Write-Host $ip } else { Write-Host "N/A" }
    }
    "termux" { Open-Termux }
    "reboot" { Restart-Device }
    "screenshot" { Take-Screenshot }
    "menu" { Show-Menu }
}