<#
.SYNOPSIS
    Script 04 - Sitios de AD, subredes y estructura de unidades organizativas (OU).

.DESCRIPCION
    Proyecto Intermodular 2º ASIR - Consultoría Kalima / Cliente: Gestión Norte
    Módulo: Administración de Sistemas Operativos
    Autor: Arian

    Qué hace, en orden:
      1. Comprueba que se ejecuta en un controlador de dominio.
      2. Sitios: renombra Default-First-Site-Name a Zaragoza y crea Huesca y Teruel.
      3. Subredes: asocia cada subred 10.<sede>.<vlan>.0/24 a su sitio.
      4. Enlaces entre sitios: Zaragoza-Huesca y Zaragoza-Teruel.
      5. OU: GestionNorte > Usuarios/Equipos por sede, Servidores, Grupos, Admin-TI.
      6. Redirige los equipos nuevos a una OU donde se pueden aplicar GPO.
      7. Verificación y resumen.

    POR QUÉ:
      - Sitios y subredes: AD decide a qué controlador se conecta cada cliente según su subred.
        Con el diseño en estrella (D30) Huesca y Teruel no tienen controlador propio, pero
        definirlos documenta la topología (requisito 18) y deja la 4ª sede lista (requisito 25).
      - Subredes: el plan 10.<sede>.<vlan>.0/24 de PLAN-RED.md. VLAN 10 y 20 solo en Zaragoza
        (núcleo); VLAN 30 a 80 en las tres sedes (D30).
      - OU por sede y departamento: permite delegar y aplicar GPO por departamento. Es la base
        de la segregación de funciones (requisito 27).
      - Todas las OU quedan protegidas contra borrado accidental.
      - Equipos nuevos: por defecto AD los mete en el contenedor "Computers", donde NO se pueden
        enlazar GPO. Se redirige a Equipos\Zaragoza para que reciban directivas desde el primer día.
      - El script es repetible: si algo ya existe, lo indica y no lo duplica.

.EJEMPLOS
    .\04-estructura-dominio.ps1
    .\04-estructura-dominio.ps1 -NoRedirigirEquipos

.NOTAS
    Ejecutar en dc1 con una cuenta de Administradores del dominio (GESTIONNORTE\Administrador).
#>

[CmdletBinding()]
param(
    [string]$RaizOU = 'GestionNorte',
    [switch]$NoRedirigirEquipos
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

# --- Privilegios y log -----------------------------------------------------
$identidad = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identidad)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Fallo 'Este script necesita ejecutarse como Administrador.'
    exit 1
}

$carpetaEvidencias = 'C:\Evidencias'
if (-not (Test-Path $carpetaEvidencias)) { New-Item -Path $carpetaEvidencias -ItemType Directory -Force | Out-Null }
$marca   = Get-Date -Format 'yyyyMMdd-HHmmss'
$fichLog = Join-Path $carpetaEvidencias "04-estructura-$($env:COMPUTERNAME.ToLower())-$marca.log"
Start-Transcript -Path $fichLog -Force | Out-Null

Write-Titulo 'SCRIPT 04 - SITIOS, SUBREDES Y UNIDADES ORGANIZATIVAS'
Write-Info "Ejecutado por : $($identidad.Name)"
Write-Info "Fecha y hora  : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
Write-Info "Log           : $fichLog"

# --- 1. Precondiciones -----------------------------------------------------
Write-Titulo '1. PRECONDICIONES'
$rol = (Get-CimInstance Win32_ComputerSystem).DomainRole
if ($rol -lt 4) {
    Write-Fallo 'Este equipo no es controlador de dominio. Ejecuta antes los scripts 02 y 03.'
    Stop-Transcript | Out-Null
    exit 2
}
Import-Module ActiveDirectory -ErrorAction Stop
try {
    $dominio   = Get-ADDomain
    $dominioDN = $dominio.DistinguishedName
}
catch {
    Write-Fallo "No se puede leer el dominio. ¿Has iniciado sesión como GESTIONNORTE\Administrador? $_"
    Stop-Transcript | Out-Null
    exit 3
}
Write-Ok "Dominio: $($dominio.DNSRoot)  ($dominioDN)"

# --- Datos de diseño (PLAN-RED.md) ------------------------------------------
$nombreVlan = @{
    10 = 'Gestion'; 20 = 'Servidores'; 30 = 'Laboral'; 40 = 'Fiscal'; 50 = 'Administracion'
    60 = 'Atencion'; 70 = 'Impresoras'; 80 = 'Invitados'; 90 = 'VPN usuarios'; 91 = 'VPN administradores'
}
$sedes = @(
    @{ Nombre = 'Zaragoza'; Num = 1; Descripcion = 'Sede principal. Nucleo: ubu-fw, DC y servidores'; Vlans = 10,20,30,40,50,60,70,80,90,91 },
    @{ Nombre = 'Huesca';   Num = 2; Descripcion = 'Sede Huesca. Sin servidor propio (red en estrella, D30)'; Vlans = 30,40,50,60,70,80 },
    @{ Nombre = 'Teruel';   Num = 3; Descripcion = 'Sede Teruel. Sin servidor propio (red en estrella, D30)'; Vlans = 30,40,50,60,70,80 }
)

