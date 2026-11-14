# Bitácora de Arian

Una línea por sesión. Es la prueba de tu aportación individual en las cuatro rúbricas.

| Fecha | Módulo | Qué hice | Qué falló y cómo lo arreglé | Decisión o cambio | Evidencia / commit |
|---|---|---|---|---|---|
| 04/11 | SO | Promoción de dc1 (script 02), verificación (03), OU y AGDLP (04, 05), política de contraseñas (06), SMB cifrado (08) | Error de sintaxis en el script 05 (`$numFila:` y `$sam:`), corregido con `${numFila}:` | Estructura AGDLP con GG por sede y departamento y DL por recurso | evidencias/so/ (logs 02 a 08) |
| 06/11 | SO | Promoción de dc2 en Server Core (script 07) | DNS de dc2 apuntaba solo a sí mismo; corregido a `10.1.20.11, 10.1.20.10` | dc2 como controlador adicional en el sitio Zaragoza | Log 07-promover-dc2-20261106-105248.log |
| 11/11 | SO | Diagnóstico de replicación tras reiniciar dc1 | Error 8524 por DNS: DNS de dc1 apuntaba a dc2 primero y había AAAA link-local. Corregido con DNS de dc1, IPv6 apagado en LAN-VLAN20, flushdns y `repadmin /replicate` de CN=Configuration | Un DC se consulta primero a sí mismo | evidencias/so/replsummary-*.txt; ficha 16, sección 3 |
| 13/11 | SO | PDC movido a dc2; GPO de LAPS y BitLocker; firma LDAP obligatoria | Copia de la clave de BitLocker a AD rechazada localmente. Sin causa identificada | PDC en dc2 y hora desde dc2 | Ficha 16, secciones 5, 7 y 8 |
| 14/11 | SO | Prueba de caída de dc1; diagnóstico de DFSR (5008) y de la anomalía de acceso a Fiscal (P5); bloqueo de daniel.ortega | Puerto RPC de DFSR cambió al apagar dc2; resuelto con `Restart-Service DFSR`. Se corrigió el filtro LAPS (`msLAPS-*`) | Anomalía de P5 documentada como abierta, sin causa identificada | Commit 313729f (script 09); evidencias/so/p5-5140-fiscal-14-11.txt |