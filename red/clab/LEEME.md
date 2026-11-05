# Maqueta de la red de producción (containerlab)

Simula la red de Gestión Norte que VMware no puede simular: VLAN 802.1Q, dos núcleos con STP y tres accesos en Zaragoza, cuatro switches de sede en Huesca y Teruel (dos en esta maqueta), un túnel WireGuard por sede hacia ubu-fw y OSPF dentro de los túneles. Sin 4G (D38) y sin firewall: las reglas de firewall se prueban en VMware y se definen en Seguridad. Los servicios (Kea, Unbound, Active Directory) siguen en VMware; aquí solo se prueba la red.

Estado: topología v2 escrita el 05/11, **pendiente de verificar** (primer `deploy`). Direcciones en `PLAN-DIRECCIONES.md`.

## Qué hay

| Nodo | Papel | En producción sería |
|---|---|---|
| `zgz-n1`, `zgz-n2` | Núcleos de Zaragoza; `zgz-n1` es la raíz de STP | Dos switches de núcleo |
| `zgz-a1`, `zgz-a2`, `zgz-a3` | Accesos de Zaragoza; cada uno sube a los dos núcleos | Tres switches de acceso |
| `ubu-fw` | Router entre VLAN (troncal con subinterfaces) y extremo de los túneles | ubu-fw (en producción, pareja con VRRP) |
| `rt-hue`, `rt-ter` | Router de sede: VLAN de la sede y un túnel hacia ubu-fw | Router pequeño con WireGuard |
| `sw-hue1`, `sw-hue2`, `sw-ter1`, `sw-ter2` | Switches de sede en cascada | Cuatro switches de sede (D36) |
| `inet` | Internet y los proveedores (no conoce las redes 10.x) | Internet |
| `srv-dc1`, `pc-*`, `prn-zgz` | Equipos de prueba con IP fija | Servidores, puestos e impresoras |

Todo usa una sola imagen, `gn-red:1.0` (Ubuntu 24.04 con FRR, WireGuard e iproute2), creada con el `Dockerfile` de esta carpeta.

| Fichero | Qué contiene | Estado |
|---|---|---|
| `gestion-norte.clab.yml` | Topología v2: nodos, enlaces y qué fichero carga cada uno | Escrito |
| `PLAN-DIRECCIONES.md` | Direcciones de VLAN, túneles, loopbacks y hosts | Escrito |
| `nodos/` | Configuración de cada nodo (switches, `ubu-fw`, `rt-sede`, `inet`) | Pendiente de reescribir para la v2 |
| `frr/*.conf` | Direcciones y OSPF de cada router | Pendiente de reescribir para la v2 |
| `gen-claves.sh` | Genera las claves de WireGuard en `claves/` (no se suben a Git) | Vigente |
| `pruebas.sh` | Pruebas de la memoria, una captura por bloque | Pendiente de adaptar a la v2 |

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


## Uso diario

| Para | Comando |
|---|---|
| Ver los nodos | `sudo containerlab inspect -t gestion-norte.clab.yml` |
| Entrar en un nodo | `docker exec -it clab-gestion-norte-ubu-fw bash` |
| Consola de FRR (como un router Cisco) | `docker exec -it clab-gestion-norte-ubu-fw vtysh` |
| Parar y borrar la maqueta | `sudo containerlab destroy -t gestion-norte.clab.yml --cleanup` |
| Subir evidencias a Git | `cd ~/gestion-norte-asir && git add evidencias && git commit -m "Redes: maqueta containerlab, prueba N" && git push` |

## Qué no simula (se declara en la memoria)

- DHCP snooping, protección de puerto por MAC y 802.1X: los puentes Linux no los tienen. Se proponen en los switches reales.
- El reparto de direcciones (Kea) y el DNS (Unbound): ya están probados en VMware; aquí los equipos llevan IP fija.
- El firewall: no forma parte de la maqueta (D38 y Seguridad).
- Rendimiento real de la fibra y de los túneles: los enlaces son virtuales.
