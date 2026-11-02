#!/usr/bin/env python3
"""Diagrama de red de Gestión Norte (blanco y negro). Genera red-fisica.svg en el directorio actual."""
W, H = 1500, 1075
F = "Liberation Sans, Arial, sans-serif"
o = []
add = o.append

def esc(s): return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

def T(x, y, s, size=18, a="middle", b=False):
    for i, l in enumerate(s.split("\n")):
        add(f'<text x="{x}" y="{y + i*size*1.25:.0f}" font-family="{F}" font-size="{size}" text-anchor="{a}"'
            f'{" font-weight=\"bold\"" if b else ""}>{esc(l)}</text>')

def R(x, y, w, h, sw=1.5, dash=None, fill="#fff", rx=6):
    d = f' stroke-dasharray="{dash}"' if dash else ""
    add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}" stroke="#000" stroke-width="{sw}"{d}/>')

def L(pts, sw=2, dash=None):
    d = f' stroke-dasharray="{dash}"' if dash else ""
    add(f'<polyline points="{" ".join(f"{a},{b}" for a, b in pts)}" fill="none" stroke="#000" stroke-width="{sw}"{d}/>')

# --- iconos ---
def fw(cx, cy, s=1.0):
    w, h = 76*s, 54*s; x, y = cx-w/2, cy-h/2
    R(x, y, w, h, sw=2, fill="#d9d9d9", rx=3)
    for r in range(1, 4): L([(x, y+r*h/4), (x+w, y+r*h/4)], sw=1)
    for r in range(4):
        off = 0 if r % 2 == 0 else w/8
        c = off + w/4
        while c < w - 1:
            L([(x+c, y+r*h/4), (x+c, y+(r+1)*h/4)], sw=1); c += w/4

def sw_(cx, cy):
    R(cx-55, cy-13, 110, 26, sw=2, fill="#d9d9d9", rx=3)
    for k in range(7): R(cx-45+k*13, cy-5, 9, 9, sw=1, rx=1)

def srv(cx, cy):
    R(cx-15, cy-24, 30, 48, sw=1.6, fill="#d9d9d9", rx=3)
    for k in range(4): L([(cx-9, cy-15+k*10), (cx+9, cy-15+k*10)], sw=1.4)

def pc(cx, cy):
    R(cx-21, cy-17, 42, 28, sw=1.6, fill="#eee", rx=2)
    L([(cx, cy+11), (cx, cy+17)], sw=2); L([(cx-11, cy+18), (cx+11, cy+18)], sw=2)

def prn(cx, cy):
    R(cx-12, cy-19, 24, 10, sw=1.4, rx=1)
    R(cx-22, cy-9, 44, 20, sw=1.6, fill="#d9d9d9", rx=3)
    R(cx-12, cy+7, 24, 10, sw=1.4, rx=1)

def ap(cx, cy):
    R(cx-19, cy+2, 38, 12, sw=1.6, fill="#d9d9d9", rx=4)
    for dx in (-12, 0, 12): L([(cx+dx, cy+2), (cx+dx*1.3, cy-16)], sw=1.6)

def bad(cx, cy):
    pc(cx, cy); L([(cx-12, cy-12), (cx+12, cy+6)], sw=2); L([(cx+12, cy-12), (cx-12, cy+6)], sw=2)

def router(cx, cy):
    add(f'<ellipse cx="{cx}" cy="{cy}" rx="30" ry="18" fill="#d9d9d9" stroke="#000" stroke-width="2"/>')
    for dx, dy in ((-14, -6), (14, 6)):
        L([(cx-dx*0.2, cy+dy*0.2), (cx+dx, cy+dy)], sw=2)
    L([(cx-14, cy+6), (cx-3, cy+6)], sw=2); L([(cx+14, cy-6), (cx+3, cy-6)], sw=2)

def chip(x, y, w, h, vlan, name, icon, lab=False, dash=None):
    R(x, y, w, h, sw=3 if lab else 1.4, dash=dash)
    icon(x+w/2, y+40)
    T(x+w/2, y+h-34, vlan, 17, b=True)
    T(x+w/2, y+h-13, name, 16)

def mini(x, y, w, vlan, name, dash=None):
    R(x, y, w, 52, sw=1.4, dash=dash, rx=5)
    T(x+w/2, y+22, vlan, 16, b=True)
    T(x+w/2, y+43, name, 16)

