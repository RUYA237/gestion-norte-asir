#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
[ "$(id -u)" -eq 0 ] || { echo "Ejecuta con sudo"; exit 1; }
USUARIO="${1:-teletrabajo1}"
WAN_IP=$(ip -4 -o addr show wan | awk '{print $4}' | cut -d/ -f1)
ER=/etc/openvpn/easy-rsa

echo "== 1. Autoridad de certificación y certificados"
if [ ! -f "$ER/pki/ca.crt" ]; then
  make-cadir "$ER"
  cd "$ER"
  ./easyrsa --batch init-pki
  ./easyrsa --batch --req-cn="Gestion Norte VPN CA" build-ca nopass
  ./easyrsa --batch build-server-full ubu-fw nopass
  cd - >/dev/null
fi
if [ ! -f "$ER/pki/issued/$USUARIO.crt" ]; then
  (cd "$ER" && ./easyrsa --batch build-client-full "$USUARIO" nopass)
fi
[ -f /etc/openvpn/server/tc.key ] || openvpn --genkey tls-crypt /etc/openvpn/server/tc.key
install -m 644 "$ER/pki/ca.crt" /etc/openvpn/server/ca.crt
install -m 644 "$ER/pki/issued/ubu-fw.crt" /etc/openvpn/server/ubu-fw.crt
install -m 600 "$ER/pki/private/ubu-fw.key" /etc/openvpn/server/ubu-fw.key

echo "== 2. Servidor"
cat > /etc/openvpn/server/gn.conf <<CONF
port 1194
proto udp
dev tun0
topology subnet
server 10.0.1.0 255.255.255.0
ca ca.crt
cert ubu-fw.crt
key ubu-fw.key
dh none
tls-crypt tc.key
tls-version-min 1.2
data-ciphers AES-256-GCM:CHACHA20-POLY1305
auth SHA256
verify-client-cert require
plugin /usr/lib/x86_64-linux-gnu/openvpn/plugins/openvpn-plugin-auth-pam.so "openvpn login USERNAME password PASSWORD 'Verification code' OTP"
auth-gen-token 28800
reneg-sec 3600
push "route 10.1.20.0 255.255.255.0"
keepalive 10 60
persist-key
persist-tun
user nobody
group nogroup
status /run/openvpn-server/estado-gn.log
verb 3
CONF

echo "== 3. Autenticación: contraseña y código TOTP"
cat > /etc/pam.d/openvpn <<'PAM'
auth requisite pam_google_authenticator.so secret=/etc/openvpn/totp/${USER} user=root
auth required pam_unix.so
account required pam_unix.so
PAM
install -d -m 700 /etc/openvpn/totp
id "$USUARIO" >/dev/null 2>&1 || useradd -M -s /usr/sbin/nologin "$USUARIO"

echo "== 4. Perfil del cliente"
install -d -m 700 /root/vpn-clientes
P=/root/vpn-clientes/$USUARIO.ovpn
{
  echo "client"
  echo "dev tun"
  echo "proto udp"
  echo "remote $WAN_IP 1194"
  echo "nobind"
  echo "remote-cert-tls server"
  echo "tls-version-min 1.2"
  echo "data-ciphers AES-256-GCM:CHACHA20-POLY1305"
  echo "auth SHA256"
  echo "auth-user-pass"
  echo "static-challenge \"Codigo TOTP\" 1"
  echo "auth-nocache"
  echo "verb 3"
  echo "<ca>"; cat "$ER/pki/ca.crt"; echo "</ca>"
  echo "<cert>"; openssl x509 -in "$ER/pki/issued/$USUARIO.crt"; echo "</cert>"
  echo "<key>"; cat "$ER/pki/private/$USUARIO.key"; echo "</key>"
  echo "<tls-crypt>"; cat /etc/openvpn/server/tc.key; echo "</tls-crypt>"
} > "$P"
chmod 600 "$P"

echo "== 5. Firewall"
nft -c -f nftables.conf
install -m 644 nftables.conf /etc/nftables.conf
systemctl restart nftables

echo "== 6. Arranque"
systemctl enable openvpn-server@gn
systemctl restart openvpn-server@gn
sleep 3
systemctl is-active openvpn-server@gn
ip -br addr show tun0
ss -lun | grep 1194
echo "Hecho. Falta: contraseña y TOTP del usuario $USUARIO (pasos del LEEME)."
