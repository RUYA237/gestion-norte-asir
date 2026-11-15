# Plan de direcciones de la maqueta (versión final, 26 nodos)

Convención: 10.<sede>.<VLAN>.0/24, puerta de enlace .1. Sede 1 = Zaragoza, 2 = Huesca, 3 = Teruel.

## VLAN montadas en la maqueta

| VLAN | Uso | Zaragoza | Huesca | Teruel |
|---|---|---|---|---|
| 10 | Gestión IT | 10.1.10.0/24 | no montada | no montada |
| 20 | Servidores | 10.1.20.0/24 | no existe | no existe |
| 30 | Laboral | 10.1.30.0/24 | 10.2.30.0/24 | no montada |
| 40 | Fiscal | 10.1.40.0/24 | 10.2.40.0/24 | 10.3.40.0/24 |
| 50 | Administración | 10.1.50.0/24 | no montada | no montada |
| 60 | Atención | 10.1.60.0/24 | no montada | no montada |
| 70 | Impresoras | 10.1.70.0/24 | no montada | no montada |
| 80 | Invitados | 10.1.80.0/24 | 10.2.80.0/24 | 10.3.80.0/24 |

El diseño de producción (memoria, apartado 4.2.1) lleva las VLAN 10, 30 a 60, 70 y 80 a las tres sedes. La maqueta solo monta en Huesca y Teruel las necesarias para probar el enrutamiento entre sedes.

## Enlaces

| Enlace | Red | Extremo ubu-fw | Otro extremo |
|---|---|---|---|
| Internet simulado | 203.0.113.0/30 | 203.0.113.2 (wan) | inet 203.0.113.1; inet tiene además 8.8.8.8/32 |
| Huesca (enlace directo; túnel WireGuard propuesto) | 10.255.12.0/30 | 10.255.12.1 (eth2) | rt-hue 10.255.12.2 |
| Teruel (enlace directo; túnel WireGuard propuesto) | 10.255.13.0/30 | 10.255.13.1 (eth3) | rt-ter 10.255.13.2 |

Identificadores: ubu-fw 10.255.0.1, rt-hue 10.255.0.2, rt-ter 10.255.0.3.

## Rutas

- ubu-fw: 10.2.0.0/16 por 10.255.12.2, 10.3.0.0/16 por 10.255.13.2 y ruta por defecto por 203.0.113.1.
- rt-hue y rt-ter: ruta por defecto hacia ubu-fw.
- inet: 10.0.0.0/8 por 203.0.113.2 (sustituye al NAT, que la maqueta no simula).

## Equipos de prueba

| Equipo | Dirección | Switch y puerto |
|---|---|---|
| srv-dc1 (escucha en 445) | 10.1.20.10 | zgz-n1 eth6 |
| pc-it | 10.1.10.10 | zgz-a1 eth3 |
| pc-lab-zgz | 10.1.30.50 | zgz-a1 eth4 |
| pc-fis-zgz | 10.1.40.50 | zgz-a2 eth3 |
| pc-adm-zgz | 10.1.50.50 | zgz-a2 eth4 |
| pc-atn-zgz | 10.1.60.50 | zgz-a3 eth3 |
| prn-zgz | 10.1.70.20 | zgz-a3 eth4 |
| pc-inv-zgz | 10.1.80.50 | zgz-a3 eth5 |
| pc-lab-hue | 10.2.30.50 | sw-hue1 eth3 |
| pc-fis-hue | 10.2.40.50 | sw-hue1 eth4 |
| pc-inv-hue | 10.2.80.50 | sw-hue2 eth2 |
| pc-fis-ter | 10.3.40.50 | sw-ter1 eth3 |
| pc-inv-ter | 10.3.80.50 | sw-ter2 eth2 |
