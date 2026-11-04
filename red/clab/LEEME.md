# Maqueta de la red de producción (containerlab)

Simula la red real de Gestión Norte, que VMware no puede simular: switches con VLAN 802.1Q y troncales, las tres sedes, los túneles WireGuard hasta ubu-fw y OSPF con la línea 4G de respaldo. Los servicios (Kea, Unbound, Active Directory) siguen en el laboratorio de VMware; aquí solo se prueba la red.

Estado: preparado el 04/11, **pendiente de verificar** (primer despliegue en clab01).

## Qué hay

| Nodo | Papel | En producción sería |
|---|---|---|
| `ubu-fw` | Router entre VLAN (troncal con subinterfaces v10-v40), extremo de los 4 túneles, OSPF, NAT y firewall con la política del ubu-fw real | ubu-fw |
| `sw-zgz-core`, `sw-zgz-acc1` | Switch de núcleo (raíz de STP) y switch de acceso de Zaragoza | Switch de núcleo y 3 switches de acceso |
| `rt-hue`, `rt-ter` | Router de sede: VLAN de la sede, 2 túneles (fibra y 4G de Zaragoza), OSPF, salida local solo para invitados | Router pequeño con WireGuard |
| `sw-hue`, `sw-ter` | Switch de sede | Switch gestionable de la sede |
| `inet` | Internet y los proveedores (no conoce las redes 10.x) | Internet |
| `srv-dc1`, `pc-*` | Equipos de prueba con IP fija (el reparto con Kea ya está probado en VMware) | Servidores y puestos |

Todo usa una sola imagen, `gn-red:1.0` (Ubuntu 24.04 con FRR, nftables, WireGuard e iproute2), creada con el `Dockerfile` de esta carpeta.

| Fichero | Qué contiene |
|---|---|
| `gestion-norte.clab.yml` | Topología: nodos, enlaces y qué fichero carga cada uno |
| `nodos/sw-*.sh` + `nodos/lib-switch.sh` | Configuración de cada switch: puertos de acceso, troncales, STP, BPDU guard, root guard, IP de gestión |
| `nodos/ubu-fw.sh`, `nodos/rt-sede.sh` + `nodos/lib-router.sh` | Subinterfaces 802.1Q, túneles WireGuard, enrutamiento por marca |
| `frr/*.conf` | Direcciones, rutas estáticas y OSPF de cada router (sintaxis tipo Cisco) |
| `nft/*.nft` | Firewall de ubu-fw (conjuntos para las tres sedes) y del router de sede |
| `gen-claves.sh` | Genera las claves de WireGuard en `claves/` (no se suben a Git) |
| `pruebas.sh` | Las 6 pruebas de la memoria, una captura por bloque |

## Cómo arrancarla (primera vez)

**1. Máquina virtual `clab01` en VMware.** Ubuntu Server 24.04, 2 CPU, 4 GB de RAM, 25 GB de disco, una sola tarjeta en **NAT (VMnet8)**. En la instalación, marca *Install OpenSSH server*. Es independiente del resto del laboratorio: no se conecta a ningún VMnet de las VLAN.

**2. Entra por SSH desde Windows** (así se puede pegar). En la consola de VMware mira la IP con `ip -br a`; luego, en PowerShell:

```
ssh raul@IP_DE_CLAB01
```

**3. Instala Docker y containerlab** (script oficial de containerlab) y prepara el kernel:

```
curl -sL https://containerlab.dev/setup | sudo -E bash -s "all"
sudo modprobe wireguard
echo wireguard | sudo tee /etc/modules-load.d/wireguard.conf
echo net.netfilter.nf_log_all_netns=1 | sudo tee /etc/sysctl.d/90-clab-logs.conf
sudo sysctl --system
```

Cierra la sesión SSH y vuelve a entrar (para que tu usuario quede en el grupo de Docker).

**4. Descarga el repositorio** (es privado: `gh` te da un código para autorizarlo en el navegador de Windows):

```
sudo apt install -y gh
gh auth login
gh repo clone RUYA237/gestion-norte-asir
git config --global user.name "Raúl"
git config --global user.email "TU_CORREO"
```

**5. Crea la imagen, las claves y despliega:**

```
cd ~/gestion-norte-asir/red/clab
docker build -t gn-red:1.0 .
./gen-claves.sh
sudo containerlab deploy -t gestion-norte.clab.yml
```

Al final sale una tabla con los 16 nodos en estado `running`. Cada nodo imprime «… configurado» durante el despliegue; si alguno da error, cópialo tal cual.

**6. Diagrama automático** (captura para la memoria). Abre en el navegador de Windows `http://IP_DE_CLAB01:50080`:

```
sudo containerlab graph -t gestion-norte.clab.yml
```

**7. Pruebas** (espera 20 s después del despliegue para que STP y OSPF terminen). Cada una es una captura; además se guarda la salida en texto como evidencia:

```
sudo ./pruebas.sh 1 | tee ~/gestion-norte-asir/evidencias/redes/20261105-raul-clab-p1.txt
```

(cambia el 1 por 2 … 6).

## Uso diario

| Para | Comando |
|---|---|
| Ver los nodos | `sudo containerlab inspect -t gestion-norte.clab.yml` |
| Entrar en un nodo | `docker exec -it clab-gestion-norte-ubu-fw bash` |
| Consola de FRR (como un router Cisco) | `docker exec -it clab-gestion-norte-ubu-fw vtysh` |
| Ver lo bloqueado por los firewalls | `sudo dmesg \| grep -E "fw-\|sede-"` |
| Parar y borrar la maqueta | `sudo containerlab destroy -t gestion-norte.clab.yml --cleanup` |
| Subir evidencias a Git | `cd ~/gestion-norte-asir && git add evidencias && git commit -m "Redes: maqueta containerlab, prueba N" && git push` |

## Qué no simula (se declara en la memoria)

- DHCP snooping, protección de puerto por MAC y 802.1X: los puentes Linux no los tienen. Se proponen en los switches reales.
- El reparto de direcciones (Kea) y el DNS (Unbound): ya están probados en VMware; aquí los equipos llevan IP fija.
- Rendimiento real de la fibra y del 4G: los enlaces son virtuales.
