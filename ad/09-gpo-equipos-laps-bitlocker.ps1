<#
.SYNOPSIS
    Script 09 - GPO de equipos: Windows LAPS, copia de claves de BitLocker en AD y ajustes de seguridad.

.DESCRIPCION
    Proyecto Intermodular 2º ASIR - Consultoría Kalima / Cliente: Gestión Norte
    Módulo: Administración de Sistemas Operativos
    Autor: Arian

    Qué hace, en orden:
      1. Comprueba privilegios, que es controlador de dominio y que existen las OU de equipos (script 04).
      2. Amplía el esquema de AD para Windows LAPS y da permiso a los equipos de la OU para
         guardar su propia contraseña de administrador local.
      3. Crea la GPO GN-Equipos-Seguridad y la enlaza a OU=Equipos,OU=GestionNorte.
      4. Configura en la GPO:
         - LAPS: contraseña de 20 caracteres, rotación cada 30 días, guardada en AD,
           y cambio de contraseña tras cada acceso con la cuenta local.
         - BitLocker: copia obligatoria de la clave de recuperación en AD antes de cifrar.
      5. Verifica la GPO, el esquema y los permisos.

    POR QUÉ:
      - LAPS: cada equipo tiene una contraseña de administrador local distinta y rotada. Si un
        equipo se compromete, no sirve para moverse al resto (movimiento lateral). Sustituye las
        claves de administrador repetidas que tiene hoy el cliente.
      - BitLocker con clave en AD: si un portátil se pierde o el TPM falla, la clave está en el
        dominio y el equipo se puede recuperar sin perder datos fiscales ni laborales (RGPD).
        Sin esa copia, el cifrado puede convertirse en pérdida de datos.
      - GPO enlazada a OU=Equipos: ningún equipo recibe la política por accidente. Es la misma
        razón por la que el script 04 redirigió los equipos nuevos a esa OU.

    LÍMITES (a documentar en la memoria):
      - Estas directivas tienen efecto cuando el equipo recibe la GPO. En el laboratorio se
        verifica con cli01 unido al dominio (pendiente).
      - Los valores de registro de las directivas se comprueban con Get-GPRegistryValue. La
        comprobación en el cliente se hace con gpresult /r y con la consola de LAPS.
      - Windows LAPS integrado: no hace falta instalar nada. Se usa Update-LapsADSchema.

.EJEMPLOS
    .\09-gpo-equipos-laps-bitlocker.ps1

.NOTAS
    Ejecutar en dc1 con GESTIONNORTE\Administrador, después del script 04.
    Haz snapshot "dc1-pre-gpo-equipos" antes de ejecutarlo.
#>

[CmdletBinding()]
param(
    [string]$NombreGPO = 'GN-Equipos-Seguridad'
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

# --- 1. Privilegios, log y precondiciones -----------------------------------------------
$identidad = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identidad)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Fallo 'Este script necesita ejecutarse como Administrador.'
    exit 1
}

$carpetaEvidencias = 'C:\Evidencias'
if (-not (Test-Path $carpetaEvidencias)) { New-Item -Path $carpetaEvidencias -ItemType Directory -Force | Out-Null }
$marca   = Get-Date -Format 'yyyyMMdd-HHmmss'
$fichLog = Join-Path $carpetaEvidencias "09-gpo-equipos-$($env:COMPUTERNAME.ToLower())-$marca.log"
Start-Transcript -Path $fichLog -Force | Out-Null

Write-Titulo 'SCRIPT 09 - GPO DE EQUIPOS (LAPS Y BITLOCKER)'
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
$dom = Get-ADDomain
$dominioDN = $dom.DistinguishedName
$dnsDominio = $dom.DNSRoot
Write-Ok "Dominio $dnsDominio."

$ouEquipos = "OU=Equipos,OU=GestionNorte,$dominioDN"
if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouEquipos'" -ErrorAction SilentlyContinue)) {
    Write-Fallo "No existe $ouEquipos. Ejecuta antes el script 04."
    Stop-Transcript | Out-Null
    exit 3
}
Write-Ok 'Existe la OU de equipos (script 04).'

# --- 2. Esquema y permisos de Windows LAPS -----------------------------------------------
Write-Titulo '2. WINDOWS LAPS: ESQUEMA Y PERMISOS'
Write-Info 'Windows LAPS viene integrado en Windows Server 2025. No se instala nada.'
try {
    Update-LapsADSchema -Confirm:$false
    Write-Ok 'Esquema de AD ampliado para Windows LAPS (o ya estaba).'
}
catch {
    Write-Aviso "Update-LapsADSchema: $($_.Exception.Message)"
}

Set-LapsADComputerSelfPermission -Identity $ouEquipos
Write-Ok "Los equipos de OU=Equipos pueden escribir su propia contraseña LAPS."

