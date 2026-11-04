# Maqueta de la red de producción (containerlab)

Simula la red real de Gestión Norte, que VMware no puede simular: switches con VLAN 802.1Q y troncales, las tres sedes, los túneles WireGuard hasta ubu-fw y OSPF con la línea 4G de respaldo. Los servicios (Kea, Unbound, Active Directory) siguen en el laboratorio de VMware; aquí solo se prueba la red.

Estado: preparado el 04/11, **pendiente de verificar** (primer despliegue en WSL).

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

## Ruta actual: contenedor en Docker Desktop (D37)

Raúl ha decidido no usar WSL. La maqueta corre en un contenedor `gestion-containerlab-red` creado desde Windows con Docker Desktop. Sin `--privileged`, con solo las capacidades que necesita.

**1. Crear el contenedor (PowerShell de Windows):**

```
docker run -it --name gestion-containerlab-red --cap-add NET_ADMIN --cap-add SYS_ADMIN --pid host -v //var/run/docker.sock://var/run/docker.sock ubuntu:24.04 bash
```

- `NET_ADMIN`: crear interfaces, puentes y rutas.
- `SYS_ADMIN`: montar los espacios de red de cada nodo. Es la más amplia de las dos; se justifica en la memoria.
- `--pid host`: localizar los procesos de los nodos.
- El montaje del socket: sin él, containerlab no puede pedir al demonio que cree los nodos. Equivale a root en el anfitrión.

**2. Dentro del contenedor:**

```
apt update && apt install -y curl git gh docker.io wireguard-tools iproute2 ca-certificates
gh auth login
gh repo clone RUYA237/gestion-norte-asir ~/gestion-norte-asir
gh auth logout -h github.com
ls ~/gestion-norte-asir/red/clab/gestion-norte.clab.yml
```

Estado 04/11: clonado y comprobado (la sesión de GitHub se cierra después del clon). **Pendiente:** instalar containerlab dentro del contenedor, `deploy` y pruebas P1-P6. Si el `deploy` pide otra capacidad, se añade esa y no `--privileged`.

## Cómo arrancarla (primera vez, en WSL: ruta descartada por D37)

La maqueta corre dentro de WSL2 (Ubuntu 24.04) en el PC de Raúl, sin máquina virtual de VMware. Docker va **dentro de WSL** (Docker Engine), no con Docker Desktop. Los comandos de los pasos 1 y 2 se pegan en PowerShell; el resto, en la terminal de Ubuntu.

**1. WSL2 con Ubuntu 24.04** (PowerShell como administrador; si ya lo tienes, `wsl -l -v` debe mostrar Ubuntu-24.04 con VERSION 2):

```
wsl --install -d Ubuntu-24.04
```

Reinicia si lo pide y crea tu usuario de Linux. Nota: WSL2 usa la plataforma de virtualización de Windows; VMware Workstation 17 convive con ella pero puede ir más lento.

**2. Memoria y systemd.** Crea `C:\Users\RUYA\.wslconfig` con 6 GB (4 GB para la maqueta y el resto para Linux):

```
[wsl2]
memory=6GB
processors=2
```

En Ubuntu activa systemd (Docker lo necesita) y reinicia WSL:

```
printf '[boot]\nsystemd=true\n' | sudo tee /etc/wsl.conf
```

```
wsl --shutdown
```

**3. Comprueba que el kernel de WSL sirve** (en Ubuntu). Deben salir los dos «OK»; si no, `wsl --update` en PowerShell y repite:

```
sudo ip link add brtest type bridge vlan_filtering 1 && sudo ip link del brtest && echo "Puente con VLAN: OK"
sudo ip link add wgtest type wireguard && sudo ip link del wgtest && echo "WireGuard: OK"
```

**4. Instala Docker y containerlab** (script oficial de containerlab):

```
curl -sL https://containerlab.dev/setup | sudo -E bash -s "all"
sudo sysctl -w net.netfilter.nf_log_all_netns=1 || echo "sin registro del firewall en dmesg (no es grave)"
```

Cierra Ubuntu, vuelve a abrirlo (para que tu usuario quede en el grupo de Docker) y comprueba `docker run --rm hello-world`.

**5. Descarga el repositorio dentro de Linux** (en `~`, no en `/mnt/c`: los enlaces y permisos fallan en el disco de Windows). Es privado: `gh` te da un código para autorizarlo en el navegador de Windows:

```
sudo apt install -y gh
gh auth login
gh repo clone RUYA237/gestion-norte-asir
git config --global user.name "Raúl"
git config --global user.email "TU_CORREO"
```

**6. Crea la imagen, las claves y despliega:**

```
cd ~/gestion-norte-asir/red/clab
docker build -t gn-red:1.0 .
./gen-claves.sh
sudo containerlab deploy -t gestion-norte.clab.yml
```

Al final sale una tabla con los 16 nodos en estado `running`. Cada nodo imprime «… configurado» durante el despliegue; si alguno da error, cópialo tal cual.

**7. Diagrama automático** (captura para la memoria). Abre en el navegador de Windows `http://localhost:50080`:

```
sudo containerlab graph -t gestion-norte.clab.yml
```

**8. Pruebas** (espera 20 s después del despliegue para que STP y OSPF terminen). Cada una es una captura; además se guarda la salida en texto como evidencia:

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
