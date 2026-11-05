# Plan de direcciones de la maqueta (v2)

Convención: 10.<sede>.<VLAN>.0/24, puerta de enlace .1 en el router de la sede.
Sede 1 = Zaragoza, 2 = Huesca, 3 = Teruel. Túneles y loopbacks en 10.255.0.0/16.

| VLAN | Uso | Zaragoza | Huesca | Teruel |
|---|---|---|---|---|
| 10 | Gestión IT | 10.1.10.0/24 | 10.2.10.0/24 | 10.3.10.0/24 |
| 20 | Servidores (solo Zaragoza) | 10.1.20.0/24 | — | — |
| 30 | Laboral | 10.1.30.0/24 | 10.2.30.0/24 | 10.3.30.0/24 |
| 40 | Fiscal | 10.1.40.0/24 | 10.2.40.0/24 | 10.3.40.0/24 |
| 50 | Administración | 10.1.50.0/24 | — | — |
| 60 | Atención | 10.1.60.0/24 | — | — |
| 70 | Impresoras | 10.1.70.0/24 | — | — |
| 80 | Invitados (Wi-Fi) | 10.1.80.0/24 | 10.2.80.0/24 | 10.3.80.0/24 |

Nota: en la maqueta solo se cablean las VLAN necesarias para probar; el reparto
de puestos completo (110/25/15) está en el diagrama, no en la maqueta.

## Enlaces de Internet (inet simula a los operadores)
| Enlace | inet | Extremo |
|---|---|---|
| Zaragoza (fibra) | 203.0.113.1/30 (eth1) | ubu-fw 203.0.113.2/30 (wan) |
| Huesca (fibra) | 203.0.113.5/30 (eth2) | rt-hue 203.0.113.6/30 (wan) |
| Teruel (fibra) | 203.0.113.9/30 (eth3) | rt-ter 203.0.113.10/30 (wan) |

## Túneles WireGuard (uno por sede, terminan en ubu-fw)
| Túnel | Extremo sede | Extremo ubu-fw | Puerto ubu-fw | Red del túnel |
|---|---|---|---|---|
| wg-hue | rt-hue 10.255.12.2/30 | 10.255.12.1/30 | 51820/udp | 10.255.12.0/30 |
| wg-ter | rt-ter 10.255.13.2/30 | 10.255.13.1/30 | 51821/udp | 10.255.13.0/30 |

## Loopbacks (router-id OSPF)
ubu-fw 10.255.0.1 · rt-hue 10.255.0.2 · rt-ter 10.255.0.3

## Hosts de prueba
srv-dc1 10.1.20.10 · pc-it 10.1.10.10 · pc-lab-zgz 10.1.30.50 · pc-fis-zgz 10.1.40.50 ·
pc-adm-zgz 10.1.50.50 · pc-atn-zgz 10.1.60.50 · prn-zgz 10.1.70.20 · pc-inv-zgz 10.1.80.50 ·
pc-lab-hue 10.2.30.50 · pc-fis-hue 10.2.40.50 · pc-inv-hue 10.2.80.50 ·
pc-fis-ter 10.3.40.50 · pc-inv-ter 10.3.80.50
