<#
.SYNOPSIS
    Script 02 - Promoción de dc1 a primer controlador de dominio (bosque ad.gestionnorte.es).

.DESCRIPCION
    Proyecto Intermodular 2º ASIR - Consultoría Kalima / Cliente: Gestión Norte
    Módulo: Administración de Sistemas Operativos
    Autor: Arian

    Qué hace, en orden:
      1. Comprueba privilegios y abre log en C:\Evidencias.
      2. Comprueba las precondiciones (nombre, IP, DNS apuntando a sí mismo, que no sea ya DC).
      3. Pide la contraseña del modo de restauración de AD (DSRM) sin escribirla en ningún fichero.
      4. Instala los roles AD DS y DNS.
      5. Crea el bosque y el dominio, con DNS integrado en AD.
      6. Deja el reinicio para después (para poder capturar la salida).

    POR QUÉ estas decisiones:
      - AD DS: control centralizado de identidades (requisito 5) y base de GPO, BitLocker con
        claves en AD y LAPS. Sustituye las claves sueltas por PC que tiene hoy el cliente.
      - DNS integrado en AD: los registros SRV que localizan al controlador se crean y replican
        solos entre dc1 y dc2. Unbound (ubu-fw) reenviará la zona a estos servidores.
      - La contraseña DSRM se pide por pantalla: nunca va en el script ni en Git.
      - Niveles funcionales por defecto del sistema (Windows Server 2025): dc2 también será 2025.

    ANTES DE EJECUTAR: instantánea de VMware "dc1-pre-promocion". Después de promover NO se
    restaura ninguna instantánea de este controlador (USN rollback).

.EJEMPLOS
    .\02-promover-dc1.ps1
    .\02-promover-dc1.ps1 -Reiniciar

.NOTAS
    Ejecutar desde la consola de VMware. Tarda entre 5 y 15 minutos.
#>

[CmdletBinding()]
param(
    [string]$Dominio         = 'ad.gestionnorte.es',
    [string]$NetBIOS         = 'GESTIONNORTE',
    [string]$NombreEsperado  = 'dc1',
    [string]$IPEsperada      = '10.1.20.10',
    [switch]$Reiniciar
)

$ErrorActionPreference = 'Stop'

function Write-Titulo { param($Texto)
    Write-Host ''
    Write-Host ('=' * 72) -ForegroundColor Cyan
    Write-Host "  $Texto" -ForegroundColor Cyan
    Write-Host ('=' * 72) -ForegroundColor Cyan
}
function Write-Ok    { param($Texto) Write-Host "[  OK  ] $Texto" -ForegroundColor Green }
function Write-Info  { param($Texto) Write-Host "[ INFO ] $Texto" -ForegroundColor Gray }
function Write-Aviso { param($Texto) Write-Host "[AVISO ] $Texto" -ForegroundColor Yellow }
function Write-Fallo { param($Texto) Write-Host "[FALLO ] $Texto" -ForegroundColor Red }

# 1. Privilegios y log
$identidad = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identidad)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Fallo 'Este script necesita ejecutarse como Administrador.'
    exit 1
}

$carpetaEvidencias = 'C:\Evidencias'
if (-not (Test-Path $carpetaEvidencias)) { New-Item -Path $carpetaEvidencias -ItemType Directory -Force | Out-Null }
$marca   = Get-Date -Format 'yyyyMMdd-HHmmss'
$fichLog = Join-Path $carpetaEvidencias "02-promover-$NombreEsperado-$marca.log"
Start-Transcript -Path $fichLog -Force | Out-Null

Write-Titulo "SCRIPT 02 - PROMOCIÓN DE $($NombreEsperado.ToUpper()) A CONTROLADOR DE DOMINIO"
Write-Info "Dominio       : $Dominio  (NetBIOS: $NetBIOS)"
Write-Info "Ejecutado por : $($identidad.Name)"
Write-Info "Fecha y hora  : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
Write-Info "Log           : $fichLog"

# 2. Precondiciones
Write-Titulo '2. PRECONDICIONES'
$fallos = 0

if ($env:COMPUTERNAME -ieq $NombreEsperado) { Write-Ok "Nombre del equipo: $env:COMPUTERNAME" }
else { Write-Fallo "El equipo se llama $env:COMPUTERNAME y debería llamarse $NombreEsperado. Ejecuta antes el script 01."; $fallos++ }

