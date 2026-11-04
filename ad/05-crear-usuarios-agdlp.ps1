<#
.SYNOPSIS
    Script 05 - Grupos AGDLP y carga de usuarios desde CSV.

.DESCRIPCION
    Proyecto Intermodular 2º ASIR - Consultoría Kalima / Cliente: Gestión Norte
    Módulo: Administración de Sistemas Operativos
    Autor: Arian

    Qué hace, en orden:
      1. Comprueba privilegios, que es controlador de dominio y que existen las OU del script 04.
      2. Lee usuarios.csv y valida cabeceras, campos, sedes, departamentos y duplicados.
      3. Crea los grupos globales GG_<Sede>_<Departamento> en OU=Globales.
      4. Crea los grupos locales de dominio DL_Fichero_<Departamento>_RW y _RO en OU=Recursos
         y anida en cada DL_..._RW los GG de sus tres sedes (cadena A-G-DL-P).
      5. Crea los usuarios en OU=<Departamento>,OU=<Sede>,OU=Usuarios, los añade a su GG_
         y les asigna una contraseña inicial aleatoria que obliga a cambiarla al primer inicio.
      6. Verificación: recuentos en AD frente al CSV y pertenencia de grupos.

    POR QUÉ:
      - AGDLP: los usuarios van a grupos globales (por función y sede), los globales se anidan
        en locales de dominio (por recurso) y los permisos se dan siempre al local de dominio.
        Así, un permiso sobre una carpeta se gestiona en un único sitio.
      - Contraseñas: se generan aleatorias por usuario. Nunca van en el script, ni en Git,
        ni en el log de evidencias. Se guardan en C:\Seguro (fuera del repositorio) para
        entregarlas al usuario y borrarlas después.
      - Idempotente: si un usuario o grupo ya existe, lo indica y no lo duplica.

.EJEMPLOS
    .\05-crear-usuarios-agdlp.ps1
    .\05-crear-usuarios-agdlp.ps1 -Csv 'C:\Scripts\usuarios.csv'

.NOTAS
    Ejecutar en dc1 con GESTIONNORTE\Administrador, después de los scripts 02, 03 y 04.
    Haz snapshot "dc1-pre-usuarios" antes de ejecutarlo.
#>

[CmdletBinding()]
param(
    [string]$Csv            = (Join-Path $PSScriptRoot 'usuarios.csv'),
    [string]$RaizOU         = 'GestionNorte',
    [string]$DominioDNS     = 'ad.gestionnorte.es',
    [string]$CarpetaSeguro  = 'C:\Seguro'
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

# --- 1. Privilegios, log y precondiciones --------------------------------------
$identidad = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identidad)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Fallo 'Este script necesita ejecutarse como Administrador.'
    exit 1
}

$carpetaEvidencias = 'C:\Evidencias'
if (-not (Test-Path $carpetaEvidencias)) { New-Item -Path $carpetaEvidencias -ItemType Directory -Force | Out-Null }
$marca   = Get-Date -Format 'yyyyMMdd-HHmmss'
$fichLog = Join-Path $carpetaEvidencias "05-usuarios-$($env:COMPUTERNAME.ToLower())-$marca.log"
Start-Transcript -Path $fichLog -Force | Out-Null

Write-Titulo 'SCRIPT 05 - GRUPOS AGDLP Y USUARIOS DESDE CSV'
Write-Info "Ejecutado por : $($identidad.Name)"
Write-Info "Fecha y hora  : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
Write-Info "CSV           : $Csv"
Write-Info "Log           : $fichLog"

Write-Titulo '1. PRECONDICIONES'
$rol = (Get-CimInstance Win32_ComputerSystem).DomainRole
if ($rol -lt 4) {
    Write-Fallo 'Este equipo no es controlador de dominio. Ejecuta antes los scripts 02, 03 y 04.'
    Stop-Transcript | Out-Null
    exit 2
}
Import-Module ActiveDirectory -ErrorAction Stop
$dominioDN = (Get-ADDomain).DistinguishedName
Write-Ok "Controlador de dominio. Dominio: $dominioDN"

