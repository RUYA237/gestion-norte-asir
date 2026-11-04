<#
.SYNOPSIS
    Script 10 - GPO de Windows Update para equipos y servidores miembro.

.DESCRIPCION
    Proyecto Intermodular 2º ASIR - Consultoría Kalima / Cliente: Gestión Norte
    Módulo: Administración de Sistemas Operativos
    Autor: Arian

    Qué hace, en orden:
      1. Comprueba privilegios, que es controlador de dominio y que existen las OU de equipos y servidores.
      2. Crea la GPO GN-Equipos-WindowsUpdate y la enlaza a OU=Equipos y OU=Servidores.
      3. Configura en la GPO:
         - Descarga automática e instalación programada (cada día a las 03:00).
         - Horas activas 08:00-20:00: no se reinicia en horario de trabajo.
         - Sin reinicio automático con usuarios con sesión iniciada.
         - Aplazamiento de 7 días de las actualizaciones de calidad (anillo de pruebas).
      4. Verifica la GPO, el enlace y los valores.

    POR QUÉ:
      - Parches: requisito de seguridad del proyecto (parches e inventario). Un equipo sin parches
        es la vía de entrada más habitual de ransomware.
      - Horas activas y sin reinicio con sesión: más de 2 h de parada en campaña fiscal es grave.
        Un reinicio en mitad de la jornada de un asesor es una parada.
      - Aplazamiento de 7 días: da margen para probar el parche en el laboratorio antes de que
        llegue a los 150 equipos. Si un parche rompe algo, se detecta con ventaja.
      - GPO propia y no mezclada con la de seguridad: se puede desactivar o modificar sin tocar LAPS
        ni BitLocker.
      - WSUS queda como propuesto (decisión D13). En laboratorio se usa Windows Update por GPO.

    LÍMITES (a documentar en la memoria):
      - Sin WSUS no hay control de aprobación de parches ni informes centralizados de cumplimiento.
        Propuesto: WSUS o Windows Update for Business en producción.
      - Propuesto: congelar cambios en campaña fiscal (abril a junio) con un parámetro de la GPO.
      - La verificación en cliente (gpresult y claves del registro) queda para cli01.

.EJEMPLOS
    .\10-gpo-windows-update.ps1

.NOTAS
    Ejecutar en dc1 con GESTIONNORTE\Administrador, después del script 04.
    Haz snapshot "dc1-pre-gpo-wu" antes de ejecutarlo.
#>

[CmdletBinding()]
param(
    [string]$NombreGPO = 'GN-Equipos-WindowsUpdate'
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

# --- 1. Privilegios, log y precondiciones -------------------------------------------
$identidad = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identidad)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Fallo 'Este script necesita ejecutarse como Administrador.'
    exit 1
}

$carpetaEvidencias = 'C:\Evidencias'
if (-not (Test-Path $carpetaEvidencias)) { New-Item -Path $carpetaEvidencias -ItemType Directory -Force | Out-Null }
$marca   = Get-Date -Format 'yyyyMMdd-HHmmss'
$fichLog = Join-Path $carpetaEvidencias "10-gpo-wu-$($env:COMPUTERNAME.ToLower())-$marca.log"
Start-Transcript -Path $fichLog -Force | Out-Null

Write-Titulo 'SCRIPT 10 - GPO DE WINDOWS UPDATE'
Write-Info "Ejecutado por : $($identidad.Name)"
Write-Info "Fecha y hora  : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
Write-Info "Log           : $fichLog"

Write-Titulo '1. PRECONDICIONES'
$rol = (Get-CimInstance Win32_ComputerSystem).DomainRole
if ($rol -lt 4) {
    Write-Fallo 'Este equipo no es controlador de dominio. Ejecuta antes los scripts 02 a 04.'
    Stop-Transcript | Out-Null
    exit 2
}
Import-Module ActiveDirectory, GroupPolicy -ErrorAction Stop
$dominioDN = (Get-ADDomain).DistinguishedName

$destinos = @("OU=Equipos,OU=GestionNorte,$dominioDN", "OU=Servidores,OU=GestionNorte,$dominioDN")
foreach ($ou in $destinos) {
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ou'" -ErrorAction SilentlyContinue)) {
        Write-Fallo "No existe $ou. Ejecuta antes el script 04."
        Stop-Transcript | Out-Null
        exit 3
    }
}
Write-Ok 'Existen las OU de equipos y servidores (script 04).'

