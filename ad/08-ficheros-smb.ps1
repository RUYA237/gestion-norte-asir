<#
.SYNOPSIS
    Script 08 - Servicio de ficheros en dc1: carpetas por departamento, permisos AGDLP y recursos compartidos con SMB cifrado.

.DESCRIPCION
    Proyecto Intermodular 2º ASIR - Consultoría Kalima / Cliente: Gestión Norte
    Módulo: Administración de Sistemas Operativos
    Autor: Arian

    Qué hace, en orden:
      1. Comprueba privilegios, que es controlador de dominio y que existen los grupos DL_Fichero_* (script 05).
      2. Instala el rol Servidor de archivos.
      3. Endurece SMB: desactiva SMBv1 y exige firma.
      4. Crea C:\Datos\<Departamento> para Laboral, Fiscal, Administracion y Atencion.
      5. Asigna permisos NTFS sin herencia: SYSTEM y Administradores control total,
         DL_Fichero_<Dep>_RW modificar y DL_Fichero_<Dep>_RO lectura.
      6. Publica cada carpeta como recurso compartido con cifrado SMB (EncryptData) y enumeración
         basada en acceso (el usuario solo ve las carpetas a las que tiene permiso).
      7. Verifica y deja la evidencia en el log.

    POR QUÉ:
      - AGDLP: el permiso se da SIEMPRE al grupo local de dominio (DL_), nunca a usuarios sueltos.
        Cambiar quién accede a Fiscal es añadir o quitar un GG_ en un único sitio.
      - SMB cifrado: los datos laborales, fiscales y bancarios (RGPD) no viajan en claro por la LAN
        ni por la VPN entre sedes. Cifrado por recurso, no global, para poder medir y documentar.
      - Sin herencia y enumeración basada en acceso: ningún usuario ve ni lista carpetas ajenas.
      - Sustituye el sistema actual del cliente (ficheros por email y USB).

    LÍMITES (a documentar en la memoria):
      - En producción el servicio de ficheros NO debería estar en un controlador de dominio. En el
        laboratorio lo da dc1 por restricción de recursos (decisión del inventario de VMs).
        Propuesto: servidor de ficheros dedicado o NAS.
      - C:\Datos está en el disco del sistema. Propuesto: volumen de datos separado.
      - La prueba de acceso con usuario real y la comprobación de cifrado desde cliente
        quedan pendientes hasta tener cli01 unido al dominio.

.EJEMPLOS
    .\08-ficheros-smb.ps1
    .\08-ficheros-smb.ps1 -Raiz 'D:\Datos'

.NOTAS
    Ejecutar en dc1 con GESTIONNORTE\Administrador, después de los scripts 05 y 06.
    Haz snapshot "dc1-pre-ficheros" antes de ejecutarlo.
#>

[CmdletBinding()]
param(
    [string]$Raiz = 'C:\Datos'
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

# --- 1. Privilegios, log y precondiciones ------------------------------------------
$identidad = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identidad)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Fallo 'Este script necesita ejecutarse como Administrador.'
    exit 1
}

$carpetaEvidencias = 'C:\Evidencias'
if (-not (Test-Path $carpetaEvidencias)) { New-Item -Path $carpetaEvidencias -ItemType Directory -Force | Out-Null }
$marca   = Get-Date -Format 'yyyyMMdd-HHmmss'
$fichLog = Join-Path $carpetaEvidencias "08-ficheros-$($env:COMPUTERNAME.ToLower())-$marca.log"
Start-Transcript -Path $fichLog -Force | Out-Null

Write-Titulo 'SCRIPT 08 - FICHEROS CON SMB CIFRADO'
Write-Info "Ejecutado por : $($identidad.Name)"
Write-Info "Fecha y hora  : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
Write-Info "Carpeta raíz  : $Raiz"
Write-Info "Log           : $fichLog"

Write-Titulo '1. PRECONDICIONES'
$rol = (Get-CimInstance Win32_ComputerSystem).DomainRole
if ($rol -lt 4) {
    Write-Fallo 'Este equipo no es controlador de dominio. Ejecuta antes los scripts 02 a 05.'
    Stop-Transcript | Out-Null
    exit 2
}
Import-Module ActiveDirectory -ErrorAction Stop
$netbios = (Get-ADDomain).NetBIOSName
Write-Ok "Dominio $netbios."

$departamentos = 'Laboral','Fiscal','Administracion','Atencion'
$faltan = 0
foreach ($dep in $departamentos) {
    foreach ($sufijo in 'RW','RO') {
        $g = "DL_Fichero_${dep}_$sufijo"
        if (-not (Get-ADGroup -Filter "SamAccountName -eq '$g'" -ErrorAction SilentlyContinue)) {
            Write-Fallo "No existe el grupo $g. Ejecuta antes el script 05."
            $faltan++
        }
    }
}
if ($faltan -gt 0) { Stop-Transcript | Out-Null; exit 3 }
Write-Ok 'Existen los 8 grupos DL_Fichero_* (script 05).'

# Nombres independientes del idioma del sistema
$sidAdmins = New-Object Security.Principal.SecurityIdentifier('S-1-5-32-544')
$sidSystem = New-Object Security.Principal.SecurityIdentifier('S-1-5-18')
$nombreAdmins = $sidAdmins.Translate([Security.Principal.NTAccount]).Value
Write-Info "Grupo Administradores del sistema: $nombreAdmins"