$rutaUsuarios = "OU=Usuarios,OU=$RaizOU,$dominioDN"
$rutaGlobales = "OU=Globales,OU=Grupos,OU=$RaizOU,$dominioDN"
$rutaRecursos = "OU=Recursos,OU=Grupos,OU=$RaizOU,$dominioDN"

foreach ($ruta in $rutaUsuarios, $rutaGlobales, $rutaRecursos) {
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ruta'" -ErrorAction SilentlyContinue)) {
        Write-Fallo "No existe la OU $ruta. Ejecuta antes el script 04."
        Stop-Transcript | Out-Null
        exit 3
    }
}
Write-Ok 'Las OU de usuarios y grupos existen (script 04).'

if (-not (Test-Path $Csv)) {
    Write-Fallo "No se encuentra el CSV: $Csv"
    Stop-Transcript | Out-Null
    exit 4
}

# --- 2. Lectura y validación del CSV ---------------------------------------------
Write-Titulo '2. VALIDACIÓN DEL CSV'
$filas = @(Import-Csv -Path $Csv -Delimiter ';' -Encoding UTF8)
$cabecerasObligatorias = 'Nombre','Apellidos','Usuario','Sede','Departamento','Puesto'
$cabecerasCsv = $filas[0].PSObject.Properties.Name
$faltan = @($cabecerasObligatorias | Where-Object { $_ -notin $cabecerasCsv })
if ($faltan.Count -gt 0) {
    Write-Fallo "Faltan columnas en el CSV: $($faltan -join ', ')"
    Stop-Transcript | Out-Null
    exit 5
}

$sedesValidas = 'Zaragoza','Huesca','Teruel'
$depsValidos  = 'Laboral','Fiscal','Administracion','Atencion'
$erroresCsv = 0
$numFila = 1
foreach ($f in $filas) {
    $numFila++
    foreach ($c in $cabecerasObligatorias) {
        if ([string]::IsNullOrWhiteSpace($f.$c)) { Write-Fallo "Fila $numFila sin valor en '$c'."; $erroresCsv++ }
    }
    if ($f.Sede -notin $sedesValidas)        { Write-Fallo "Fila ${numFila}: sede no válida '$($f.Sede)'."; $erroresCsv++ }
    if ($f.Departamento -notin $depsValidos) { Write-Fallo "Fila ${numFila}: departamento no válido '$($f.Departamento)'."; $erroresCsv++ }
    if ($f.Usuario -notmatch '^[a-z0-9.]{1,16}$') { Write-Fallo "Fila ${numFila}: usuario no válido '$($f.Usuario)'."; $erroresCsv++ }
}
$duplicados = @($filas | Group-Object Usuario | Where-Object { $_.Count -gt 1 })
if ($duplicados.Count -gt 0) {
    Write-Fallo "Usuarios duplicados en el CSV: $($duplicados.Name -join ', ')"
    $erroresCsv++
}
if ($erroresCsv -gt 0) {
    Write-Fallo "El CSV tiene $erroresCsv error(es). No se crea nada."
    Stop-Transcript | Out-Null
    exit 6
}
Write-Ok "CSV válido: $($filas.Count) usuarios."

Write-Info 'Recuento por sede:'
$filas | Group-Object Sede | Sort-Object Name | ForEach-Object { Write-Info "  $($_.Name): $($_.Count)" }
Write-Info 'Recuento por departamento:'
$filas | Group-Object Departamento | Sort-Object Name | ForEach-Object { Write-Info "  $($_.Name): $($_.Count)" }

