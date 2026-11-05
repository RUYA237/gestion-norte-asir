from icons import *
import icons as _ic
def _wrap(name):
    f=getattr(_ic,name)
    return lambda *a,**k: o.append(f(*a,**k))
# o se define después; el wrapper la resuelve en tiempo de llamada
W,H=2000,1200
o=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><rect width="{W}" height="{H}" fill="#ffffff"/>',DEFS]
def T(x,y,s,size=14,anchor="start",bold=False,color="#222"):
    b=' font-weight="bold"' if bold else ''
    o.append(f'<text x="{x}" y="{y}" font-family="Arial" font-size="{size}" text-anchor="{anchor}" fill="{color}"{b}>{s}</text>')
def L(pts,color="#333",w=2,dash=None):
    p=" ".join(f"{a},{b}" for a,b in pts)
    d=f' stroke-dasharray="{dash}"' if dash else ""
    o.append(f'<polyline points="{p}" fill="none" stroke="{color}" stroke-width="{w}"{d}/>')
def SEDE(x,y,w,h,title,sub,color="#2b6cb0"):
    o.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="12" fill="#eef6fd" stroke="{color}" stroke-width="2"/>')
    T(x+16,y+28,title,20,bold=True,color=color)
    T(x+16,y+50,sub,13,color="#444")
def VBOX(x,y,w,h,title,color):
    o.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="8" fill="#ffffff" stroke="{color}" stroke-width="2"/>')
    T(x+w/2,y+22,title,12,anchor="middle",bold=True,color=color)
def CARD(x,y,vlan,name,kind,count,col):
    o.append(f'<rect x="{x}" y="{y}" width="78" height="140" rx="8" fill="#ffffff" stroke="{col}" stroke-width="2"/>')
    T(x+39,y+18,vlan,11,anchor="middle",bold=True,color=col)
    T(x+39,y+32,name,11,anchor="middle",color=col)
    if kind=="pc":
        pc(x+20,y+44,0.7); o.append(pc(x+20,y+44,0.7)) if False else None
        T(x+39,y+100,count,15,anchor="middle",bold=True)
    elif kind=="net":
        T(x+39,y+62,"rt-hue" if False else "red de",10,anchor="middle",color="#555")
        T(x+39,y+76,"gestión",10,anchor="middle",color="#555")
    elif kind=="printer":
        printer(x+24,y+44,0.6)
        T(x+39,y+100,count,12,anchor="middle",bold=True)
    elif kind=="ap":
        ap(x+25,y+44,0.9)
        T(x+39,y+100,count,12,anchor="middle",bold=True)

pc=_wrap('pc'); switch=_wrap('switch'); router=_wrap('router'); firewall=_wrap('firewall')
server=_wrap('server'); printer=_wrap('printer'); ap=_wrap('ap')
# ---- titulo
T(40,46,"Gestión Norte · Red propuesta (3 sedes + teletrabajo)",28,bold=True)
T(40,74,"Direcciones 10.&lt;sede&gt;.&lt;VLAN&gt;.0/24 · sedes: 1 Zaragoza, 2 Huesca, 3 Teruel · puestos: 110 + 25 + 15 = 150",14,color="#555")

# ---- Internet y operadores
o.append(cloud(1250,85,300,90,"Internet"))
L([(335,168),(335,130)]); L([(595,168),(595,130)])
L([(335,130),(1250,130)],color="#333",w=2)
router(300,190); router(560,190)
T(335,250,"Operador A · fibra",13,anchor="middle")
T(595,250,"Operador B · fibra",13,anchor="middle")
# teletrabajo
pc(40,170,1.0)
T(40,240,"Teletrabajo · 65",15,bold=True)
T(40,258,"OpenVPN + TOTP",13,color="#555")

# ---- ZARAGOZA
SEDE(40,290,1290,820,"ZARAGOZA · 110 puestos · 10.1.x.x","Sede principal · CPD y oficina")
L([(335,216),(640,340)],color="#333",w=2)
L([(630,203),(858,340)],color="#333",w=2)
firewall(640,320); firewall(860,320)
T(662,306,"ubu-fw1 · activo",14,anchor="middle",bold=True)
T(882,306,"ubu-fw2 · respaldo",14,anchor="middle",bold=True)
L([(684,350),(860,350)],color="#888",w=2,dash="5,4")
T(772,343,"VRRP",11,anchor="middle",color="#666")
# núcleos
switch(600,480,190); switch(900,480,190)
T(586,506,"Núcleo 1 · raíz STP",14,anchor="end",bold=True)
T(1100,506,"Núcleo 2 · respaldo",14,anchor="start",bold=True)
L([(790,500),(900,500)],color="#333",w=3)
L([(662,380),(695,480)]); L([(662,380),(995,480)])
L([(882,380),(695,480)]); L([(882,380),(995,480)])
# accesos
switch(90,620,220); switch(400,620,220); switch(710,620,220)
T(212,676,"Acceso 1 · planta 1",12)
T(522,676,"Acceso 2 · planta 1",12)
T(832,676,"Acceso 3 · planta 2",12)
for ax in (200,510,820):
    L([(ax,620),(695,520)],color="#777",w=1.5)
    L([(ax,620),(995,520)],color="#777",w=1.5)
    L([(ax,660),(ax,700)],color="#999",w=1.5)
# bus VLAN
L([(145,700),(1253,700)],color="#999",w=1.5,dash="4,3")
# VLAN de Zaragoza
G="#1e8e3e"; O="#e8590c"
VBOX(60,720,170,220,"VLAN 10 · Gestión IT",G)
for x in (75,150): pc(x,780,0.9)
T(145,860,"2 PAW",14,anchor="middle")
L([(145,700),(145,720)],color="#999",w=1.5)
VBOX(245,720,250,220,"VLAN 20 · Servidores",G)
for i,n in enumerate(["dc1","dc2","ubu-svc","wazuh01","bkp01"]):
    server(262+i*46,770,0.9); T(262+i*46+13,850,n,10,anchor="middle")