# --- 2. Sitios ---------------------------------------------------------------
Write-Titulo '2. SITIOS DE ACTIVE DIRECTORY'

$defecto = Get-ADReplicationSite -Filter "Name -eq 'Default-First-Site-Name'" -ErrorAction SilentlyContinue
$zgz     = Get-ADReplicationSite -Filter "Name -eq 'Zaragoza'" -ErrorAction SilentlyContinue
if ($defecto -and -not $zgz) {
    Rename-ADObject -Identity $defecto.DistinguishedName -NewName 'Zaragoza'
    Write-Ok "Sitio 'Default-First-Site-Name' renombrado a 'Zaragoza' (dc1 sigue dentro de él)."
}
elseif ($zgz) { Write-Info "El sitio 'Zaragoza' ya existe." }

foreach ($s in $sedes) {
    $existe = Get-ADReplicationSite -Filter "Name -eq '$($s.Nombre)'" -ErrorAction SilentlyContinue
    if ($existe) {
        Set-ADReplicationSite -Identity $s.Nombre -Description $s.Descripcion
        Write-Info "El sitio '$($s.Nombre)' ya existe."
    } else {
        New-ADReplicationSite -Name $s.Nombre -Description $s.Descripcion
        Write-Ok "Sitio creado: $($s.Nombre)"
    }
}

# --- 3. Subredes -------------------------------------------------------------
Write-Titulo '3. SUBREDES'

foreach ($s in $sedes) {
    foreach ($v in $s.Vlans) {
        $cidr = "10.$($s.Num).$v.0/24"
        $loc  = "VLAN $v $($nombreVlan[$v]) - $($s.Nombre)"
        $sub  = Get-ADReplicationSubnet -Filter "Name -eq '$cidr'" -ErrorAction SilentlyContinue
        if ($sub) { Write-Info "Ya existe: $cidr" }
        else {
            New-ADReplicationSubnet -Name $cidr -Site $s.Nombre -Location $loc
            Write-Ok "Subred $cidr -> sitio $($s.Nombre)  ($loc)"
        }
    }
}
# Túneles entre sedes (10.0.0.0/24): terminan en ubu-fw, en Zaragoza
$cidrTun = '10.0.0.0/24'
if (-not (Get-ADReplicationSubnet -Filter "Name -eq '$cidrTun'" -ErrorAction SilentlyContinue)) {
    New-ADReplicationSubnet -Name $cidrTun -Site 'Zaragoza' -Location 'Tuneles entre sedes (WireGuard) - terminan en ubu-fw'
    Write-Ok "Subred $cidrTun -> sitio Zaragoza (túneles)"
} else { Write-Info "Ya existe: $cidrTun" }

# --- 4. Enlaces entre sitios ------------------------------------------------------
Write-Titulo '4. ENLACES ENTRE SITIOS'
Write-Info 'Coste 100 y replicación cada 15 minutos. Los enlaces salen de Zaragoza (estrella).'