# --- 3. Grupos globales GG_ (por sede y departamento) ----------------------------
function Asegurar-Grupo {
    param([string]$Nombre, [string]$Ambito, [string]$Ruta, [string]$Descripcion)
    $existe = Get-ADGroup -Filter "SamAccountName -eq '$Nombre'" -ErrorAction SilentlyContinue
    if ($existe) { Write-Info "Ya existe el grupo $Nombre" }
    else {
        New-ADGroup -Name $Nombre -SamAccountName $Nombre -GroupScope $Ambito `
            -GroupCategory Security -Path $Ruta -Description $Descripcion
        Write-Ok "Grupo creado: $Nombre ($Ambito)"
    }
}

function Asegurar-Miembro {
    param([string]$Grupo, [string]$Miembro)
    $ya = Get-ADGroupMember -Identity $Grupo -ErrorAction SilentlyContinue |
          Where-Object { $_.SamAccountName -eq $Miembro }
    if ($ya) { Write-Info "$Miembro ya es miembro de $Grupo" }
    else {
        Add-ADGroupMember -Identity $Grupo -Members $Miembro
        Write-Ok "$Miembro añadido a $Grupo"
    }
}

Write-Titulo '3. GRUPOS GLOBALES (GG_)'
$sedesValidas | ForEach-Object {
    $sede = $_
    $depsValidos | ForEach-Object {
        $dep = $_
        Asegurar-Grupo -Nombre "GG_${sede}_$dep" -Ambito Global -Ruta $rutaGlobales `
            -Descripcion "Usuarios de $dep en $sede (global, AGDLP)"
    }
}

# --- 4. Grupos locales de dominio DL_ (permiso sobre recurso) y anidación ----------
Write-Titulo '4. GRUPOS LOCALES DE DOMINIO (DL_) Y ANIDACIÓN'
Write-Info 'Cadena: usuario -> GG_ (global) -> DL_ (local de dominio) -> permiso en la carpeta.'
foreach ($dep in $depsValidos) {
    Asegurar-Grupo -Nombre "DL_Fichero_${dep}_RW" -Ambito DomainLocal -Ruta $rutaRecursos `
        -Descripcion "Permiso Modificar sobre la carpeta de $dep (se asigna en el servidor de ficheros)"
    Asegurar-Grupo -Nombre "DL_Fichero_${dep}_RO" -Ambito DomainLocal -Ruta $rutaRecursos `
        -Descripcion "Permiso Lectura sobre la carpeta de $dep (se asigna en el servidor de ficheros)"
    foreach ($sede in $sedesValidas) {
        Asegurar-Miembro -Grupo "DL_Fichero_${dep}_RW" -Miembro "GG_${sede}_$dep"
    }
}

# --- 5. Usuarios -------------------------------------------------------------------
Write-Titulo '5. USUARIOS'

function New-PasswordInicial {
    $juegos = @(
        'ABCDEFGHJKLMNPQRSTUVWXYZ',
        'abcdefghijkmnopqrstuvwxyz',
        '23456789',
        '!#%+*-_=?'
    )
    $todos = -join $juegos
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    function Elegir-Caracter {
        param([string]$Conjunto)
        $b = New-Object byte[] 4
        $rng.GetBytes($b)
        return $Conjunto[[BitConverter]::ToUInt32($b, 0) % $Conjunto.Length]
    }
    $chars = New-Object System.Collections.Generic.List[char]
    foreach ($j in $juegos) { $chars.Add((Elegir-Caracter $j)) }
    while ($chars.Count -lt 14) { $chars.Add((Elegir-Caracter $todos)) }
    $mezcla = $chars | Sort-Object { Get-Random }
    $rng.Dispose()
    return (-join $mezcla)
}

# Carpeta fuera de Git y de evidencias, solo accesible por SYSTEM y Administradores
if (-not (Test-Path $CarpetaSeguro)) {
    New-Item -Path $CarpetaSeguro -ItemType Directory -Force | Out-Null
    icacls $CarpetaSeguro /inheritance:r /grant:r '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' | Out-Null
    Write-Ok "Carpeta de contraseñas creada con permisos restringidos: $CarpetaSeguro"
}
$fichPass = Join-Path $CarpetaSeguro "contrasenas-iniciales-$marca.csv"
$listaPass = New-Object System.Collections.Generic.List[object]

$creados  = 0
$omitidos = 0
$errores  = 0