# --- 2. GPO y enlaces ------------------------------------------------------------------
Write-Titulo '2. GPO Y ENLACES'
$gpo = Get-GPO -Name $NombreGPO -ErrorAction SilentlyContinue
if ($gpo) { Write-Info "Ya existe la GPO $NombreGPO. Se actualizan sus valores." }
else {
    $gpo = New-GPO -Name $NombreGPO -Comment 'Windows Update: instalación nocturna, horas activas y aplazamiento de 7 días (script 10)'
    Write-Ok "GPO creada: $NombreGPO"
}

foreach ($ou in $destinos) {
    $enlazada = (Get-GPInheritance -Target $ou).GpoLinks | Where-Object { $_.DisplayName -eq $NombreGPO }
    if ($enlazada) { Write-Info "La GPO ya está enlazada a $ou." }
    else {
        New-GPLink -Name $NombreGPO -Target $ou -LinkEnabled Yes | Out-Null
        Write-Ok "GPO enlazada a $ou."
    }
}

# --- 3. Ajustes de la GPO -----------------------------------------------------------------
Write-Titulo '3. AJUSTES DE LA GPO'

$wu = 'HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate'
$au = "$wu\AU"

# Instalación automática programada
Set-GPRegistryValue -Name $NombreGPO -Key $au -ValueName 'NoAutoUpdate'       -Type DWord -Value 0
Set-GPRegistryValue -Name $NombreGPO -Key $au -ValueName 'AUOptions'          -Type DWord -Value 4   # 4 = descargar e instalar según programación
Set-GPRegistryValue -Name $NombreGPO -Key $au -ValueName 'ScheduledInstallDay'  -Type DWord -Value 0  # 0 = todos los días
Set-GPRegistryValue -Name $NombreGPO -Key $au -ValueName 'ScheduledInstallTime' -Type DWord -Value 3  # 03:00
Write-Ok 'Instalación automática: todos los días a las 03:00.'

# Sin reinicio en horario de trabajo
Set-GPRegistryValue -Name $NombreGPO -Key $au -ValueName 'NoAutoRebootWithLoggedOnUsers' -Type DWord -Value 1
Set-GPRegistryValue -Name $NombreGPO -Key $wu -ValueName 'SetActiveHours'   -Type DWord -Value 1
Set-GPRegistryValue -Name $NombreGPO -Key $wu -ValueName 'ActiveHoursStart' -Type DWord -Value 8
Set-GPRegistryValue -Name $NombreGPO -Key $wu -ValueName 'ActiveHoursEnd'   -Type DWord -Value 20
Write-Ok 'Horas activas 08:00-20:00 y sin reinicio automático con usuarios conectados.'

# Aplazamiento de actualizaciones de calidad (anillo de pruebas)
Set-GPRegistryValue -Name $NombreGPO -Key $wu -ValueName 'DeferQualityUpdates'             -Type DWord -Value 1
Set-GPRegistryValue -Name $NombreGPO -Key $wu -ValueName 'DeferQualityUpdatesPeriodInDays' -Type DWord -Value 7
Write-Ok 'Actualizaciones de calidad aplazadas 7 días (margen para probar).'

# --- 4. Verificación -----------------------------------------------------------------------------
Write-Titulo '4. VERIFICACIÓN'

Write-Host 'GPO:' -ForegroundColor White
Get-GPO -Name $NombreGPO | Format-List DisplayName, GpoStatus, CreationTime, ModificationTime

Write-Host 'Enlaces:' -ForegroundColor White
foreach ($ou in $destinos) {
    Write-Host "  $ou" -ForegroundColor Gray
    (Get-GPInheritance -Target $ou).GpoLinks | Where-Object { $_.DisplayName -eq $NombreGPO } |
        Format-Table DisplayName, Enabled, Enforced -AutoSize
}

Write-Host 'Valores configurados (WindowsUpdate):' -ForegroundColor White
Get-GPRegistryValue -Name $NombreGPO -Key $wu -ErrorAction SilentlyContinue |
    Where-Object { $_.ValueName } | Format-Table ValueName, Value -AutoSize

Write-Host 'Valores configurados (WindowsUpdate\AU):' -ForegroundColor White
Get-GPRegistryValue -Name $NombreGPO -Key $au | Format-Table ValueName, Value -AutoSize

Write-Host ''
Write-Ok "Script 10 finalizado. Log guardado en: $fichLog"
Write-Info 'PENDIENTE DE VERIFICAR: en cli01 (gpresult /r y claves del registro de Windows Update).'
Stop-Transcript | Out-Null
