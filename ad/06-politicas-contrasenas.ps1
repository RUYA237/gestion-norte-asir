<#
.SYNOPSIS
    Script 06 - Política de contraseñas y bloqueo de cuentas del dominio, con política específica para administradores.

.DESCRIPCION
    Proyecto Intermodular 2º ASIR - Consultoría Kalima / Cliente: Gestión Norte
    Módulo: Administración de Sistemas Operativos
    Autor: Arian

    Qué hace, en orden:
      1. Comprueba privilegios, que es controlador de dominio y que el módulo ActiveDirectory funciona.
      2. Fija la política de contraseñas y bloqueo del dominio (Default Domain Policy):
         longitud mínima 12, complejidad, historial de 24, caducidad 90 días,
         bloqueo tras 5 intentos fallidos durante 30 minutos.
      3. Crea una política de contraseñas granular (PSO) para los administradores del dominio:
         longitud mínima 15, bloqueo tras 3 intentos, caducidad 60 días.
      4. Verifica la política resultante para un usuario normal y para la cuenta Administrador.

    POR QUÉ:
      - Longitud 12 y complejidad: requisito mínimo de la política de seguridad del proyecto.
      - Bloqueo: frena la fuerza bruta contra cuentas. 5 intentos en el dominio y 3 en las cuentas
        privilegiadas, porque un atacante que llega a una cuenta de administrador tiene todo el dominio.
      - PSO para administradores: una contraseña más larga y bloqueo más estricto sin imponerlo a
        los 150 usuarios. Se aplica a Admins. del dominio por SID (-512), así funciona en cualquier idioma.
      - Historial y caducidad: evitan reutilizar contraseñas. Los usuarios del CSV tienen que cambiarla
        igualmente en el primer inicio de sesión (script 05).

    LIMITACIÓN: la política de dominio se aplica desde Default Domain Policy. No tocamos otra GPO
    para evitar que dos GPO se pisen. Se verifica con Get-ADDefaultDomainPasswordPolicy.

.EJEMPLOS
    .\06-politicas-contrasenas.ps1

.NOTAS
    Ejecutar en dc1 con GESTIONNORTE\Administrador, después del script 05.
    Haz snapshot "dc1-pre-politicas" antes de ejecutarlo.
#>

[CmdletBinding()]
param(
    [string]$Dominio = 'ad.gestionnorte.es',
    [string]$NombrePSO = 'PSO-Administradores'
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

# --- 1. Privilegios, log y precondiciones ---------------------------------------
$identidad = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identidad)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Fallo 'Este script necesita ejecutarse como Administrador.'
    exit 1
}

$carpetaEvidencias = 'C:\Evidencias'
if (-not (Test-Path $carpetaEvidencias)) { New-Item -Path $carpetaEvidencias -ItemType Directory -Force | Out-Null }
$marca   = Get-Date -Format 'yyyyMMdd-HHmmss'
$fichLog = Join-Path $carpetaEvidencias "06-politicas-$($env:COMPUTERNAME.ToLower())-$marca.log"
Start-Transcript -Path $fichLog -Force | Out-Null

Write-Titulo 'SCRIPT 06 - POLÍTICA DE CONTRASEÑAS Y BLOQUEO'
Write-Info "Ejecutado por : $($identidad.Name)"
Write-Info "Fecha y hora  : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
Write-Info "Log           : $fichLog"

Write-Titulo '1. PRECONDICIONES'
$rol = (Get-CimInstance Win32_ComputerSystem).DomainRole
if ($rol -lt 4) {
    Write-Fallo 'Este equipo no es controlador de dominio. Ejecuta antes los scripts 02 a 05.'
    Stop-Transcript | Out-Null
    exit 2
}
Import-Module ActiveDirectory -ErrorAction Stop
$dom = Get-ADDomain
$domainSid = $dom.DomainSID.Value
Write-Ok "Controlador de dominio. Dominio: $($dom.DNSRoot)"

# --- 2. Política de contraseñas y bloqueo del dominio ----------------------------
Write-Titulo '2. POLÍTICA DE DOMINIO (Default Domain Policy)'
$politica = @{
    Identity                    = $Dominio
    MinPasswordLength           = 12
    PasswordHistoryCount        = 24
    MaxPasswordAge              = [TimeSpan]::FromDays(90)
    MinPasswordAge              = [TimeSpan]::FromDays(1)
    ComplexityEnabled           = $true
    ReversibleEncryptionEnabled = $false
    LockoutThreshold            = 5
    LockoutDuration             = [TimeSpan]::FromMinutes(30)
    LockoutObservationWindow    = [TimeSpan]::FromMinutes(30)
}
Set-ADDefaultDomainPasswordPolicy @politica
Write-Ok 'Política de dominio aplicada: longitud 12, complejidad, historial 24, caducidad 90 días, bloqueo a los 5 fallos (30 min).'

