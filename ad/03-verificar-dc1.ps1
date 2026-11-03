<#
.SYNOPSIS
    Script 03 - Configuración posterior y verificación de dc1 tras la promoción.

.DESCRIPCION
    Proyecto Intermodular 2º ASIR - Consultoría Kalima / Cliente: Gestión Norte
    Módulo: Administración de Sistemas Operativos
    Autor: Arian

    Qué hace, en orden:
      1. Crea la zona inversa de la VLAN 20 (10.1.20.0/24) si no existe.
      2. Configura el reenviador DNS hacia ubu-fw (Unbound) para nombres que no son del dominio.
      3. Verifica: dominio, bosque, controlador, roles FSMO, zonas DNS, registros SRV,
         estado de la hora y dcdiag.
      4. Guarda todo en el log de C:\Evidencias.

    POR QUÉ:
      - La zona inversa permite resolver IP -> nombre; la usan registros, auditoría y Wazuh.
      - Reenviador a ubu-fw: dc1 resuelve lo suyo (ad.gestionnorte.es) y delega lo demás en
        Unbound, que es el DNS de borde. Unbound, a su vez, reenvía ad.gestionnorte.es a dc1/dc2.
      - dcdiag es la prueba estándar de salud de un controlador; si falla algo, se documenta
        el fallo y su arreglo (criterio 4 de la rúbrica de SO).

.EJEMPLOS
    .\03-verificar-dc1.ps1
    .\03-verificar-dc1.ps1 -Reenviador 10.1.20.1
#>

[CmdletBinding()]
param(
    [string]$Dominio    = 'ad.gestionnorte.es',
    [string]$RedInversa = '10.1.20.0/24',
    [string]$Reenviador = '10.1.20.1'
)

$ErrorActionPreference = 'Continue'

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

$identidad = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identidad)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Fallo 'Este script necesita ejecutarse como Administrador.'
    exit 1
}

$carpetaEvidencias = 'C:\Evidencias'
if (-not (Test-Path $carpetaEvidencias)) { New-Item -Path $carpetaEvidencias -ItemType Directory -Force | Out-Null }
$marca   = Get-Date -Format 'yyyyMMdd-HHmmss'
$fichLog = Join-Path $carpetaEvidencias "03-verificar-$($env:COMPUTERNAME.ToLower())-$marca.log"
Start-Transcript -Path $fichLog -Force | Out-Null

Write-Titulo "SCRIPT 03 - VERIFICACIÓN DE $($env:COMPUTERNAME.ToUpper())"
Write-Info "Ejecutado por : $($identidad.Name)"
Write-Info "Fecha y hora  : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"

Import-Module ActiveDirectory, DnsServer -ErrorAction Stop

# 1. Zona inversa
Write-Titulo '1. ZONA INVERSA'
$zonaInv = Get-DnsServerZone -ErrorAction SilentlyContinue | Where-Object { $_.IsReverseLookupZone -and $_.ZoneName -like '20.1.10.*' }
if ($zonaInv) { Write-Info "La zona inversa $($zonaInv.ZoneName) ya existe." }
else {
    Add-DnsServerPrimaryZone -NetworkId $RedInversa -ReplicationScope Domain -DynamicUpdate Secure
    Write-Ok "Zona inversa creada para $RedInversa (actualización dinámica segura)."
}

# 2. Reenviador
Write-Titulo '2. REENVIADOR DNS'
Set-DnsServerForwarder -IPAddress $Reenviador -PassThru | Out-Null
Write-Ok "Reenviador configurado: $Reenviador (ubu-fw / Unbound)."
Write-Aviso 'Si ubu-fw aún no está operativo, los nombres de Internet no resolverán; AD funciona igual.'

# 3. Verificaciones
Write-Titulo '3. DOMINIO Y BOSQUE'
Get-ADDomain | Format-List DNSRoot, NetBIOSName, DomainMode, PDCEmulator, InfrastructureMaster, RIDMaster
Get-ADForest | Format-List Name, ForestMode, SchemaMaster, DomainNamingMaster
Get-ADDomainController -Filter * | Format-Table Name, Site, IPv4Address, IsGlobalCatalog, OperatingSystem -AutoSize

Write-Titulo '4. ROLES FSMO'
netdom query fsmo

Write-Titulo '5. ZONAS DNS'
Get-DnsServerZone | Format-Table ZoneName, ZoneType, IsDsIntegrated, IsReverseLookupZone, DynamicUpdate -AutoSize
Write-Info "Reenviadores: $((Get-DnsServerForwarder).IPAddress -join ', ')"

Write-Titulo '6. REGISTROS SRV (localización del controlador)'
$srv = Resolve-DnsName -Name "_ldap._tcp.dc._msdcs.$Dominio" -Type SRV -ErrorAction SilentlyContinue
if ($srv) { Write-Ok 'El registro SRV _ldap._tcp.dc._msdcs existe:'; $srv | Format-Table Name, NameTarget, Port -AutoSize }
else      { Write-Fallo 'No se resuelve el registro SRV del controlador. Revisa el DNS y reinicia el servicio Netlogon.' }
nltest /dsgetdc:$Dominio

Write-Titulo '7. HORA'
w32tm /query /status
Write-Info 'dc1 es el PDC Emulator: es la referencia de hora del dominio. Los Ubuntu se sincronizan contra él.'

Write-Titulo '8. DCDIAG'
dcdiag /q
if ($LASTEXITCODE -eq 0) { Write-Ok 'dcdiag /q no devuelve errores (silencio = todo correcto).' }
else { Write-Aviso 'dcdiag ha devuelto avisos. Ejecuta "dcdiag /v" y documenta cada fallo y su solución.' }

Write-Host ''
Write-Ok "Script 03 finalizado. Log guardado en: $fichLog"
Write-Info 'SIGUIENTE PASO: avisar a Raúl (reenvío de zona en Unbound) y ejecutar los scripts 04 y 05.'
Stop-Transcript | Out-Null