try {
    foreach ($f in $filas) {
        $sam = $f.Usuario.Trim()
        $nombreCompleto = "$($f.Nombre) $($f.Apellidos)"
        $ruta = "OU=$($f.Departamento),OU=$($f.Sede),$rutaUsuarios"

        $existe = Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue
        if ($existe) {
            Write-Info "Ya existe el usuario $sam. Se omite."
            $omitidos++
            continue
        }

        $pwd = New-PasswordInicial
        try {
            New-ADUser -Name $nombreCompleto -GivenName $f.Nombre -Surname $f.Apellidos `
                -DisplayName $nombreCompleto -SamAccountName $sam `
                -UserPrincipalName "$sam@$DominioDNS" -Path $ruta `
                -Office $f.Sede -Department $f.Departamento -Title $f.Puesto `
                -Description "Gestión Norte - $($f.Sede)" `
                -AccountPassword (ConvertTo-SecureString $pwd -AsPlainText -Force) `
                -ChangePasswordAtLogon $true -Enabled $true
            Add-ADGroupMember -Identity "GG_$($f.Sede)_$($f.Departamento)" -Members $sam
            $listaPass.Add([pscustomobject]@{
                Usuario          = $sam
                NombreCompleto   = $nombreCompleto
                Sede             = $f.Sede
                Departamento     = $f.Departamento
                ContrasenaInicial = $pwd
            })
            Write-Ok "Usuario creado: $sam ($($f.Sede) / $($f.Departamento))"
            $creados++
        }
        catch {
            Write-Fallo "Error con ${sam}: $($_.Exception.Message)"
            $errores++
        }
    }
}
finally {
    if ($listaPass.Count -gt 0) {
        $listaPass | Export-Csv -Path $fichPass -Delimiter ';' -NoTypeInformation -Encoding UTF8
        Write-Aviso "Contraseñas iniciales guardadas en: $fichPass"
        Write-Aviso 'NO las copies a Git, a evidencias ni a capturas. Entrégalas y borra el fichero.'
    }
}

Write-Info "Resumen de usuarios: creados $creados, omitidos (ya existían) $omitidos, errores $errores."

# --- 6. Verificación -----------------------------------------------------------------
Write-Titulo '6. VERIFICACIÓN'

$enAD = @(Get-ADUser -Filter * -SearchBase $rutaUsuarios).Count
if ($enAD -eq $filas.Count) { Write-Ok "Usuarios en AD bajo OU=Usuarios: $enAD (coincide con el CSV)." }
else { Write-Aviso "Usuarios en AD bajo OU=Usuarios: $enAD. El CSV tiene $($filas.Count)." }

Write-Host ''
Write-Host 'Grupos globales GG_ y miembros:' -ForegroundColor White
Get-ADGroup -Filter "SamAccountName -like 'GG_*'" -SearchBase $rutaGlobales |
    Sort-Object SamAccountName |
    ForEach-Object {
        [pscustomobject]@{
            Grupo    = $_.SamAccountName
            Miembros = @(Get-ADGroupMember -Identity $_).Count
        }
    } | Format-Table -AutoSize

Write-Host 'Grupos locales de dominio DL_ y miembros:' -ForegroundColor White
Get-ADGroup -Filter "SamAccountName -like 'DL_*'" -SearchBase $rutaRecursos |
    Sort-Object SamAccountName |
    ForEach-Object {
        [pscustomobject]@{
            Grupo    = $_.SamAccountName
            Miembros = (Get-ADGroupMember -Identity $_ | Select-Object -ExpandProperty SamAccountName) -join ', '
        }
    } | Format-Table -AutoSize

Write-Host ''
if ($errores -eq 0) { Write-Ok "Script 05 finalizado sin errores. Log guardado en: $fichLog" }
else                { Write-Fallo "Script 05 finalizado con $errores error(es). Revisa el log: $fichLog" }
Write-Info 'SIGUIENTE PASO: capturas 15 (grupos) y 16 (usuarios). Después, commit del 05 y script de GPO.'
Stop-Transcript | Out-Null

