<#
.SYNOPSIS
    Script 07 - Promoción de dc2 (Server Core) a segundo controlador de dominio de ad.gestionnorte.es.

.DESCRIPCION
    Proyecto Intermodular 2º ASIR - Consultoría Kalima / Cliente: Gestión Norte
    Módulo: Administración de Sistemas Operativos
    Autor: Arian

    Qué hace, en orden:
      1. Comprueba privilegios y abre log en C:\Evidencias.
      2. Comprueba las precondiciones: nombre, IP fija, DNS apuntando a dc1, equipo no promovido
         todavía, y que dc1 responde (DNS, registro SRV y puerto LDAP 389).
      3. Pide las credenciales de un administrador del dominio y la contraseña DSRM de dc2.
      4. Instala los roles AD DS y DNS.
      5. Promueve dc2 como controlador adicional del dominio existente, en el sitio Zaragoza,
         con DNS integrado y catálogo global, replicando desde dc1.
      6. Deja el reinicio para después, para poder capturar la salida.

    POR QUÉ:
      - Alta disponibilidad: si dc1 cae (más de 2 h de parada en campaña fiscal es grave),
        dc2 sigue autenticando y resolviendo el dominio.
      - Server Core: menor superficie de ataque y menos parches (sin escritorio), y consume 2 GB.
      - Catálogo global en ambos: los inicios de sesión no dependen de un único servidor.
      - Replica desde dc1 de forma explícita para que el origen quede documentado en el log.
      - Las credenciales y la contraseña DSRM se piden por pantalla: nunca van en el script ni en Git.

    ANTES DE EJECUTAR: dc1 encendido y accesible, y snapshot "dc2-pre-promocion".
    Después de promover NO se restaura ninguna instantánea de este controlador (USN rollback).

.EJEMPLOS
    .\07-promover-dc2.ps1
    .\07-promover-dc2.ps1 -Reiniciar

.NOTAS
    Ejecutar desde la consola de VMware en dc2. Tarda entre 5 y 15 minutos.
#>

[CmdletBinding()]
param(
    [string]$Dominio         = 'ad.gestionnorte.es',
    [string]$NombreEsperado  = 'dc2',
    [string]$IPEsperada      = '10.1.20.11',
    [string]$IPdc1           = '10.1.20.10',
    [string]$FQDNdc1         = 'dc1.ad.gestionnorte.es',
    [string]$Sitio           = 'Zaragoza',
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

# --- 1. Privilegios y log ---------------------------------------------------------
$identidad = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identidad)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Fallo 'Este script necesita ejecutarse como Administrador.'
    exit 1
}

$carpetaEvidencias = 'C:\Evidencias'
if (-not (Test-Path $carpetaEvidencias)) { New-Item -Path $carpetaEvidencias -ItemType Directory -Force | Out-Null }
$marca   = Get-Date -Format 'yyyyMMdd-HHmmss'
$fichLog = Join-Path $carpetaEvidencias "07-promover-$NombreEsperado-$marca.log"
Start-Transcript -Path $fichLog -Force | Out-Null

Write-Titulo "SCRIPT 07 - PROMOCIÓN DE $($NombreEsperado.ToUpper()) A CONTROLADOR ADICIONAL"
Write-Info "Dominio       : $Dominio"
Write-Info "Origen de réplica: $FQDNdc1 ($IPdc1)"
Write-Info "Sitio         : $Sitio"
Write-Info "Ejecutado por : $($identidad.Name)"
Write-Info "Fecha y hora  : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
Write-Info "Log           : $fichLog"
Write-Info "Tipo de instalación: $((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').InstallationType)"

# --- 2. Precondiciones --------------------------------------------------------------
Write-Titulo '2. PRECONDICIONES'
$fallos = 0

if ($env:COMPUTERNAME -ieq $NombreEsperado) { Write-Ok "Nombre del equipo: $env:COMPUTERNAME" }
else { Write-Fallo "El equipo se llama $env:COMPUTERNAME y debería llamarse $NombreEsperado. Ejecuta antes el script 01."; $fallos++ }

$ipOk = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -eq $IPEsperada -and $_.PrefixOrigin -eq 'Manual' }
if ($ipOk) { Write-Ok "IP fija $IPEsperada presente." }
else { Write-Fallo "No hay IP fija $IPEsperada en este equipo."; $fallos++ }

$dnsCliente = (Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses } |
               Select-Object -ExpandProperty ServerAddresses) -join ', '
if ($dnsCliente -match [regex]::Escape($IPdc1)) { Write-Ok "El DNS del equipo apunta a dc1 ($dnsCliente)." }
else { Write-Fallo "El DNS del equipo es '$dnsCliente'. Debe incluir $IPdc1."; $fallos++ }

