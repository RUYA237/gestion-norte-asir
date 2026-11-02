#!/usr/bin/env python3
"""Diagrama de la red del laboratorio (VMware). Genera red-lab.svg. Reutiliza los iconos de red-fisica.py."""
import re
src = open(__file__.replace("red-lab.py", "red-fisica.py")).read()
exec(src.split("# ================= LIENZO =================")[0])  # funciones e iconos
W, H = 1500, 830
o.clear()
add(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><rect width="{W}" height="{H}" fill="#fff"/>')
T(30, 42, "Laboratorio · PC de integración (VMware Workstation)", 28, a="start", b=True)
T(30, 72, "Cada VLAN es una red virtual (VMnet) de tipo solo anfitrión, sin DHCP de VMware y sin adaptador del PC", 18, a="start")

add('<ellipse cx="750" cy="128" rx="110" ry="34" fill="#f0f0f0" stroke="#000" stroke-width="2"/>')
T(750, 135, "Internet", 22, b=True)
L([(750, 162), (750, 222)], sw=2.5)
T(765, 190, "VMnet8 (NAT): salida de ubu-fw; el PC anfitrión también está aquí (prueba de la VPN)", 16, a="start")
fw(750, 250)
T(705, 244, "ubu-fw", 20, a="end", b=True)
T(705, 267, ".1 en cada VLAN · única máquina con varias redes", 16, a="end")

L([(750, 277), (750, 310)], sw=2.5)
L([(60, 310), (750, 310)], sw=2)
# VLAN 20
R(150, 330, 1200, 185, sw=3)
T(750, 356, "VMnet12 · VLAN 20 Servidores · 10.1.20.0/24", 18, b=True)
L([(750, 310), (750, 330)], sw=2)
for k, (n, ip, who) in enumerate([("dc1", ".10", "Arian"), ("dc2", ".11", "Arian"), ("ubu-svc", ".20", "Álvaro"),
                                  ("wazuh01", ".30", "Álvaro"), ("bkp01", ".40", "Álvaro")]):
    cx = 270 + k*240
    srv(cx, 410); T(cx, 457, f"{n} {ip}", 17, b=True); T(cx, 479, who, 16)

# fila inferior
L([(60, 310), (60, 550)], sw=2)
L([(60, 550), (1230, 550)], sw=2)
boxes = [(40, "VMnet11 · VLAN 10 Gestión"), (520, "VMnet13 · VLAN 30 Laboral"), (1000, "VMnet14 · VLAN 40 Fiscal")]
for x, t in boxes:
    L([(x+230, 550), (x+230, 575)], sw=1.6)
    R(x, 575, 460, 165, sw=3)
    T(x+230, 601, t, 18, b=True)
# VLAN 10
R(165, 622, 210, 112, sw=1.4, dash="8 5"); pc(270, 660); T(270, 703, "cli-test", 16, b=True); T(270, 720, "para administrar", 14)
# VLAN 30
for cx, n, who in [(650, "cli-test", "Raúl · Ubuntu"), (850, "cli01", "Arian · Windows 11")]:
    pc(cx, 660); T(cx, 703, n, 16, b=True); T(cx, 722, who, 15)
# VLAN 40
R(1125, 622, 210, 112, sw=1.4, dash="8 5"); pc(1230, 660); T(1230, 703, "cli-test", 16, b=True); T(1230, 720, "prueba de aislamiento", 14)

y = 778
R(30, y-14, 40, 26, sw=1.4, dash="8 5"); T(78, y+5, "cli-test se mueve de red cambiando su adaptador en VMware", 16, a="start")
T(30, y+36, "Clientes con IP de Kea (reparto .50-.249). Ninguna máquina, salvo ubu-fw, tiene más de una red: así nada puede saltarse el firewall.", 15, a="start")
add("</svg>")
open("red-lab.svg", "w").write("\n".join(o))
print("ok")
