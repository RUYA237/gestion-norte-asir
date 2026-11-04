#!/usr/bin/env python3
"""Diagrama de conmutación y enrutamiento (switches, troncales, túneles y OSPF).
Mismos nombres de nodo, interfaz y dirección que la maqueta de containerlab (red/clab).
Genera red-conmutacion.svg. Reutiliza los iconos de red-fisica.py."""
src = open(__file__.replace("red-conmutacion.py", "red-fisica.py")).read()
exec(src.split("# ================= LIENZO =================")[0])  # funciones e iconos
W, H = 1500, 1200
o.clear()
add(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><rect width="{W}" height="{H}" fill="#fff"/>')
T(30, 42, "Gestión Norte · Conmutación y enrutamiento", 28, a="start", b=True)
T(30, 72, "Switches, troncales 802.1Q, túneles WireGuard y OSPF · nombres y direcciones de la maqueta (red/clab)", 18, a="start")

TR, AC = 5, 1.8   # grosor: troncal 802.1Q y puerto de acceso

# ---------------- Internet ----------------
R(560, 100, 380, 70, sw=2, fill="#f0f0f0", rx=30)
T(750, 130, "Internet", 22, b=True)
T(750, 155, "proveedores de fibra y 4G (inet en la maqueta)", 15)

# ---------------- ubu-fw ----------------
fw(750, 300)
L([(728, 273), (728, 170)], sw=2.5)
L([(772, 273), (772, 170)], sw=2.5, dash="3 4")
T(720, 205, "wan · fibra (principal)", 15, a="end", b=True)
T(720, 225, "203.0.113.2/30", 15, a="end")
T(780, 205, "wan4g · 4G/5G (respaldo)", 15, a="start", b=True)
T(780, 225, "198.51.100.2/30", 15, a="start")
T(764, 352, "ubu-fw", 19, a="start", b=True)
T(764, 372, "firewall, router entre VLAN y OSPF", 15, a="start")

# ---------------- routers de sede y túneles ----------------
def rtr(cx, name, wan, side):
    router(cx, 300)
    if side == "L":
        T(cx - 40, 340, name, 19, a="end", b=True); T(cx - 40, 360, f"wan {wan}", 15, a="end")
    else:
        T(cx + 40, 340, name, 19, a="start", b=True); T(cx + 40, 360, f"wan {wan}", 15, a="start")
    ex = 560 if side == "L" else 940
    L([(cx, 282), (cx, 135), (ex, 135)], sw=2.5)
    T(cx + (8 if side == "L" else -8), 120, "fibra local", 15, a="start" if side == "L" else "end")

rtr(260, "rt-hue", "203.0.113.6/30", "L")
rtr(1240, "rt-ter", "203.0.113.10/30", "R")

def tuneles(x1, x2, f, m):
    L([(x1, 290), (x2, 290)], sw=2.2, dash="9 6")
    L([(x1, 310), (x2, 310)], sw=1.4, dash="4 5")
    cx = (x1 + x2) / 2
    T(cx, 280, f, 14)
    T(cx, 330, m, 14)

tuneles(292, 712, "wg-hue-f · 10.0.0.0/30 · coste 10 (fibra)", "wg-hue-m · 10.0.0.4/30 · coste 100 (4G)")
tuneles(788, 1208, "wg-ter-f · 10.0.0.8/30 · coste 10 (fibra)", "wg-ter-m · 10.0.0.12/30 · coste 100 (4G)")
T(450, 256, "OSPF área 0 dentro de los túneles", 15, b=True)
T(1050, 256, "OSPF área 0 dentro de los túneles", 15, b=True)

# ---------------- bloques de sede ----------------
Y0 = 440       # parte superior de los bloques
def bloque(x, w, title, sub):
    R(x, Y0, w, 540, sw=2.6, rx=10)
    T(x + 16, Y0 + 28, title, 19, a="start", b=True)
    T(x + 16, Y0 + 50, sub, 15, a="start")

def nodo_pc(cx, cy, name, ip, vlan, extra=None):
    pc(cx, cy)
    T(cx, cy + 42, name, 15, b=True)
    T(cx, cy + 61, ip, 14)
    T(cx, cy + 80, vlan, 14)
    if extra: T(cx, cy + 99, extra, 14)

def trunk_down(x, y1, vl):
    L([(x, y1), (x, 515)], sw=TR)
    T(x + 10, 398, "troncal 802.1Q", 14, a="start", b=True)
    T(x + 10, 416, vl, 14, a="start")

SWY = 530      # fila de switches
PCY = 690      # fila de equipos

# Zaragoza
bloque(500, 500, "Zaragoza · CPD", "110 puestos · 10.1.x.x")
trunk_down(750, 327, "VLAN 10, 20, 30, 40")
sw_(750, SWY)
T(812, SWY - 6, "sw-zgz-core · núcleo", 15, a="start", b=True)
T(812, SWY + 13, "raíz STP · 10.1.10.2", 14, a="start")
L([(705, SWY + 13), (705, 600), (585, 600), (585, PCY - 30)], sw=AC)
L([(730, SWY + 13), (730, 615), (700, 615), (700, PCY - 25)], sw=AC)
L([(790, SWY + 13), (790, 600), (910, 600), (910, PCY + 7)], sw=TR)
T(585, 640, "eth3 · acceso 20", 13)
T(694, 655, "eth4 · acceso 10", 13, a="end")
T(902, 625, "eth2 · troncal 10, 30, 40", 13, a="end")
T(902, 642, "root guard", 13, a="end")
srv(585, PCY); T(585, PCY + 44, "srv-dc1", 15, b=True); T(585, PCY + 63, "10.1.20.10 · VLAN 20", 14)
T(585, PCY + 82, "papel de dc1", 14)
nodo_pc(700, PCY, "pc-it", "10.1.10.10", "VLAN 10")
sw_(910, PCY + 20)
T(848, PCY + 16, "sw-zgz-acc1", 15, a="end", b=True)
T(848, PCY + 35, "acceso · 10.1.10.3", 14, a="end")
L([(860, PCY + 33), (860, PCY + 40), (845, PCY + 40), (845, 850)], sw=AC)
L([(960, PCY + 33), (960, PCY + 40), (950, PCY + 40), (950, 850)], sw=AC)
nodo_pc(845, 870, "pc-lab-zgz", "10.1.30.50", "VLAN 30")
nodo_pc(950, 870, "pc-fis-zgz", "10.1.40.50", "VLAN 40")
for i, l in enumerate(["Producción: un switch de", "núcleo y tres de acceso", "de 48 puertos con PoE", "(144 puertos para unos", "120 equipos). La maqueta", "monta uno de acceso."]):
    T(520, 830 + i * 18, l, 14, a="start")

# Huesca
bloque(30, 450, "Huesca · 25 puestos", "10.2.x.x")
trunk_down(260, 318, "VLAN 10, 30, 40, 80")
sw_(260, SWY)
T(260, SWY + 35, "sw-hue · 48 puertos PoE", 15, b=True)
T(260, SWY + 53, "gestión 10.2.10.2", 14)
L([(215, SWY + 13), (215, SWY + 20), (120, SWY + 20), (120, PCY - 25)], sw=AC)
L([(305, SWY + 13), (305, SWY + 20), (400, SWY + 20), (400, PCY - 25)], sw=AC)
L([(260, SWY + 60), (260, PCY - 25)], sw=AC)
nodo_pc(120, PCY, "pc-lab-hue", "10.2.30.50", "VLAN 30")
nodo_pc(260, PCY, "pc-fis-hue", "10.2.40.50", "VLAN 40")
nodo_pc(400, PCY, "pc-inv-hue", "10.2.80.50", "VLAN 80 · visitas", "sale por la fibra local")
for i, l in enumerate(["rt-hue no enruta entre sus VLAN:", "todo el tráfico de empresa va al túnel", "y lo filtra ubu-fw. Solo la VLAN 80 sale", "directa a Internet, con su propia tabla", "de rutas y sin acceso a la red 10.x."]):
    T(50, 840 + i * 18, l, 14, a="start", b=(i == 0))

# Teruel
bloque(1020, 450, "Teruel · 15 puestos", "10.3.x.x")
trunk_down(1240, 318, "VLAN 10, 30, 40, 80")
sw_(1240, SWY)
T(1240, SWY + 35, "sw-ter · 24 puertos PoE", 15, b=True)
T(1240, SWY + 53, "gestión 10.3.10.2", 14)
L([(1240, SWY + 60), (1240, PCY - 25)], sw=AC)
nodo_pc(1240, PCY, "pc-fis-ter", "10.3.40.50", "VLAN 40")
for i, l in enumerate(["Igual que Huesca. La maqueta solo", "monta un puesto de Fiscal: basta para", "probar que llega a los servidores y", "que cambia al 4G si cae la fibra."]):
    T(1040, 840 + i * 18, l, 14, a="start")

# Configuración común de los switches
YB = 1000
R(30, YB, 1440, 100, sw=1.4, rx=6, fill="#f7f7f7")
T(46, YB + 26, "En todos los switches:", 15, a="start", b=True)
T(46, YB + 48, "puerto de acceso = una VLAN fija sin etiqueta y BPDU guard · troncal = solo las VLAN necesarias, etiquetadas · sin VLAN nativa (una trama sin etiqueta", 14, a="start")
T(46, YB + 68, "en un troncal se descarta) · STP con el núcleo como raíz · IP de gestión en la VLAN 10. Propuesto solo en los switches reales: DHCP snooping, límite de MAC", 14, a="start")
T(46, YB + 88, "por puerto y 802.1X, que los puentes Linux de la maqueta no tienen.", 14, a="start")

# Leyenda
y = 1135
L([(30, y), (90, y)], sw=TR); T(98, y + 5, "troncal 802.1Q", 15, a="start")
L([(250, y), (310, y)], sw=AC); T(318, y + 5, "puerto de acceso", 15, a="start")
L([(480, y), (540, y)], sw=2.5); T(548, y + 5, "línea a Internet", 15, a="start")
L([(700, y), (760, y)], sw=2.2, dash="9 6"); T(768, y + 5, "túnel WireGuard por la fibra", 15, a="start")
L([(1010, y), (1070, y)], sw=1.4, dash="4 5"); T(1078, y + 5, "túnel WireGuard por el 4G", 15, a="start")
T(30, y + 40, "Si cae la fibra de Zaragoza, los túneles de la fibra dejan de responder y OSPF pasa en unos 8 segundos a los del 4G (coste 100). Estado: propuesto en producción; maqueta pendiente de verificar.", 14, a="start")

add("</svg>")
open("red-conmutacion.svg", "w").write("\n".join(o))
print("ok")
