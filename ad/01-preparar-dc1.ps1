<#
.SYNOPSIS
    Script 01 - Preparación de un servidor clonado antes de promoverlo a controlador de dominio.

.DESCRIPCION
    Proyecto Intermodular 2º ASIR - Consultoría Kalima / Cliente: Gestión Norte
    Módulo: Administración de Sistemas Operativos
    Autor: Arian

    Qué hace, en orden:
      1. Comprueba que se ejecuta como administrador.
      2. Abre un log de evidencia en C:\Evidencias.
      3. Fotografía el estado PREVIO del equipo (nombre, red, dominio).
      4. Comprueba que la IP que vamos a asignar NO está ya en uso en la red.
      5. Comprueba que el nombre de equipo no está ya registrado.
      6. Configura la tarjeta de red: nombre, IP fija, puerta de enlace y DNS.
      7. Ajusta zona horaria y configuración regional.
      8. Renombra el equipo.
      9. Muestra el estado FINAL y cierra el log.

    POR QUÉ la comprobación de IP duplicada (paso 4):
    El cliente describe su problema como "cada máquina tiene un numerito escrito a mano,
    si se repite no funciona". Las colisiones de IP son el fallo número uno de su red
    actual. Este script demuestra el procedimiento correcto: verificar antes de asignar.
    En producción esta función la cubre el DHCP con reservas (Kea, módulo de Redes);
    aquí cubre las direcciones fijas de la VLAN 20 de servidores.

    LÍMITE CONOCIDO de la comprobación: se basa en ICMP y en la tabla ARP. Un equipo con
    el firewall bloqueando ICMP podría no responder al ping. Por eso se comprueba también
    la tabla ARP, que detecta al vecino aunque no conteste. Aun así no es infalible:
    la fuente de verdad es la documentación del plan de direccionamiento (PLAN-RED.md).

.EJEMPLOS
    .\01-preparar-dc1.ps1
    .\01-preparar-dc1.ps1 -Reiniciar
    .\01-preparar-dc1.ps1 -NombreEquipo dc2 -IP 10.1.20.11 -DNS 10.1.20.10 -Reiniciar

.NOTAS
    Ejecutar SIEMPRE desde la consola de VMware, nunca por RDP: el script cambia la IP
    y cortaría tu propia sesión.
#>

[CmdletBinding()]
param(
    [string]$NombreEquipo = 'dc1',
    [string]$IP           = '10.1.20.10',
    [int]   $Mascara      = 24,
    [string]$Gateway      = '10.1.20.1',
    # Antes de promover el PRIMER controlador, el servidor se apunta a sí mismo como DNS.
    # Para dc2 y para servidores miembro, aquí va la IP de dc1 (10.1.20.10).
    [string]$DNS          = '10.1.20.10',
    [string]$NombreNIC    = 'LAN-VLAN20',
    [string]$ZonaHoraria  = 'Romance Standard Time',
    [switch]$Reiniciar
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Funciones de salida (para que el log quede legible)
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# 1. Comprobación de privilegios
# ---------------------------------------------------------------------------
$identidad = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identidad)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Fallo 'Este script necesita ejecutarse como Administrador.'
    Write-Host  'Cierra esta ventana y abre PowerShell con "Ejecutar como administrador".'
    exit 1
}

# ---------------------------------------------------------------------------
# 2. Log de evidencia
# ---------------------------------------------------------------------------
$carpetaEvidencias = 'C:\Evidencias'
if (-not (Test-Path $carpetaEvidencias)) {
    New-Item -Path $carpetaEvidencias -ItemType Directory -Force | Out-Null
}
$marca   = Get-Date -Format 'yyyyMMdd-HHmmss'
$fichLog = Join-Path $carpetaEvidencias "01-preparar-$NombreEquipo-$marca.log"
Start-Transcript -Path $fichLog -Force | Out-Null

Write-Titulo "SCRIPT 01 - PREPARACIÓN DE $($NombreEquipo.ToUpper())"
Write-Info "Proyecto Gestión Norte - Consultoría Kalima"
Write-Info "Ejecutado por : $($identidad.Name)"
Write-Info "Fecha y hora  : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
Write-Info "Log           : $fichLog"

# ---------------------------------------------------------------------------
# 3. Estado PREVIO (evidencia del "antes")
# ---------------------------------------------------------------------------
Write-Titulo '3. ESTADO PREVIO DEL EQUIPO'

$infoPrevia = Get-CimInstance Win32_ComputerSystem
Write-Info "Nombre actual   : $($infoPrevia.Name)"
Write-Info "Grupo de trabajo: $($infoPrevia.Workgroup)"
Write-Info "¿En dominio?    : $($infoPrevia.PartOfDomain)"
Write-Info "Zona horaria    : $((Get-TimeZone).Id)"
Write-Host ''
Write-Info 'Adaptadores de red detectados:'
Get-NetAdapter | Format-Table Name, InterfaceDescription, Status, MacAddress, LinkSpeed -AutoSize
Write-Info 'Direcciones IPv4 actuales:'
Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.InterfaceAlias -notlike 'Loopback*' } |
    Format-Table InterfaceAlias, IPAddress, PrefixLength, PrefixOrigin -AutoSize