$ipOk = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -eq $IPEsperada -and $_.PrefixOrigin -eq 'Manual' }
if ($ipOk) { Write-Ok "IP fija $IPEsperada presente." }
else { Write-Fallo "No hay IP fija $IPEsperada en este equipo."; $fallos++ }

$dnsCliente = (Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses } | Select-Object -ExpandProperty ServerAddresses) -join ', '
if ($dnsCliente -match [regex]::Escape($IPEsperada)) { Write-Ok "El DNS del equipo apunta a sí mismo ($dnsCliente)." }
else { Write-Fallo "El DNS del equipo es '$dnsCliente'. Debe incluir $IPEsperada."; $fallos++ }

$rol = (Get-CimInstance Win32_ComputerSystem).DomainRole
if ($rol -ge 4) { Write-Fallo 'Este equipo ya es controlador de dominio.'; $fallos++ }
else { Write-Ok 'El equipo no es todavía controlador de dominio.' }

# Aviso (no bloquea): hora
Write-Info "Hora actual: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')  Zona: $((Get-TimeZone).Id)"
Write-Info 'Comprueba que la hora es correcta: Kerberos no tolera más de 5 minutos de desfase.'

if ($fallos -gt 0) {
    Write-Host ''
    Write-Fallo "Hay $fallos precondición(es) sin cumplir. No se promueve nada."
    Stop-Transcript | Out-Null
    exit 2
}

# 3. Contraseña DSRM
Write-Titulo '3. CONTRASEÑA DEL MODO DE RESTAURACIÓN (DSRM)'
Write-Info 'Es la contraseña de emergencia para reparar AD. Guárdala en el gestor compartido,'
Write-Info 'NUNCA en Git ni en este script. Mínimo 12 caracteres, con mayúsculas, minúsculas, números y símbolos.'
do {
    $p1 = Read-Host 'Contraseña DSRM' -AsSecureString
    $p2 = Read-Host 'Repite la contraseña' -AsSecureString
    $t1 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($p1))
    $t2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($p2))
    $coincide = ($t1 -ceq $t2)
    $fuerte   = ($t1.Length -ge 12) -and ($t1 -cmatch '[A-Z]') -and ($t1 -cmatch '[a-z]') -and ($t1 -match '\d') -and ($t1 -match '[^\w]')
    if (-not $coincide) { Write-Aviso 'Las contraseñas no coinciden. Otra vez.' }
    elseif (-not $fuerte) { Write-Aviso 'La contraseña no cumple la complejidad mínima. Otra vez.' }
} until ($coincide -and $fuerte)
Remove-Variable t1, t2 -ErrorAction SilentlyContinue
Write-Ok 'Contraseña DSRM aceptada (no se guarda en ningún fichero).'

# 4. Roles
Write-Titulo '4. INSTALACIÓN DE ROLES AD DS Y DNS'
$res = Install-WindowsFeature -Name AD-Domain-Services, DNS -IncludeManagementTools
if ($res.Success) { Write-Ok "Roles instalados. Reinicio necesario por los roles: $($res.RestartNeeded)" }
else { Write-Fallo 'La instalación de roles ha fallado.'; Stop-Transcript | Out-Null; exit 3 }

# 5. Bosque y dominio
Write-Titulo "5. CREACIÓN DEL BOSQUE $Dominio"
Write-Info 'Esto tarda unos minutos. No cierres la ventana.'
Import-Module ADDSDeployment
Install-ADDSForest `
    -DomainName                    $Dominio `
    -DomainNetbiosName             $NetBIOS `
    -InstallDns:$true `
    -CreateDnsDelegation:$false `
    -SafeModeAdministratorPassword $p1 `
    -NoRebootOnCompletion:$true `
    -Force:$true | Out-Null

Write-Ok "Bosque $Dominio creado. Falta reiniciar para terminar la promoción."
Remove-Variable p1, p2 -ErrorAction SilentlyContinue

Write-Titulo '6. RESUMEN'
Write-Info 'Tras reiniciar, inicia sesión como GESTIONNORTE\Administrador y ejecuta el script 03.'
Write-Ok "Script 02 finalizado. Log guardado en: $fichLog"
Stop-Transcript | Out-Null

if ($Reiniciar) {
    Write-Aviso 'Reiniciando en 10 segundos... (Ctrl+C para cancelar)'
    Start-Sleep -Seconds 10
    Restart-Computer -Force
} else {
    Write-Aviso 'Haz tus capturas y reinicia con:  Restart-Computer -Force'
}
