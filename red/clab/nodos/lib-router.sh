#!/bin/bash
# Funciones comunes de los routers de la maqueta (ubu-fw, rt-hue, rt-ter).

# preparar: quita la salida por la red de gestión de containerlab (eth0) para que
# todo el tráfico de la maqueta vaya por sus enlaces, y activa el reenvío.
# rp_filter=2 (modo flexible): con dos salidas a Internet y dos túneles por sede,
# el modo estricto descartaría el túnel de respaldo (la vuelta "esperada" es la fibra).
preparar() {
  ip route del default dev eth0 2>/dev/null || true
  sysctl -qw net.ipv4.ip_forward=1 net.ipv4.conf.all.rp_filter=2 || true
}

# vlans TRONCAL VLAN... -> subinterfaces 802.1Q (router-on-a-stick): v10, v20...
vlans() {
  local t=$1; shift
  ip link set "$t" up
  for v in "$@"; do
    ip link add link "$t" name "v$v" type vlan id "$v"
    ip link set "v$v" up
  done
}

# tunel NOMBRE CLAVE_PROPIA PEER [opciones de wg para el peer]
#   Una interfaz WireGuard por túnel y un solo peer en cada una: así OSPF ve cada
#   túnel como un enlace punto a punto con su propio coste.
#   allowed-ips 0.0.0.0/0 en cada túnel (solo hay un peer por interfaz).
#   multicast on: OSPF envía sus saludos a 224.0.0.5.
tunel() {
  local n=$1 k=$2 peer=$3; shift 3
  ip link add "$n" type wireguard
  wg set "$n" private-key "/config/claves/$k.key" "$@" \
     peer "$(cat /config/claves/$peer.pub)" allowed-ips 0.0.0.0/0
  ip link set "$n" multicast on up
}

# arrancar_frr: crea las carpetas de FRR y arranca zebra, staticd y ospfd con frr.conf
arrancar_frr() {
  mkdir -p /var/run/frr /var/log/frr
  chown -R frr:frr /var/run/frr /var/log/frr
  /usr/lib/frr/frrinit.sh start
}
