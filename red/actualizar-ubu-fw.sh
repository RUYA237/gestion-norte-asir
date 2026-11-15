#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
[ "$(id -u)" -eq 0 ] || { echo "Ejecuta con sudo"; exit 1; }
NP=/etc/netplan/config-red-vlan.yaml
[ -f "$NP" ] || { echo "No existe $NP: esta máquina no es la ubu-fw del 03/11"; exit 1; }

if ! ip link show v50 >/dev/null 2>&1; then
  echo "== FASE 1: copia de seguridad, tarjetas nuevas y ficheros"
  C=/root/copia-config-$(date +%Y%m%d-%H%M)
  mkdir -p "$C"
  cp -a "$NP" /etc/nftables.conf /etc/kea/kea-dhcp4.conf /etc/unbound/unbound.conf.d/dns-gestion-norte.conf "$C"/
  echo "Copia en $C"
  if ! grep -q 'v50:' "$NP"; then
    for v in 50 60 70 80; do
      printf '    v%s:\n      match: { macaddress: "00:50:56:00:01:%s" }\n      set-name: v%s\n      addresses: [10.1.%s.1/24]\n' "$v" "$v" "$v" "$v" >> "$NP"
    done
  fi
  netplan generate
  install -m 644 dns-gestion-norte.conf /etc/unbound/unbound.conf.d/dns-gestion-norte.conf
  install -m 640 kea-dhcp4.conf /etc/kea/kea-dhcp4.conf
  if getent group _kea >/dev/null; then chown root:_kea /etc/kea/kea-dhcp4.conf; fi
  install -m 644 chrony-gestion-norte.conf /etc/chrony/conf.d/gestion-norte.conf
  nft -c -f nftables.conf
  install -m 644 nftables.conf /etc/nftables.conf
  unbound-checkconf
  echo "FASE 1 hecha. Reinicia (sudo reboot) y vuelve a ejecutar este script."
  exit 0
fi

echo "== FASE 2: comprobación tras el reinicio"
kea-dhcp4 -t /etc/kea/kea-dhcp4.conf 2>&1 | tail -3
ip -br addr
sysctl net.ipv4.ip_forward
systemctl is-active nftables unbound kea-dhcp4-server chrony
nft list ruleset | grep -c accept
ss -lun | grep -E ':(53|67|123) ' | awk '{print $4}' | sort -u
chronyc tracking | head -3
