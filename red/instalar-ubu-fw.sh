#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
[ "$(id -u)" -eq 0 ] || { echo "Ejecuta con sudo"; exit 1; }

echo "== 1. Paquetes"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nftables kea-dhcp4-server unbound chrony
systemctl stop kea-dhcp4-server unbound 2>/dev/null || true

echo "== 2. Red: cloud-init fuera y netplan por MAC"
echo 'network: {config: disabled}' > /etc/cloud/cloud.cfg.d/99-desactivar-red-cloud-init.cfg
mkdir -p /root/copia-netplan-original
for f in /etc/netplan/*.yaml; do
  [ "$f" = /etc/netplan/config-red-vlan.yaml ] || mv "$f" /root/copia-netplan-original/
done
install -m 600 config-red-vlan.yaml /etc/netplan/config-red-vlan.yaml
netplan generate
netplan apply
sleep 5

echo "== 3. Endurecimiento de red e IPv6 apagado en el kernel"
install -m 644 sysctl-seguridad-red.conf /etc/sysctl.d/99-seguridad-red.conf
sysctl --system >/dev/null
if ! grep -q 'ipv6.disable=1' /etc/default/grub; then
  sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 ipv6.disable=1"/' /etc/default/grub
  update-grub
fi

echo "== 4. Ficheros de servicio"
install -m 644 dns-gestion-norte.conf /etc/unbound/unbound.conf.d/dns-gestion-norte.conf
install -m 640 kea-dhcp4.conf /etc/kea/kea-dhcp4.conf
getent group _kea >/dev/null && chown root:_kea /etc/kea/kea-dhcp4.conf
install -m 644 chrony-gestion-norte.conf /etc/chrony/conf.d/gestion-norte.conf
install -m 644 nftables.conf /etc/nftables.conf
mkdir -p /etc/systemd/system/nftables.service.d
install -m 644 activar-reenvio.conf /etc/systemd/system/nftables.service.d/activar-reenvio.conf

echo "== 5. Validación antes de arrancar nada"
nft -c -f /etc/nftables.conf
unbound-checkconf
kea-dhcp4 -t /etc/kea/kea-dhcp4.conf

echo "== 6. Arranque"
systemctl daemon-reload
systemctl restart chrony
systemctl enable --now unbound kea-dhcp4-server
systemctl restart unbound kea-dhcp4-server
systemctl enable nftables
systemctl restart nftables

echo "== 7. Estado"
ip -br addr
sysctl net.ipv4.ip_forward
systemctl is-active nftables unbound kea-dhcp4-server chrony
echo "Hecho. El SSH por la WAN queda cerrado: entra desde la VLAN 10. Reinicia para apagar IPv6."