# --- 2. Rol Servidor de archivos ------------------------------------------------------------
Write-Titulo '2. ROL SERVIDOR DE ARCHIVOS'
$res = Install-WindowsFeature -Name FS-FileServer
if ($res.Success) { Write-Ok "Rol Servidor de archivos presente. Reinicio necesario: $($res.RestartNeeded)" }
else { Write-Fallo 'La instalación del rol ha fallado.'; Stop-Transcript | Out-Null; exit 4 }

# --- 3. Endurecimiento de SMB ------------------------------------------------------------------
Write-Titulo '3. ENDURECIMIENTO DE SMB'
Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
Set-SmbServerConfiguration -RequireSecuritySignature $true -Force
Get-SmbServerConfiguration | Format-List EnableSMB1Protocol, EnableSMB2Protocol, RequireSecuritySignature, EncryptData
Write-Ok 'SMBv1 desactivado y firma SMB obligatoria.'

# --- 4 y 5. Carpetas y permisos NTFS -----------------------------------------------------------------
Write-Titulo '4. CARPETAS Y PERMISOS NTFS (AGDLP)'

function Nueva-Regla {
    param($Identidad, [string]$Derechos)
    if ($Identidad -is [string]) { $Identidad = New-Object Security.Principal.NTAccount($Identidad) }
    New-Object Security.AccessControl.FileSystemAccessRule(
        $Identidad, $Derechos, 'ContainerInherit,ObjectInherit', 'None', 'Allow')
}

if (-not (Test-Path $Raiz)) { New-Item -Path $Raiz -ItemType Directory -Force | Out-Null; Write-Ok "Carpeta raíz creada: $Raiz" }

foreach ($dep in $departamentos) {
    $ruta = Join-Path $Raiz $dep
    if (-not (Test-Path $ruta)) { New-Item -Path $ruta -ItemType Directory -Force | Out-Null; Write-Ok "Carpeta creada: $ruta" }
    else { Write-Info "Ya existe la carpeta: $ruta" }

    $acl = Get-Acl -Path $ruta
    $acl.SetAccessRuleProtection($true, $false)      # sin herencia y sin copiar permisos heredados
    foreach ($regla in @($acl.Access)) { [void]$acl.RemoveAccessRule($regla) }
    $acl.AddAccessRule((Nueva-Regla $sidSystem 'FullControl'))
    $acl.AddAccessRule((Nueva-Regla $sidAdmins 'FullControl'))
    $acl.AddAccessRule((Nueva-Regla "$netbios\DL_Fichero_${dep}_RW" 'Modify'))
    $acl.AddAccessRule((Nueva-Regla "$netbios\DL_Fichero_${dep}_RO" 'ReadAndExecute'))
    Set-Acl -Path $ruta -AclObject $acl
    Write-Ok "Permisos NTFS aplicados en $ruta (RW: modificar, RO: lectura)."
}

# --- 6. Recursos compartidos con SMB cifrado ------------------------------------------------------------
Write-Titulo '5. RECURSOS COMPARTIDOS CON CIFRADO SMB'
foreach ($dep in $departamentos) {
    $ruta = Join-Path $Raiz $dep
    $existe = Get-SmbShare -Name $dep -ErrorAction SilentlyContinue
    if ($existe) {
        Set-SmbShare -Name $dep -EncryptData $true -FolderEnumerationMode AccessBased -Force
        Write-Info "Ya existía el recurso $dep. Se asegura cifrado y enumeración basada en acceso."
    }
    else {
        New-SmbShare -Name $dep -Path $ruta `
            -EncryptData $true -FolderEnumerationMode AccessBased `
            -FullAccess $nombreAdmins `
            -ChangeAccess "$netbios\DL_Fichero_${dep}_RW" `
            -ReadAccess   "$netbios\DL_Fichero_${dep}_RO" `
            -Description  "Ficheros de $dep (AGDLP, SMB cifrado)" | Out-Null
        Write-Ok "Recurso compartido creado: \\$($env:COMPUTERNAME)\$dep"
    }
}

# --- 7. Verificación -----------------------------------------------------------------------------------------
Write-Titulo '6. VERIFICACIÓN'

Write-Host 'Recursos compartidos:' -ForegroundColor White
Get-SmbShare | Where-Object { $_.Name -in $departamentos } |
    Format-Table Name, Path, EncryptData, FolderEnumerationMode -AutoSize

Write-Host 'Permisos del recurso (compartido):' -ForegroundColor White
foreach ($dep in $departamentos) {
    Get-SmbShareAccess -Name $dep | Format-Table Name, AccountName, AccessControlType, AccessRight -AutoSize
}

Write-Host 'Permisos NTFS (sin herencia):' -ForegroundColor White
foreach ($dep in $departamentos) {
    $ruta = Join-Path $Raiz $dep
    Write-Host "  $ruta" -ForegroundColor Gray
    (Get-Acl $ruta).Access |
        Format-Table IdentityReference, FileSystemRights, AccessControlType, IsInherited -AutoSize
}

$sinCifrar = @(Get-SmbShare | Where-Object { $_.Name -in $departamentos -and -not $_.EncryptData })
if ($sinCifrar.Count -eq 0) { Write-Ok 'Los 4 recursos tienen EncryptData activado.' }
else { Write-Fallo "Recursos sin cifrado: $($sinCifrar.Name -join ', ')" }

Write-Host ''
Write-Ok "Script 08 finalizado. Log guardado en: $fichLog"
Write-Info 'PENDIENTE DE VERIFICAR: acceso real de un usuario desde cli01 y Get-SmbConnection (Encrypted = True).'
Stop-Transcript | Out-Null