# ---------------------------------------------------------------------------
# 4. Comprobación de IP duplicada  <-- EVIDENCIA CLAVE PARA LA MEMORIA
# ---------------------------------------------------------------------------
Write-Titulo "4. COMPROBACIÓN DE IP DUPLICADA ($IP)"

$yaEsMia = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
           Where-Object { $_.IPAddress -eq $IP }

if ($yaEsMia) {
    Write-Aviso "La IP $IP ya está asignada a este mismo equipo. Se omite la comprobación."
}
else {
    Write-Info "Enviando 3 paquetes ICMP a $IP ..."
    $responde = Test-Connection -ComputerName $IP -Count 3 -Quiet -ErrorAction SilentlyContinue

    Write-Info 'Consultando la tabla ARP del segmento ...'
    $vecinoArp = Get-NetNeighbor -AddressFamily IPv4 -ErrorAction SilentlyContinue |
                 Where-Object { $_.IPAddress -eq $IP -and $_.State -in 'Reachable','Stale','Permanent' }

    if ($responde -or $vecinoArp) {
        Write-Fallo "CONFLICTO: la dirección $IP YA ESTÁ EN USO en este segmento."
        if ($responde)  { Write-Fallo "  - Responde al ping." }
        if ($vecinoArp) { Write-Fallo "  - Presente en la tabla ARP con MAC $($vecinoArp.LinkLayerAddress) (estado: $($vecinoArp.State))." }
        Write-Host ''
        Write-Host 'Tabla ARP completa del segmento:' -ForegroundColor Yellow
        arp -a
        Write-Host ''
        Write-Fallo 'Se aborta la configuración para NO provocar una colisión de IP.'
        Write-Host  'Acción: identifica el equipo que tiene esa IP, corrige el plan de'
        Write-Host  'direccionamiento (PLAN-RED.md) y vuelve a ejecutar el script.'
        Stop-Transcript | Out-Null
        exit 2
    }

    Write-Ok "La dirección $IP está libre. Se puede asignar."
}

# ---------------------------------------------------------------------------
# 5. Comprobación de nombre de equipo duplicado
# ---------------------------------------------------------------------------
Write-Titulo "5. COMPROBACIÓN DEL NOMBRE DE EQUIPO ($NombreEquipo)"

$resuelve = Resolve-DnsName -Name $NombreEquipo -ErrorAction SilentlyContinue |
            Where-Object { $_.Type -eq 'A' }

if ($resuelve) {
    $ipsEncontradas = ($resuelve.IPAddress | Sort-Object -Unique) -join ', '
    if ($ipsEncontradas -eq $IP) {
        Write-Aviso "El nombre $NombreEquipo ya resuelve a $ipsEncontradas (la IP prevista). Probablemente sea una reejecución del script."
    } else {
        Write-Aviso "El nombre $NombreEquipo ya resuelve a $ipsEncontradas, distinta de la prevista ($IP)."
        Write-Aviso 'Revisa si hay otro equipo con ese nombre antes de continuar.'
    }
} else {
    Write-Ok "El nombre $NombreEquipo no está registrado en DNS. Libre."
}

# ---------------------------------------------------------------------------
# 6. Configuración de la tarjeta de red
# ---------------------------------------------------------------------------
Write-Titulo '6. CONFIGURACIÓN DE RED'

# Se elige el adaptador físico conectado; si ninguno lo está, el primero disponible.
$nic = Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1
if (-not $nic) { $nic = Get-NetAdapter -Physical | Select-Object -First 1 }
if (-not $nic) {
    Write-Fallo 'No se ha encontrado ninguna tarjeta de red física. Revisa la configuración de la VM.'
    Stop-Transcript | Out-Null
    exit 3
}
Write-Info "Adaptador seleccionado: '$($nic.Name)' - MAC $($nic.MacAddress) - estado $($nic.Status)"

# 6.1 Renombrar el adaptador para que se identifique la VLAN de un vistazo
if ($nic.Name -ne $NombreNIC) {
    Rename-NetAdapter -Name $nic.Name -NewName $NombreNIC -ErrorAction Stop
    Write-Ok "Adaptador renombrado a '$NombreNIC'."
} else {
    Write-Info "El adaptador ya se llama '$NombreNIC'."
}

# 6.2 Desactivar DHCP y limpiar la configuración anterior
Set-NetIPInterface -InterfaceAlias $NombreNIC -Dhcp Disabled -ErrorAction SilentlyContinue
Write-Ok 'DHCP desactivado en el adaptador (esta máquina usa IP fija).'