# --- 3. Política granular para administradores (PSO) ---------------------------------
Write-Titulo '3. POLÍTICA GRANULAR PARA ADMINISTRADORES (PSO)'
$gruposAdmins = Get-ADGroup -Identity (New-Object System.Security.Principal.SecurityIdentifier("$domainSid-512"))
Write-Info "Grupo administradores del dominio (SID -512): $($gruposAdmins.SamAccountName)"

$pso = Get-ADFineGrainedPasswordPolicy -Filter "Name -eq '$NombrePSO'" -ErrorAction SilentlyContinue
if ($pso) {
    Write-Info "Ya existe la política $NombrePSO. Se actualizan sus valores."
    Set-ADFineGrainedPasswordPolicy -Identity $NombrePSO `
        -MinPasswordLength 15 -PasswordHistoryCount 24 `
        -MaxPasswordAge ([TimeSpan]::FromDays(60)) -MinPasswordAge ([TimeSpan]::FromDays(1)) `
        -ComplexityEnabled $true -ReversibleEncryptionEnabled $false `
        -LockoutThreshold 3 -LockoutDuration ([TimeSpan]::FromMinutes(30)) `
        -LockoutObservationWindow ([TimeSpan]::FromMinutes(30))
}
else {
    New-ADFineGrainedPasswordPolicy -Name $NombrePSO -Precedence 10 `
        -MinPasswordLength 15 -PasswordHistoryCount 24 `
        -MaxPasswordAge ([TimeSpan]::FromDays(60)) -MinPasswordAge ([TimeSpan]::FromDays(1)) `
        -ComplexityEnabled $true -ReversibleEncryptionEnabled $false `
        -LockoutThreshold 3 -LockoutDuration ([TimeSpan]::FromMinutes(30)) `
        -LockoutObservationWindow ([TimeSpan]::FromMinutes(30)) `
        -ProtectedFromAccidentalDeletion $true
    Write-Ok "Política creada: $NombrePSO (precedencia 10, longitud 15, bloqueo a los 3 fallos)."
}

$aplicada = (Get-ADFineGrainedPasswordPolicy -Identity $NombrePSO -Properties AppliesTo).AppliesTo -contains $gruposAdmins.DistinguishedName
if ($aplicada) { Write-Info "$NombrePSO ya se aplica a $($gruposAdmins.SamAccountName)." }
else {
    Add-ADFineGrainedPasswordPolicySubject -Identity $NombrePSO -Subjects $gruposAdmins.DistinguishedName
    Write-Ok "$NombrePSO aplicada a $($gruposAdmins.SamAccountName)."
}

# --- 4. Verificación ---------------------------------------------------------------
Write-Titulo '4. VERIFICACIÓN'

Write-Host 'Política de dominio:' -ForegroundColor White
Get-ADDefaultDomainPasswordPolicy -Identity $Dominio |
    Format-List ComplexityEnabled, MinPasswordLength, PasswordHistoryCount, MaxPasswordAge, MinPasswordAge, LockoutThreshold, LockoutDuration, LockoutObservationWindow

Write-Host 'Políticas granulares (PSO):' -ForegroundColor White
Get-ADFineGrainedPasswordPolicy -Filter * -Properties AppliesTo |
    Format-List Name, Precedence, MinPasswordLength, LockoutThreshold, AppliesTo

$admin = Get-ADUser -Identity (New-Object System.Security.Principal.SecurityIdentifier("$domainSid-500"))
Write-Host "Política resultante para $($admin.SamAccountName) (cuenta de administrador integrada):" -ForegroundColor White
Get-ADUserResultantPasswordPolicy -Identity $admin.SamAccountName |
    Format-List Name, MinPasswordLength, LockoutThreshold, MaxPasswordAge

$ouUsuarios = "OU=Usuarios,OU=GestionNorte,$($dom.DistinguishedName)"
$usuario = Get-ADUser -Filter * -SearchBase $ouUsuarios | Select-Object -First 1
if ($usuario) {
    Write-Host "Política resultante para un usuario normal ($($usuario.SamAccountName)):" -ForegroundColor White
    Get-ADUserResultantPasswordPolicy -Identity $usuario.SamAccountName |
        Format-List Name, MinPasswordLength, LockoutThreshold, MaxPasswordAge
}
else { Write-Aviso 'No hay usuarios en OU=Usuarios. Ejecuta antes el script 05.' }

Write-Host ''
Write-Ok "Script 06 finalizado. Log guardado en: $fichLog"
Write-Info 'SIGUIENTE PASO: captura 18 (verificación) y prueba de bloqueo con un usuario de prueba.'
Stop-Transcript | Out-Null