T(370,890,"solo en Zaragoza",12,anchor="middle",color="#555")
L([(370,700),(370,720)],color="#999",w=1.5)
VBOX(510,720,160,220,"VLAN 30 · Laboral",G)
pc(540,780,0.85); pc(600,780,0.85); T(590,890,"× 44",16,anchor="middle",bold=True)
L([(590,700),(590,720)],color="#999",w=1.5)
VBOX(685,720,160,220,"VLAN 40 · Fiscal",G)
pc(715,780,0.85); pc(775,780,0.85); T(765,890,"× 33",16,anchor="middle",bold=True)
L([(765,700),(765,720)],color="#999",w=1.5)
VBOX(860,720,160,220,"VLAN 50 · Admin.",G)
pc(890,780,0.85); pc(950,780,0.85); T(940,890,"× 18",16,anchor="middle",bold=True)
L([(940,700),(940,720)],color="#999",w=1.5)
VBOX(1035,720,150,220,"VLAN 60 · Atención",G)
pc(1065,780,0.85); T(1110,890,"× 15",16,anchor="middle",bold=True)
L([(1110,700),(1110,720)],color="#999",w=1.5)
VBOX(1197,720,113,220,"VLAN 70",O)
printer(1215,790,1.0); T(1253,890,"× 7",14,anchor="middle",bold=True)
L([(1253,700),(1253,720)],color="#999",w=1.5)
VBOX(1197,960,113,110,"VLAN 80",O)
ap(1220,1000,1.0)
T(1253,1080,"invitados",11,anchor="middle",color=O)
L([(1253,700),(1253,960)],color="#e8590c",w=0) if False else None
T(40,1138,"Matriz de permisos: los departamentos no se ven entre sí; acceden a servidores (AD, ficheros), impresoras e Internet.",13,color="#555")

# ---- HUESCA
SEDE(1370,290,590,310,"HUESCA · 25 puestos","10.2.x.x · 4 switches redundantes")
router(1395,366)
T(1386,412,"rt-hue",12,anchor="start",bold=True)
SW=[1490,1605,1720,1835]
for i,sx in enumerate(SW):
    switch(sx,372,110); T(sx+55,366,f"SW{i+1}",11,anchor="middle",bold=True)
    L([(sx+55,412),(sx+55,426)],color="#555",w=1.5)
L([(1465,380),(1490,392)])
L([(1425,426),(1890,426)],color="#555",w=1.5)
cols=[("VLAN 10","Gestión",'net',"",  "#6b7a90"),("VLAN 30","Laboral",'pc',"× 10",G),("VLAN 40","Fiscal",'pc',"× 7",G),
      ("VLAN 50","Admin.",'pc',"× 4",G),("VLAN 60","Atención",'pc',"× 4",G),("VLAN 70","Impresoras",'printer',"× pend.",O),("VLAN 80","Invitados",'ap',"Wi-Fi",O)]
for i,(v,n,k,c,col) in enumerate(cols):
    x=1386+i*82
    CARD(x,440,v,n,k,c,col)
    L([(x+39,426),(x+39,440)],color="#777",w=1.2)

# ---- TERUEL
SEDE(1370,680,590,310,"TERUEL · 15 puestos","10.3.x.x · 4 switches redundantes")
router(1395,756)
T(1386,812,"rt-ter",12,anchor="start",bold=True)
SW=[1490,1605,1720,1835]
for i,sx in enumerate(SW):
    switch(sx,762,110); T(sx+55,756,f"SW{i+1}",11,anchor="middle",bold=True)
    L([(sx+55,802),(sx+55,822)],color="#555",w=1.5)
L([(1465,770),(1490,782)])
L([(1425,822),(1890,822)],color="#555",w=1.5)
cols2=[("VLAN 10","Gestión",'net',"",  "#6b7a90"),("VLAN 30","Laboral",'pc',"× 6",G),("VLAN 40","Fiscal",'pc',"× 5",G),
      ("VLAN 50","Admin.",'pc',"× 3",G),("VLAN 60","Atención",'pc',"× 1",G),("VLAN 70","Impresoras",'printer',"× pend.",O),("VLAN 80","Invitados",'ap',"Wi-Fi",O)]
for i,(v,n,k,c,col) in enumerate(cols2):
    x=1386+i*82
    CARD(x,830,v,n,k,c,col)
    L([(x+39,822),(x+39,830)],color="#777",w=1.2)

# ---- túneles WireGuard (uno por sede, terminan en ubu-fw2)
P="#7a5af8"
L([(1395,380),(1352,380),(1352,340),(904,340)],color=P,w=2,dash="8,5")
L([(1395,769),(1342,769),(1342,360),(904,360)],color=P,w=2,dash="8,5")
T(1100,332,"túnel WireGuard · Huesca",12,color=P)
T(1100,378,"túnel WireGuard · Teruel",12,color=P)

# ---- notas
T(40,1160,"VLAN 80 (invitados): sin ruta a la red de empresa; solo sale a Internet. Impresoras de Huesca y Teruel: pendiente de inventario.",13,color="#555")
T(40,1182,"Estado: propuesta, pendiente de verificar (puestos, cableado, equipos reutilizables). Sin 4G: enlaces por fibra.",13,color="#555")
o.append('</svg>')
open("red-propuesta.svg","w").write("\n".join(o))
print("ok")
