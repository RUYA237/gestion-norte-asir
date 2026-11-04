#!/bin/bash
# inet: simula Internet y los proveedores. No conoce las redes 10.x de la empresa,
# igual que Internet: por eso ubu-fw y los routers de sede tienen que hacer NAT.
# Direcciones de documentación (RFC 5737): no chocan con ninguna red real.
set -eu
ip route del default dev eth0 2>/dev/null || true
sysctl -qw net.ipv4.ip_forward=1 || true
ip addr add 203.0.113.1/30  dev eth1   # fibra de Zaragoza
ip addr add 198.51.100.1/30 dev eth2   # 4G de Zaragoza
ip addr add 203.0.113.5/30  dev eth3   # fibra de Huesca
ip addr add 203.0.113.9/30  dev eth4   # fibra de Teruel
ip addr add 9.9.9.9/32 dev lo          # "un servidor de Internet"
# Servicio web simulado en 9.9.9.9 (puertos 80 y 443) para probar la salida
for p in 80 443; do setsid nc -lk "$p" >/dev/null 2>&1 < /dev/null & done
echo "inet configurado"
