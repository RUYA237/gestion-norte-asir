# Lo que pide la rúbrica y no estaba planificado (27/10)

Comparación de las cuatro rúbricas y los 30 requisitos del enunciado con el plan del 27/10. Cada hueco tiene responsable y nivel (1 obligatorio · 2 si da tiempo · 3 propuesto).

## Transversal (afecta a las cuatro notas)
| Hueco | Qué pide | Acción | Quién | Nivel |
|---|---|---|---|---|
| **Bitácora individual** | Redes 5, SO 5, BD 5, Seg 4: "tareas propias, decisiones, dificultades y cambios", "errores encontrados y correcciones" | Un fichero por persona en `docs/bitacoras/`, una línea por sesión | Los tres | 1 |
| **Registro de incidencias del laboratorio** | Redes 3 "reconoce límites o incidencias"; memoria 8.3 | Cada fallo real: síntoma, causa, solución. Ya es evidencia | Los tres | 1 |
| **Diseño físico y presupuesto** | Redes 1 "dispositivos"; requisitos 9 y 30; presupuesto 75.000 € | Lista de equipos por sede (switches, AP, firewall, servidores, SAI), licencias y coste; roadmap para el cliente con fases y responsables | Raúl (red) · Arian (servidores y licencias) | 1 |
| **Módulo de aplicaciones web** | El enunciado lo cita, sin rúbrica | Preguntar al profesor | Raúl | — |

## Redes
| Hueco | Criterio | Acción | Nivel |
|---|---|---|---|
| Explicar prevención de conflictos con ejemplos | 2 | Prueba: IP duplicada (el script 01 de AD ya la detecta) y reserva Kea; captura del log de Kea | 1 |
| Dependencias de la red | 4 | Tabla: qué depende de ubu-fw, de los DC y del DNS, y qué pasa si cae cada uno | 1 |
| Wi-Fi y dispositivos | 1 | AP con SSID por VLAN (empleados e invitados) en el diseño; propuesto | 3 |

## Sistemas operativos
| Hueco | Criterio | Acción | Nivel |
|---|---|---|---|
| **Cuentas en Linux** | 2 | Usuarios con nombre en los Ubuntu, sudo por grupo, SSH solo con clave, root sin login | 1 |
| **Control de cambios** | 3 | Git como registro (commit = cambio) + plantilla de cambio: qué, por qué, quién, cómo volver atrás | 1 |
| Plan de actualizaciones con frecuencia | 3 | `unattended-upgrades` en Ubuntu, Windows Update por GPO, ventana mensual fuera de campaña fiscal | 1 |
| Registros del sistema | 4 | Visor de eventos y `journalctl` en el diagnóstico de la incidencia | 1 |
| Equipo cliente | intro | cli01: unión al dominio, `gpresult`, BitLocker, LAPS | 2 |

## Bases de datos
| Hueco | Criterio | Acción | Nivel |
|---|---|---|---|
| **El modelo no existe** | 1 y 2 (40 %) | `.sql` con entidades, claves, restricciones y 3FN | 1 · urgente |
| Duplicados del cliente | 1, req. 11 | `UNIQUE` en NIF/CIF y correo de clientes; explicarlo como solución a "duplicados en listas de clientes y facturas" | 1 |
| Integridad e inconsistencias | 2 | FK con `ON DELETE` razonado, `CHECK`, transacciones en una operación de negocio | 1 |
| **Mantenimiento del gestor** | 4 | `VACUUM`/`ANALYZE`, autovacuum, tamaño y conexiones con `pg_stat_*` | 1 |
| Retención y borrado de datos personales | req. 22 | Procedimiento de borrado o anonimización al vencer el plazo | 2 |

## Seguridad y alta disponibilidad
| Hueco | Criterio / requisito | Acción | Nivel |
|---|---|---|---|
| **Política de copias completa** | 3: alcance, periodicidad, custodia, responsables | Tabla: qué se copia, cada cuánto, dónde, quién y cuánto se guarda | 1 |
| **Clasificación de datos** | 1, req. 14 | Niveles: pública, interna, confidencial, especialmente protegida; ejemplos de la asesoría | 1 |
| **Políticas escritas** | req. 17 | Uso aceptable de una página: equipos, USB, dispositivos personales, correo | 1 |
| **Retención y eliminación** | 5, req. 22 | Calendario por tipo de dato (laboral, fiscal, bancario) | 1 |
| **Responsabilidades (RACI)** | 3 y 5, req. 21 y 29 | Quién decide, ejecuta y supervisa copias, parches, incidentes y altas/bajas; proveedores y SLA | 1 |
| Segregación de funciones | req. 27 | Permisos por departamento (AGDLP) y separación administrador/usuario (`adm_`) | 1 |
| Mejora tras el incidente | 5 | El simulacro termina con lecciones aprendidas y cambios | 1 |
| Formación | 5, req. 23 | Plan de formación con simulacro de phishing | 2 |
| Coherencia escrito/práctica | req. 28 | Cap. 2: pendiente de verificar con el cliente | — |