Get-NetIPAddress -InterfaceAlias $NombreNIC -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
Get-NetRoute -InterfaceAlias $NombreNIC -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
    Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue
Write-Ok 'Configuración IPv4 anterior eliminada.'

# 6.3 Asignar la configuración definitiva
New-NetIPAddress -InterfaceAlias $NombreNIC `
                 -IPAddress     $IP `
                 -PrefixLength  $Mascara `
                 -DefaultGateway $Gateway -ErrorAction Stop | Out-Null
Write-Ok "IP $IP/$Mascara asignada, puerta de enlace $Gateway."

Set-DnsClientServerAddress -InterfaceAlias $NombreNIC -ServerAddresses $DNS -ErrorAction Stop
Write-Ok "Servidor DNS configurado: $DNS"

# 6.4 Sufijo DNS principal (se registrará correctamente al promover el dominio)
Set-DnsClient -InterfaceAlias $NombreNIC -RegisterThisConnectionsAddress $true -ErrorAction SilentlyContinue

Write-Host ''
Write-Info 'Comprobación de conectividad con la puerta de enlace (ubu-fw):'
if (Test-Connection -ComputerName $Gateway -Count 2 -Quiet -ErrorAction SilentlyContinue) {
    Write-Ok "La puerta de enlace $Gateway responde."
} else {
    Write-Aviso "La puerta de enlace $Gateway no responde."
    Write-Aviso 'Puede ser normal si ubu-fw aún no está montado o si filtra ICMP. Anótalo en la bitácora.'
}

# ---------------------------------------------------------------------------
# 7. Zona horaria y configuración regional
# ---------------------------------------------------------------------------
Write-Titulo '7. ZONA HORARIA Y REGIÓN'

Set-TimeZone -Id $ZonaHoraria -ErrorAction Stop
Write-Ok "Zona horaria establecida: $ZonaHoraria"
Write-Info 'La hora del dominio la impondrá el PDC Emulator. El resto de equipos (y los'
Write-Info 'Ubuntu con chrony) se sincronizarán contra él. Kerberos no tolera más de 5'
Write-Info 'minutos de desfase: un reloj mal puesto rompe el inicio de sesión.'

Set-WinSystemLocale   -SystemLocale es-ES -ErrorAction SilentlyContinue
Set-WinHomeLocation   -GeoId 217          -ErrorAction SilentlyContinue   # 217 = España
Write-Ok 'Configuración regional: España.'

# ---------------------------------------------------------------------------
# 8. Renombrar el equipo
# ---------------------------------------------------------------------------
Write-Titulo '8. NOMBRE DEL EQUIPO'

if ($env:COMPUTERNAME -ieq $NombreEquipo) {
    Write-Info "El equipo ya se llama $NombreEquipo. No se renombra."
    $necesitaReinicio = $false
} else {
    Rename-Computer -NewName $NombreEquipo -Force -ErrorAction Stop
    Write-Ok "Equipo renombrado a '$NombreEquipo'. El cambio se aplica tras reiniciar."
    $necesitaReinicio = $true
}

# ---------------------------------------------------------------------------
# 9. Estado FINAL (evidencia del "después")
# ---------------------------------------------------------------------------
Write-Titulo '9. ESTADO FINAL - RESUMEN DE VERIFICACIÓN'

Write-Host ''
Write-Host 'Configuración de red resultante:' -ForegroundColor White
Get-NetIPConfiguration -InterfaceAlias $NombreNIC | Format-List InterfaceAlias, IPv4Address, IPv4DefaultGateway, DNSServer

Write-Host 'Resumen:' -ForegroundColor White
[PSCustomObject]@{
    'Nombre (tras reinicio)' = $NombreEquipo
    'Adaptador'              = $NombreNIC
    'Dirección IP'           = "$IP/$Mascara"
    'Puerta de enlace'       = $Gateway
    'Servidor DNS'           = $DNS
    'Zona horaria'           = (Get-TimeZone).Id
    'Firewall activo'        = (((Get-NetFirewallProfile).Enabled) -join ', ')
} | Format-List

Write-Host ''
Write-Ok "Script 01 finalizado. Log guardado en: $fichLog"
Write-Info 'SIGUIENTE PASO: reiniciar y ejecutar el script 02 (promoción a controlador de dominio).'

Stop-Transcript | Out-Null

# ---------------------------------------------------------------------------
# 10. Reinicio
# ---------------------------------------------------------------------------
if ($necesitaReinicio) {
    if ($Reiniciar) {
        Write-Aviso 'Reiniciando en 10 segundos... (Ctrl+C para cancelar)'
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    } else {
        Write-Aviso 'HACE FALTA REINICIAR para que el nuevo nombre tenga efecto.'
        Write-Host  'Haz tus capturas primero y luego ejecuta:  Restart-Computer -Force'
    }
}
