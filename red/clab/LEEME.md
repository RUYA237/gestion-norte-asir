# Maqueta de la red de producción (containerlab), versión final de 26 nodos

Es la versión documentada en el apartado 4.1 de la memoria: Zaragoza (15 nodos), Huesca (6) y Teruel (5), con enlaces directos entre ubu-fw y cada sede y rutas estáticas. Sin firewall, sin WireGuard y sin OSPF (propuestos).

Estado: verificada el 06/11 en WSL2 (containerlab 0.81.1). En Fedora: pendiente de verificar.

## Ficheros

| Fichero | Contenido |
|---|---|
| `gestion-norte.clab.yml` | Los 26 nodos y los 28 enlaces |
| `Dockerfile` | Imagen única `gn-red:1.0` |
| `nodos/lib.sh` | Funciones comunes: subinterfaz VLAN, puente, troncal, acceso, root guard |
| `nodos/sw.sh` | Configuración de los 9 switches |
| `nodos/ubu-fw.sh` | Router entre VLAN, WAN y enlaces a las sedes |
| `nodos/rt-sede.sh` | Router de Huesca (2) y de Teruel (3) |
| `nodos/host.sh` | Equipos de prueba con IP fija |
| `nodos/inet.sh` | Internet simulado (8.8.8.8) |
| `pruebas.sh` | Pruebas P1 a P5 y acceso de los 12 equipos a srv-dc1 |

## Instalar en Fedora (una vez)

```
sudo dnf install -y dnf-plugins-core git
sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
bash -c "$(curl -sL https://get.containerlab.dev)"
sudo modprobe -a bridge 8021q
```

Cierra la sesión y vuelve a entrar para que el grupo `docker` tenga efecto.

## Desplegar y probar

```
cd red/clab
chcon -Rt container_file_t nodos
docker build -t gn-red:1.0 .
sudo containerlab deploy -t gestion-norte.clab.yml
sudo containerlab inspect -t gestion-norte.clab.yml
./pruebas.sh | tee pruebas-$(date +%Y%m%d-%H%M).log
```

## Prueba P6: cortes de enlace (a mano)

```
docker exec clab-gestion-norte-ubu-fw ip link set wan down
docker exec clab-gestion-norte-pc-lab-hue ping -c2 -W2 8.8.8.8
docker exec clab-gestion-norte-pc-lab-hue ping -c2 -W2 10.1.20.10
docker exec clab-gestion-norte-ubu-fw bash -c "ip link set wan up; ip route replace default via 203.0.113.1"

docker exec clab-gestion-norte-ubu-fw ip link set eth2 down
docker exec clab-gestion-norte-pc-lab-hue ping -c2 -W2 10.1.20.10
docker exec clab-gestion-norte-pc-fis-ter ping -c2 -W2 10.1.20.10
docker exec clab-gestion-norte-ubu-fw bash -c "ip link set eth2 up; ip route replace 10.2.0.0/16 via 10.255.12.2"
```

Resultado esperado: con la WAN caída no hay Internet y sí se llega a srv-dc1; con eth2 caído solo Huesca queda aislada.

## Parar

```
sudo containerlab destroy -t gestion-norte.clab.yml --cleanup
```

## Qué no simula

Firewall (se prueba en VMware con ubu-fw), Kea y Unbound (los equipos llevan IP fija), WireGuard y OSPF (propuestos), DHCP snooping, límite de MAC y 802.1X (propuestos para los switches reales). En las sedes solo se montan las VLAN 30, 40 y 80 (Huesca) y 40 y 80 (Teruel).