foreach ($destino in 'Huesca','Teruel') {
    $nombreEnlace = "Zaragoza-$destino"
    if (Get-ADReplicationSiteLink -Filter "Name -eq '$nombreEnlace'" -ErrorAction SilentlyContinue) {
        Write-Info "Ya existe el enlace $nombreEnlace."
    } else {
        New-ADReplicationSiteLink -Name $nombreEnlace -SitesIncluded 'Zaragoza',$destino `
            -Cost 100 -ReplicationFrequencyInMinutes 15 -InterSiteTransportProtocol IP
        Write-Ok "Enlace creado: $nombreEnlace"
    }
}
Write-Info "El enlace por defecto 'DEFAULTIPSITELINK' se deja como está (no estorba)."

# --- 5. Unidades organizativas ----------------------------------------------------
Write-Titulo '5. UNIDADES ORGANIZATIVAS (OU)'

function Asegurar-OU {
    param([string]$Nombre, [string]$Ruta, [string]$Descripcion = '')
    $dn = "OU=$Nombre,$Ruta"
    $existe = Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$dn'" -ErrorAction SilentlyContinue
    if ($existe) {
        Write-Info "Ya existe: $dn"
    } else {
        New-ADOrganizationalUnit -Name $Nombre -Path $Ruta -Description $Descripcion -ProtectedFromAccidentalDeletion $true
        Write-Ok "OU creada: $dn"
    }
    return $dn
}

$departamentos = 'Laboral','Fiscal','Administracion','Atencion'

$dnRaiz      = Asegurar-OU -Nombre $RaizOU -Ruta $dominioDN -Descripcion 'Raiz de la estructura de Gestion Norte'
$dnUsuarios  = Asegurar-OU -Nombre 'Usuarios'  -Ruta $dnRaiz -Descripcion 'Usuarios por sede y departamento'
$dnEquipos   = Asegurar-OU -Nombre 'Equipos'   -Ruta $dnRaiz -Descripcion 'Equipos cliente por sede'
$dnServ      = Asegurar-OU -Nombre 'Servidores' -Ruta $dnRaiz -Descripcion 'Servidores miembros del dominio'
$dnGrupos    = Asegurar-OU -Nombre 'Grupos'    -Ruta $dnRaiz -Descripcion 'Grupos de seguridad (modelo AGDLP)'
$dnAdmin     = Asegurar-OU -Nombre 'Admin-TI'  -Ruta $dnRaiz -Descripcion 'Cuentas administrativas adm_ separadas de las de uso diario'

foreach ($s in $sedes) {
    $dnSedeU = Asegurar-OU -Nombre $s.Nombre -Ruta $dnUsuarios -Descripcion "Usuarios de $($s.Nombre)"
    foreach ($d in $departamentos) {
        Asegurar-OU -Nombre $d -Ruta $dnSedeU -Descripcion "$d - $($s.Nombre)" | Out-Null
    }
    Asegurar-OU -Nombre $s.Nombre -Ruta $dnEquipos -Descripcion "Equipos de $($s.Nombre)" | Out-Null
}

# Subdivisión de Grupos para AGDLP: globales (por departamento) y de recurso (locales de dominio)
Asegurar-OU -Nombre 'Globales' -Ruta $dnGrupos -Descripcion 'Grupos globales GG_ (un grupo por departamento y sede)' | Out-Null
Asegurar-OU -Nombre 'Recursos' -Ruta $dnGrupos -Descripcion 'Grupos locales de dominio DL_ (permiso sobre cada recurso)' | Out-Null

# --- 6. Equipos nuevos --------------------------------------------------------------
Write-Titulo '6. UBICACIÓN POR DEFECTO DE LOS EQUIPOS NUEVOS'
if ($NoRedirigirEquipos) {
    Write-Aviso 'Se omite la redirección (parámetro -NoRedirigirEquipos).'
} else {
    $destinoEquipos = "OU=Zaragoza,$dnEquipos"
    redircmp.exe $destinoEquipos | Out-Null
    Write-Ok "Los equipos que se unan al dominio sin OU indicada irán a: $destinoEquipos"
    Write-Info 'Motivo: el contenedor "Computers" por defecto no admite GPO enlazadas.'
}

# --- 7. Verificación ----------------------------------------------------------------
Write-Titulo '7. VERIFICACIÓN'

Write-Host ''
Write-Host 'Sitios:' -ForegroundColor White
Get-ADReplicationSite -Filter * | Sort-Object Name | Format-Table Name, Description -AutoSize

Write-Host 'Subredes por sitio:' -ForegroundColor White
Get-ADReplicationSubnet -Filter * |
    Select-Object Name, @{ n = 'Sitio'; e = { ($_.Site -split ',')[0] -replace '^CN=' } }, Location |
    Sort-Object Sitio, Name | Format-Table -AutoSize

Write-Host 'Enlaces entre sitios:' -ForegroundColor White
Get-ADReplicationSiteLink -Filter * | Format-Table Name, Cost, ReplicationFrequencyInMinutes -AutoSize

Write-Host 'Controlador y su sitio:' -ForegroundColor White
Get-ADDomainController -Filter * | Format-Table Name, Site, IPv4Address -AutoSize

Write-Host 'Árbol de OU:' -ForegroundColor White
$ous = Get-ADOrganizationalUnit -Filter * -SearchBase $dnRaiz -Properties ProtectedFromAccidentalDeletion
$ous | Sort-Object DistinguishedName |
    Select-Object @{ n = 'OU'; e = { ($_.DistinguishedName -replace ",$([regex]::Escape($dominioDN))$",'') } }, ProtectedFromAccidentalDeletion |
    Format-Table -AutoSize
$sinProteger = @($ous | Where-Object { -not $_.ProtectedFromAccidentalDeletion }).Count
Write-Info "Total de OU: $($ous.Count). Sin protección contra borrado: $sinProteger."

Write-Host ''
Write-Ok "Script 04 finalizado. Log guardado en: $fichLog"
Write-Info 'SIGUIENTE PASO: script 05 (grupos AGDLP y usuarios desde CSV).'
Stop-Transcript | Out-Null