$rol = (Get-CimInstance Win32_ComputerSystem).DomainRole
if ($rol -ge 4) { Write-Fallo 'Este equipo ya es controlador de dominio.'; $fallos++ }
else { Write-Ok 'El equipo no es todavía controlador de dominio.' }

$resDominio = Resolve-DnsName -Name $Dominio -Server $IPdc1 -ErrorAction SilentlyContinue
if ($resDominio) { Write-Ok "dc1 resuelve $Dominio." }
else { Write-Fallo "dc1 no resuelve $Dominio. Comprueba que dc1 está encendido y que su DNS funciona."; $fallos++ }

$srv = Resolve-DnsName -Name "_ldap._tcp.dc._msdcs.$Dominio" -Type SRV -Server $IPdc1 -ErrorAction SilentlyContinue
if ($srv) { Write-Ok 'dc1 publica el registro SRV _ldap._tcp.dc._msdcs.' }
else { Write-Fallo 'No se resuelve el registro SRV del controlador en dc1.'; $fallos++ }

$ldap = Test-NetConnection -ComputerName $IPdc1 -Port 389 -WarningAction SilentlyContinue
if ($ldap.TcpTestSucceeded) { Write-Ok "Puerto LDAP 389 de dc1 accesible." }
else { Write-Fallo "No se alcanza el puerto 389 de $IPdc1."; $fallos++ }

Write-Info "Hora actual: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')  Zona: $((Get-TimeZone).Id)"
Write-Info 'Kerberos no tolera más de 5 minutos de desfase con dc1. Comprueba que la hora es correcta.'

if ($fallos -gt 0) {
    Write-Host ''
    Write-Fallo "Hay $fallos precondición(es) sin cumplir. No se promueve nada."
    Stop-Transcript | Out-Null
    exit 2
}

# --- 3. Credenciales y contraseña DSRM ----------------------------------------------------
Write-Titulo '3. CREDENCIALES Y CONTRASEÑA DSRM'
Write-Info 'Se necesita una cuenta de Administradores del dominio para unir y promover dc2.'
$cred = Get-Credential -UserName 'GESTIONNORTE\Administrador' -Message 'Administrador del dominio ad.gestionnorte.es'

Write-Info 'Contraseña DSRM de dc2: guárdala en el gestor compartido, NUNCA en Git ni en este script.'
Write-Info 'Mínimo 12 caracteres, con mayúsculas, minúsculas, números y símbolos.'
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
Write-Ok 'Credenciales y contraseña DSRM aceptadas (no se guardan en ningún fichero).'

# --- 4. Roles ---------------------------------------------------------------------------------
Write-Titulo '4. INSTALACIÓN DE ROLES AD DS Y DNS'
$res = Install-WindowsFeature -Name AD-Domain-Services, DNS -IncludeManagementTools
if ($res.Success) { Write-Ok "Roles instalados. Reinicio necesario por los roles: $($res.RestartNeeded)" }
else { Write-Fallo 'La instalación de roles ha fallado.'; Stop-Transcript | Out-Null; exit 3 }

# --- 5. Promoción como controlador adicional -------------------------------------------------------
Write-Titulo "5. PROMOCIÓN DE $($NombreEsperado.ToUpper()) EN $Dominio"
Write-Info 'Esto tarda unos minutos. No cierres la ventana.'
Import-Module ADDSDeployment
Install-ADDSDomainController `
    -DomainName                    $Dominio `
    -Credential                    $cred `
    -SiteName                      $Sitio `
    -ReplicationSourceDC           $FQDNdc1 `
    -InstallDns:$true `
    -NoGlobalCatalog:$false `
    -SafeModeAdministratorPassword $p1 `
    -NoRebootOnCompletion:$true `
    -Force:$true | Out-Null

Write-Ok "$NombreEsperado promovido como controlador adicional de $Dominio. Falta reiniciar para terminar."
Remove-Variable p1, p2, cred -ErrorAction SilentlyContinue

Write-Titulo '6. RESUMEN'
Write-Info 'Tras reiniciar, inicia sesión como GESTIONNORTE\Administrador y verifica la replicación:'
Write-Info '  repadmin /replsummary ; repadmin /showrepl ; dcdiag /q'
Write-Ok "Script 07 finalizado. Log guardado en: $fichLog"
Stop-Transcript | Out-Null

if ($Reiniciar) {
    Write-Aviso 'Reiniciando en 10 segundos... (Ctrl+C para cancelar)'
    Start-Sleep -Seconds 10
    Restart-Computer -Force
} else {
    Write-Aviso 'Haz tus capturas y reinicia con:  Restart-Computer -Force'
}