# ================= LIENZO =================
add(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><rect width="{W}" height="{H}" fill="#fff"/>')
T(30, 42, "Gestión Norte · Red propuesta", 28, a="start", b=True)
T(30, 72, "Redes 10.<sede>.<vlan>.0/24 · el mismo número de VLAN tiene el mismo uso en todas las sedes", 18, a="start")

# Internet
add('<ellipse cx="750" cy="132" rx="120" ry="38" fill="#f0f0f0" stroke="#000" stroke-width="2"/>')
T(750, 139, "Internet", 22, b=True)

# Teletrabajo
R(30, 100, 330, 74)
pc(68, 137)
T(102, 130, "Teletrabajo (65 personas)", 18, a="start", b=True)
T(102, 155, "OpenVPN + doble factor", 17, a="start")
L([(195, 174), (195, 205), (712, 205), (722, 222)], sw=2, dash="9 6")

# ubu-fw (hub central)
L([(750, 170), (750, 222)], sw=2.5)
fw(750, 250)
T(700, 238, "ubu-fw · firewall central", 20, a="end", b=True)
T(700, 262, "único punto de entrada y salida", 17, a="end")
T(700, 284, "(físicamente en el CPD de Zaragoza)", 17, a="end")

# Túneles a Huesca y Teruel
L([(788, 250), (1215, 250), (1215, 625), (940, 625), (940, 650)], sw=2, dash="9 6")
L([(1215, 625), (1295, 625), (1295, 650)], sw=2, dash="9 6")
T(1232, 300, "Túneles WireGuard", 18, a="start", b=True)
T(1232, 324, "por la fibra de cada sede;", 17, a="start")
T(1232, 346, "todo su tráfico pasa", 17, a="start")
T(1232, 368, "por ubu-fw", 17, a="start")

# Núcleo central
L([(750, 277), (750, 352)], sw=2.5)
R(330, 330, 860, 255, sw=2.6, rx=10)
T(350, 358, "Núcleo central", 20, a="start", b=True)
T(350, 381, "CPD de Zaragoza", 17, a="start")
sw_(750, 365)
L([(750, 378), (750, 400)], sw=2)
L([(345, 400), (848, 400)], sw=2)
L([(445, 400), (445, 420)], sw=1.6); L([(848, 400), (848, 420)], sw=1.6)
# VLAN 10
R(360, 420, 170, 150, sw=3)
T(445, 444, "VLAN 10", 17, b=True); T(445, 465, "Gestión IT", 16)
pc(445, 505); T(445, 552, "2 puestos", 16)
# VLAN 20
R(545, 420, 630, 150, sw=3)
T(860, 444, "VLAN 20 · Servidores", 17, b=True)
for k, (n, d) in enumerate([("dc1", "AD · ficheros"), ("dc2", "AD"), ("ubu-svc", "BD · Zabbix"),
                            ("wazuh01", "SIEM"), ("bkp01", "copias")]):
    cx = 608 + k*126
    srv(cx, 492); T(cx, 538, n, 16, b=True); T(cx, 558, d, 15)

# Zaragoza (LAN directa al núcleo)
L([(345, 400), (345, 625), (390, 625), (390, 650)], sw=2.5)
T(400, 616, "LAN · troncal 802.1Q", 16, a="start")
R(30, 650, 720, 335, sw=2.6, rx=10)
T(50, 680, "Zaragoza · 110 puestos · 10.1.x.x", 20, a="start", b=True)
cw, ch, gx = 160, 128, 12
xs = [50 + k*(cw+gx) for k in range(4)]
chip(xs[0], 698, cw, ch, "VLAN 30", "Laboral · 44", pc, lab=True)
chip(xs[1], 698, cw, ch, "VLAN 40", "Fiscal · 33", pc, lab=True)
chip(xs[2], 698, cw, ch, "VLAN 50", "Administr. · 18", pc)
chip(xs[3], 698, cw, ch, "VLAN 60", "Atención · 15", pc)
chip(xs[0], 840, cw, ch, "VLAN 70", "Impresoras · 7", prn)
chip(xs[1], 840, cw, ch, "VLAN 80", "Wi-Fi visitas", ap)
chip(xs[2], 840, cw, ch, "VLAN 99", "Cuarentena W7", bad, dash="8 5")
T(xs[3]+4, 872, "Departamentos:", 15, a="start", b=True)
T(xs[3]+4, 893, "no se ven entre sí;", 15, a="start")
T(xs[3]+4, 914, "Wi-Fi visitas:", 15, a="start", b=True)
T(xs[3]+4, 935, "solo Internet", 15, a="start")

# Sedes remotas
def sede(x, name, sub, rt, n, prns):
    R(x, 650, 335, 335, sw=2.6, rx=10)
    T(x+18, 680, name, 20, a="start", b=True)
    T(x+18, 703, sub, 17, a="start")
    router(x+48, 742)
    T(x+90, 738, rt, 17, a="start", b=True)
    T(x+90, 760, "router con VPN, sin servidor", 15, a="start")
    mw = 150
    c1, c2 = x+12, x+12+mw+11
    mini(c1, 782, mw, "VLAN 30", f"Laboral · {n[0]}"); mini(c2, 782, mw, "VLAN 40", f"Fiscal · {n[1]}")
    mini(c1, 840, mw, "VLAN 50", f"Administr. · {n[2]}"); mini(c2, 840, mw, "VLAN 60", f"Atención · {n[3]}")
    mini(c1, 898, mw, "VLAN 70", f"Impresoras · {prns}"); mini(c2, 898, mw, "VLAN 80", "Wi-Fi visitas")
    T(x+18, 973, "VLAN 99 solo si hay equipos W7", 15, a="start")

sede(772, "Huesca · 25 puestos", "10.2.x.x", "rt-hue", (10, 7, 4, 4), 3)
sede(1135, "Teruel · 15 puestos", "10.3.x.x", "rt-ter", (6, 5, 3, 1), 2)

# Leyenda
y = 1012
L([(30, y), (90, y)], sw=2.5); T(98, y+6, "enlace físico", 16, a="start")
L([(235, y), (295, y)], sw=2, dash="9 6"); T(303, y+6, "túnel cifrado por Internet", 16, a="start")
R(530, y-12, 40, 24, sw=3); T(578, y+6, "se monta en el laboratorio", 16, a="start")
R(800, y-12, 40, 24, sw=1.4, dash="8 5"); T(848, y+6, "temporal (equipos con Windows 7)", 16, a="start")
T(30, y+40, "Puestos por departamento en cada sede: estimación proporcional, pendiente de verificar. "
            "Impresoras por sede: dato del cliente (28/10). Cuarta sede futura: 10.4.x.x con el mismo esquema que Huesca y Teruel.", 15, a="start")

add("</svg>")
open("red-fisica.svg", "w").write("\n".join(o))
print("ok")