# --- 3. GPO y enlace -------------------------------------------------------------------------
Write-Titulo '3. GPO Y ENLACE'
$gpo = Get-GPO -Name $NombreGPO -ErrorAction SilentlyContinue
if ($gpo) { Write-Info "Ya existe la GPO $NombreGPO. Se actualizan sus valores." }
else {
    $gpo = New-GPO -Name $NombreGPO -Comment 'LAPS y copia de claves BitLocker en AD (script 09)'
    Write-Ok "GPO creada: $NombreGPO"
}

$enlaces = (Get-GPInheritance -Target $ouEquipos).GpoLinks | Where-Object { $_.DisplayName -eq $NombreGPO }
if ($enlaces) { Write-Info "La GPO ya está enlazada a $ouEquipos." }
else {
    New-GPLink -Name $NombreGPO -Target $ouEquipos -LinkEnabled Yes | Out-Null
    Write-Ok "GPO enlazada a $ouEquipos."
}

# --- 4. Ajustes de la GPO ----------------------------------------------------------------------
Write-Titulo '4. AJUSTES DE LA GPO'

# Windows LAPS (valores de directiva en HKLM\Software\Microsoft\Policies\LAPS)
$laps = 'HKLM\Software\Microsoft\Policies\LAPS'
Set-GPRegistryValue -Name $NombreGPO -Key $laps -ValueName 'BackupDirectory'            -Type DWord -Value 2    # 2 = Active Directory
Set-GPRegistryValue -Name $NombreGPO -Key $laps -ValueName 'PasswordLength'             -Type DWord -Value 20
Set-GPRegistryValue -Name $NombreGPO -Key $laps -ValueName 'PasswordAgeDays'            -Type DWord -Value 30
Set-GPRegistryValue -Name $NombreGPO -Key $laps -ValueName 'PasswordComplexity'         -Type DWord -Value 4    # 4 = mayúsculas, minúsculas, números y símbolos
Set-GPRegistryValue -Name $NombreGPO -Key $laps -ValueName 'PostAuthenticationActions'  -Type DWord -Value 3    # 3 = cambiar contraseña y cerrar sesión
Set-GPRegistryValue -Name $NombreGPO -Key $laps -ValueName 'PostAuthenticationResetDelay' -Type DWord -Value 8
Write-Ok 'LAPS: contraseña de 20 caracteres, rotación cada 30 días, guardada en AD.'

# BitLocker: copia obligatoria de la clave de recuperación en AD
$fve = 'HKLM\Software\Policies\Microsoft\FVE'
Set-GPRegistryValue -Name $NombreGPO -Key $fve -ValueName 'OSActiveDirectoryBackup'        -Type DWord -Value 1
Set-GPRegistryValue -Name $NombreGPO -Key $fve -ValueName 'OSRequireActiveDirectoryBackup' -Type DWord -Value 1
Set-GPRegistryValue -Name $NombreGPO -Key $fve -ValueName 'OSActiveDirectoryInfoToStore'   -Type DWord -Value 1  # 1 = clave de recuperación
Set-GPRegistryValue -Name $NombreGPO -Key $fve -ValueName 'ActiveDirectoryBackup'          -Type DWord -Value 1
Set-GPRegistryValue -Name $NombreGPO -Key $fve -ValueName 'RequireActiveDirectoryBackup'   -Type DWord -Value 1
Write-Ok 'BitLocker: la clave de recuperación se guarda en AD antes de cifrar.'
Write-Aviso 'Pendiente de verificar en gpedit (Cifrado de unidad BitLocker) que los valores se ven como "Habilitada".'

# --- 5. Verificación -----------------------------------------------------------------------------------
Write-Titulo '5. VERIFICACIÓN'

Write-Host 'GPO y enlaces:' -ForegroundColor White
Get-GPO -Name $NombreGPO | Format-List DisplayName, GpoStatus, CreationTime, ModificationTime
Get-GPInheritance -Target $ouEquipos | Select-Object -ExpandProperty GpoLinks |
    Where-Object { $_.DisplayName -eq $NombreGPO } | Format-Table DisplayName, Enabled, Enforced -AutoSize

Write-Host 'Valores LAPS:' -ForegroundColor White
Get-GPRegistryValue -Name $NombreGPO -Key $laps | Format-Table ValueName, Value -AutoSize

Write-Host 'Valores BitLocker:' -ForegroundColor White
Get-GPRegistryValue -Name $NombreGPO -Key $fve | Format-Table ValueName, Value -AutoSize

Write-Host 'Esquema LAPS y permisos en la OU:' -ForegroundColor White
$esquema = Get-ADObject -Filter "Name -like 'ms-LAPS-Password*'" -SearchBase (Get-ADRootDSE).schemaNamingContext -ErrorAction SilentlyContinue
if ($esquema) { Write-Ok "Atributos LAPS en el esquema: $($esquema.Count)." }
else { Write-Aviso 'No se encuentran los atributos LAPS en el esquema.' }

Write-Host ''
Write-Ok "Script 09 finalizado. Log guardado en: $fichLog"
Write-Info 'PENDIENTE DE VERIFICAR: en cli01 (gpupdate /force y Get-LapsADPassword) y la clave BitLocker en AD.'
Stop-Transcript | Out-Null

