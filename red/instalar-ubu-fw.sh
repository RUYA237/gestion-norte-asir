#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
[ "$(id -u)" -eq 0 ] || { echo "Ejecuta con sudo"; exit 1; }

if ! ip link show v10 >/dev/null 2>&1; then
  echo "== FASE 1: paquetes, nombres de tarjeta y kernel"
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y nftables kea-dhcp4-server unbound chrony
  systemctl disable --now kea-dhcp4-server unbound 2>/dev/null || true
  echo 'network: {config: disabled}' > /etc/cloud/cloud.cfg.d/99-desactivar-red-cloud-init.cfg
  mkdir -p /root/copia-netplan-original
  for f in /etc/netplan/*.yaml; do
    [ "$f" = /etc/netplan/config-red-vlan.yaml ] || mv "$f" /root/copia-netplan-original/
  done
  install -m 600 config-red-vlan.yaml /etc/netplan/config-red-vlan.yaml
  netplan generate
  install -m 644 sysctl-seguridad-red.conf /etc/sysctl.d/99-seguridad-red.conf
  if ! grep -q 'ipv6.disable=1' /etc/default/grub; then
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 ipv6.disable=1"/' /etc/default/grub
    update-grub
  fi
  echo "FASE 1 hecha. Reinicia (sudo reboot) y vuelve a ejecutar este script."
  exit 0
fi

echo "== FASE 2: servicios y firewall"
install -m 644 dns-gestion-norte.conf /etc/unbound/unbound.conf.d/dns-gestion-norte.conf
install -m 640 kea-dhcp4.conf /etc/kea/kea-dhcp4.conf
if getent group _kea >/dev/null; then chown root:_kea /etc/kea/kea-dhcp4.conf; fi
install -m 644 chrony-gestion-norte.conf /etc/chrony/conf.d/gestion-norte.conf
install -m 644 nftables.conf /etc/nftables.conf
mkdir -p /etc/systemd/system/nftables.service.d
install -m 644 activar-reenvio.conf /etc/systemd/system/nftables.service.d/activar-reenvio.conf

nft -c -f /etc/nftables.conf
unbound-checkconf
kea-dhcp4 -t /etc/kea/kea-dhcp4.conf

systemctl daemon-reload
systemctl restart chrony
systemctl enable unbound kea-dhcp4-server nftables
systemctl restart unbound kea-dhcp4-server
systemctl restart nftables

echo "== ESTADO"
ip -br addr
cat /proc/cmdline
sysctl net.ipv4.ip_forward
systemctl is-active nftables unbound kea-dhcp4-server chrony
echo "FASE 2 hecha. El SSH por la WAN queda cerrado: entra desde la VLAN 10."
