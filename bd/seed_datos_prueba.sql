
BEGIN;


-- 1. Catálogos --------------------------------------------------------
INSERT INTO departamento (id_departamento, nombre) VALUES
(1, 'Laboral'),
(2, 'Fiscal'),
(3, 'Administración'),
(4, 'Atención al cliente');

INSERT INTO servicio (id_servicio, codigo, nombre, id_departamento) VALUES
(1, 'LAB', 'Asesoría laboral', 1),
(2, 'NOM', 'Gestión de nóminas', 1),
(3, 'FIS', 'Asesoría fiscal', 2),
(4, 'IMP', 'Declaración de impuestos', 2),
(5, 'CON', 'Contabilidad', 3),
(6, 'TRA', 'Trámites y gestiones', 4);

INSERT INTO tipo_documento (id_tipo_documento, nombre, nivel, anios_conservacion) VALUES
(1, 'Contrato de trabajo', 'CONFIDENCIAL', 5),
(2, 'Nómina', 'ESPECIAL', 4),
(3, 'Factura', 'INTERNA', 6);

INSERT INTO tipo_obligacion (id_tipo_obligacion, codigo, nombre, ambito, periodicidad) VALUES
(1, '303', 'Autoliquidación de IVA', 'F', 'T'),
(2, '111', 'Retenciones e ingresos a cuenta del IRPF', 'F', 'T'),
(3, '130', 'Pago fraccionado del IRPF (autónomos)', 'F', 'T'),
(4, '200', 'Impuesto sobre Sociedades', 'F', 'A'),
(5, 'TC1', 'Cotizaciones a la Seguridad Social', 'L', 'M');

-- 2. Empleados de la asesoría ------------------------------------------
INSERT INTO empleado (id_empleado, id_departamento, sede, usuario_ad, nombre, apellidos, email, activo) VALUES
(1,  1, 'ZARAGOZA', 'emp01', 'Laura',  'Martínez Gil',   'emp01@gestionnorte.example', true),
(2,  1, 'HUESCA',   'emp02', 'Carlos', 'López Serrano',  'emp02@gestionnorte.example', true),
(3,  1, 'ZARAGOZA', 'emp03', 'Marta',  'Sánchez Blanco', 'emp03@gestionnorte.example', true),
(4,  2, 'ZARAGOZA', 'emp04', 'Javier', 'Pérez Molina',   'emp04@gestionnorte.example', true),
(5,  2, 'TERUEL',   'emp05', 'Elena',  'Gómez Ortega',   'emp05@gestionnorte.example', true),
(6,  2, 'ZARAGOZA', 'emp06', 'Sergio', 'Ruiz Castro',    'emp06@gestionnorte.example', true),
(7,  3, 'ZARAGOZA', 'emp07', 'Paula',  'Díaz Ramos',     'emp07@gestionnorte.example', true),
(8,  3, 'HUESCA',   'emp08', 'Diego',  'Moreno Navarro', 'emp08@gestionnorte.example', true),
(9,  4, 'ZARAGOZA', 'emp09', 'Lucía',  'Alonso Torres',  'emp09@gestionnorte.example', true),
(10, 4, 'ZARAGOZA', 'emp10', 'Adrián', 'Domínguez Gil',  'emp10@gestionnorte.example', true),
(11, 4, 'TERUEL',   'emp11', 'Nuria',  'Serrano Blanco', 'emp11@gestionnorte.example', true),
(12, 4, 'HUESCA',   'emp12', 'Pablo',  'Molina Ortega',  'emp12@gestionnorte.example', false);

-- 3. Clientes: 1-14 empresas (E), 15-20 autónomos (A) -------------------
INSERT INTO cliente (id_cliente, tipo_cliente, nif, denominacion, direccion, codigo_postal, localidad, telefono, email, fecha_alta, fecha_baja) VALUES
(1,  'E', 'B50000001', 'Talleres Ebro S.L.',              'Calle del Coso 10',      '50003', 'Zaragoza',              '976100001', 'info@talleresebro.example',          '2019-04-01', NULL),
(2,  'E', 'B50000002', 'Hostelería Pirineos S.L.',        'Avenida Pirineos 4',     '22001', 'Huesca',                '974200002', 'info@hosteleriapirineos.example',    '2019-05-01', NULL),
(3,  'E', 'B50000003', 'Construcciones Moncayo S.L.',     'Calle Mayor 22',         '44001', 'Teruel',                '978300003', 'info@construccionesmoncayo.example', '2019-06-01', NULL),
(4,  'E', 'B50000004', 'Clínica San Jorge S.L.',          'Calle San Jorge 7',      '50001', 'Zaragoza',              '976100004', 'admin@clinicasanjorge.example',      '2020-01-15', NULL),
(5,  'E', 'B50000005', 'Distribuciones Monegros S.L.',    'Polígono Norte, nave 5', '50300', 'Calatayud',             '976100005', 'info@distribucionesmonegros.example','2020-03-01', NULL),
(6,  'E', 'B50000006', 'Transportes del Jalón S.L.',      'Calle Alfonso I 16',     '50010', 'Zaragoza',              '976100006', 'info@transportesjalon.example',      '2020-06-01', NULL),
(7,  'E', 'B50000007', 'Agroalimentaria Somontano S.L.',  'Carretera de Huesca 3',  '22300', 'Barbastro',             '974300007', 'info@agrosomontano.example',         '2021-02-01', NULL),
(8,  'E', 'B50000008', 'Ferretería Maestrazgo S.L.',      'Calle Goya 8',           '44600', 'Alcañiz',               '978400008', 'info@ferreteriamaestrazgo.example',  '2021-05-01', NULL),
(9,  'E', 'B50000009', 'Comercial Cinco Villas S.L.',     'Calle Costa 12',         '50600', 'Ejea de los Caballeros','976100009', 'info@comercialcincovillas.example',  '2021-09-01', NULL),
(10, 'E', 'B50000010', 'Servicios Pueyo S.L.',            'Calle San Jorge 30',     '50018', 'Zaragoza',              '976100010', 'info@serviciospueyo.example',        '2022-01-10', NULL),
(11, 'E', 'B50000011', 'Panadería La Concepción S.L.',    'Calle del Coso 55',      '22002', 'Huesca',                '974200011', 'info@panaderialaconcepcion.example', '2022-03-01', NULL),
(12, 'E', 'B50000012', 'Electricidad Bajo Aragón S.L.',   'Calle Goya 41',          '44600', 'Alcañiz',               '978400012', 'info@electricidadbajoaragon.example','2022-07-01', NULL),
(13, 'E', 'B50000013', 'Gestorías Ribera S.L.',           'Calle Alfonso I 80',     '50012', 'Zaragoza',              '976100013', 'info@gestoriasribera.example',       '2023-01-01', NULL),
(14, 'E', 'B50000014', 'Reformas Tarazona S.L.',          'Calle Mayor 9',          '50500', 'Tarazona',              '976100014', 'info@reformastarazona.example',      '2023-04-01', NULL),
(15, 'A', '17000015A', 'Ana Lasheras Gracia',             'Calle Costa 4',          '50001', 'Zaragoza',              '976200015', 'ana.lasheras@example.com',           '2021-10-01', NULL),
(16, 'A', '17000016B', 'Luis Abadía Tena',                'Calle Goya 19',          '22001', 'Huesca',                '974200016', 'luis.abadia@example.com',            '2022-02-01', NULL),
(17, 'A', '17000017C', 'Pilar Bernad Allué',              'Calle Mayor 30',         '44001', 'Teruel',                '978300017', 'pilar.bernad@example.com',           '2022-06-01', NULL),
(18, 'A', '17000018D', 'Jorge Cativiela Betrán',          'Calle del Coso 77',      '50010', 'Zaragoza',              '976200018', 'jorge.cativiela@example.com',        '2023-03-01', NULL),
(19, 'A', '17000019E', 'Carmen Escartín Lafuente',        'Calle Costa 25',         '22300', 'Barbastro',             '974300019', 'carmen.escartin@example.com',        '2023-09-01', NULL),
(20, 'A', '17000020F', 'Raúl Mairal Tena',                'Calle Alfonso I 2',      '44600', 'Alcañiz',               '978400020', 'raul.mairal@example.com',            '2024-01-01', '2026-06-30');

-- Una persona de contacto por cliente
INSERT INTO contacto_cliente (id_contacto, id_cliente, nombre, cargo, telefono, email) VALUES
(1,  1,  'Pilar Gracia',     'Gerencia',       '976100101', 'pilar.gracia@talleresebro.example'),
(2,  2,  'Jorge Lanzuela',   'Gerencia',       '974200102', 'jorge.lanzuela@hosteleriapirineos.example'),
(3,  3,  'Rosa Mairal',      'Administración', '978300103', 'rosa.mairal@construccionesmoncayo.example'),
(4,  4,  'Andrés Pueyo',     'Gerencia',       '976100104', 'andres.pueyo@clinicasanjorge.example'),
(5,  5,  'Isabel Oliván',    'Administración', '976100105', 'isabel.olivan@distribucionesmonegros.example'),
(6,  6,  'Carlos Sanz',      'Gerencia',       '976100106', 'carlos.sanz@transportesjalon.example'),
(7,  7,  'Marta Escartín',   'Administración', '974300107', 'marta.escartin@agrosomontano.example'),
(8,  8,  'Raúl Bernad',      'Gerencia',       '978400108', 'raul.bernad@ferreteriamaestrazgo.example'),
(9,  9,  'Sara Allué',       'Administración', '976100109', 'sara.allue@comercialcincovillas.example'),
(10, 10, 'Óscar Cativiela',  'Gerencia',       '976100110', 'oscar.cativiela@serviciospueyo.example'),
(11, 11, 'Lucía Tena',       'Administración', '974200111', 'lucia.tena@panaderialaconcepcion.example'),
(12, 12, 'Hugo Betrán',      'Gerencia',       '978400112', 'hugo.betran@electricidadbajoaragon.example'),
(13, 13, 'Ainhoa Lafuente',  'Administración', '976100113', 'ainhoa.lafuente@gestoriasribera.example'),
(14, 14, 'Víctor Marco',     'Gerencia',       '976100114', 'victor.marco@reformastarazona.example'),
(15, 15, 'Ana Lasheras',     'Titular',        '976200115', 'ana.lasheras@example.com'),
(16, 16, 'Luis Abadía',      'Titular',        '974200116', 'luis.abadia@example.com'),
(17, 17, 'Pilar Bernad',     'Titular',        '978300117', 'pilar.bernad@example.com'),
(18, 18, 'Jorge Cativiela',  'Titular',        '976200118', 'jorge.cativiela@example.com'),
(19, 19, 'Carmen Escartín',  'Titular',        '974300119', 'carmen.escartin@example.com'),
(20, 20, 'Raúl Mairal',      'Titular',        '978400120', 'raul.mairal@example.com');

-- 4. Contrataciones: cada cliente tiene de 2 a 3 servicios ------------------
INSERT INTO contratacion (id_contratacion, id_cliente, id_servicio, id_empleado_responsable, fecha_alta, fecha_baja, cuota_mensual) VALUES
(1,  1,  1, 1,  '2024-01-01', NULL,         180.00),
(2,  2,  1, 2,  '2024-01-01', NULL,         180.00),
(3,  3,  1, 3,  '2024-01-01', NULL,         180.00),
(4,  4,  1, 1,  '2024-01-01', NULL,         180.00),
(5,  5,  1, 2,  '2024-01-01', NULL,         180.00),
(6,  6,  1, 3,  '2024-01-01', NULL,         180.00),
(7,  7,  1, 1,  '2024-01-01', NULL,         180.00),
(8,  8,  1, 2,  '2024-01-01', NULL,         180.00),
(9,  9,  1, 3,  '2024-01-01', NULL,         180.00),
(10, 10, 1, 1,  '2024-01-01', NULL,         180.00),
(11, 11, 1, 2,  '2024-01-01', NULL,         180.00),
(12, 12, 1, 3,  '2024-01-01', NULL,         180.00),
(13, 13, 1, 1,  '2024-01-01', NULL,         180.00),
(14, 14, 1, 2,  '2024-01-01', NULL,         180.00),
(15, 1,  3, 4,  '2024-01-01', NULL,         220.00),
(16, 2,  3, 5,  '2024-01-01', NULL,         220.00),
(17, 3,  3, 6,  '2024-01-01', NULL,         220.00),
(18, 4,  3, 4,  '2024-01-01', NULL,         220.00),
(19, 5,  3, 5,  '2024-01-01', NULL,         220.00),
(20, 6,  3, 6,  '2024-01-01', NULL,         220.00),
(21, 7,  3, 4,  '2024-01-01', NULL,         220.00),
(22, 8,  3, 5,  '2024-01-01', NULL,         220.00),
(23, 9,  3, 6,  '2024-01-01', NULL,         220.00),
(24, 10, 3, 4,  '2024-01-01', NULL,         220.00),
(25, 11, 3, 5,  '2024-01-01', NULL,         220.00),
(26, 12, 3, 6,  '2024-01-01', NULL,         220.00),
(27, 13, 3, 4,  '2024-01-01', NULL,         220.00),
(28, 14, 3, 5,  '2024-01-01', NULL,         220.00),
(29, 1,  5, 7,  '2024-01-01', NULL,         150.00),
(30, 2,  5, 8,  '2024-01-01', NULL,         150.00),
(31, 3,  5, 7,  '2024-01-01', NULL,         150.00),
(32, 4,  5, 8,  '2024-01-01', NULL,         150.00),
(33, 5,  5, 7,  '2024-01-01', NULL,         150.00),
(34, 6,  5, 8,  '2024-01-01', NULL,         150.00),
(35, 7,  5, 7,  '2024-01-01', NULL,         150.00),
(36, 15, 6, 9,  '2024-01-01', NULL,          60.00),
(37, 16, 6, 10, '2024-01-01', NULL,          60.00),
(38, 17, 6, 11, '2024-01-01', NULL,          60.00),
(39, 18, 6, 9,  '2024-01-01', NULL,          60.00),
(40, 19, 6, 10, '2024-01-01', NULL,          60.00),
(41, 20, 6, 11, '2024-01-01', '2026-06-30',  60.00),
(42, 15, 3, 4,  '2024-06-01', NULL,          90.00),
(43, 16, 3, 5,  '2024-06-01', NULL,          90.00),
(44, 17, 3, 6,  '2024-06-01', NULL,          90.00),
(45, 18, 3, 4,  '2024-06-01', NULL,          90.00),
(46, 19, 3, 5,  '2024-06-01', NULL,          90.00),
(47, 20, 3, 6,  '2024-06-01', '2026-06-30',  90.00);

-- 5. Trabajadores de los clientes 1, 2 y 3 (cuatro cada uno) --------------
INSERT INTO trabajador (id_trabajador, id_cliente, documento_identidad, num_afiliacion, nombre, apellidos, puesto, tipo_contrato, fecha_alta, fecha_baja) VALUES
(1,  1, '11111111H', '281000000001', 'Miguel',   'Aznar Bolea',     'Administrativo', 'INDEFINIDO', '2019-02-01', NULL),
(2,  1, '11111112A', '281000000002', 'Cristina', 'Campo Duque',     'Operaria',       'INDEFINIDO', '2020-03-01', NULL),
(3,  1, '11111113B', '281000000003', 'Alberto',  'Franco Giménez', 'Técnico',        'TEMPORAL',   '2025-01-15', NULL),
(4,  1, '11111114C', '281000000004', 'Silvia',   'Herrero Lacasa', 'Comercial',      'FORMACION',  '2025-09-01', NULL),
(5,  2, '22222221D', '282000000005', 'Daniel',   'Royo Marco',     'Camarero',       'INDEFINIDO', '2018-06-01', NULL),
(6,  2, '22222222E', '282000000006', 'Eva',      'Tello Pardo',    'Dependiente',    'INDEFINIDO', '2021-04-01', NULL),
(7,  2, '22222223F', '282000000007', 'Fernando', 'Sarasa Latorre', 'Cocinero',       'TEMPORAL',   '2024-02-01', NULL),
(8,  2, '22222224G', '282000000008', 'Beatriz',  'Ibáñez Nasarre', 'Administrativa', 'INDEFINIDO', '2022-09-01', NULL),
(9,  3, '33333331H', '283000000009', 'Rafael',   'Bolea Campo',    'Conductor',      'INDEFINIDO', '2017-01-10', NULL),
(10, 3, '33333332J', '283000000010', 'Inés',     'Duque Español',  'Técnica',        'INDEFINIDO', '2019-07-01', NULL),
(11, 3, '33333333K', '283000000011', 'Miguel',   'Giménez Herrero','Peón',           'TEMPORAL',   '2025-03-01', NULL),
(12, 3, '33333334L', '283000000012', 'Silvia',   'Lacasa Royo',    'Administrativa', 'OTRO',       '2023-05-01', '2026-06-30');

-- 6. Cuentas bancarias: una vigente por cliente, una histórica y dos de trabajadores
INSERT INTO cuenta_bancaria (id_cuenta, id_cliente, id_trabajador, titular, iban, vigente, fecha_alta, fecha_baja) VALUES
(1,  1,  NULL, 'Talleres Ebro S.L.',           'ES7621000418450200000001', true,  '2024-01-01', NULL),
(2,  2,  NULL, 'Hostelería Pirineos S.L.',     'ES7621000418450200000002', true,  '2024-01-01', NULL),
(3,  3,  NULL, 'Construcciones Moncayo S.L.',  'ES7621000418450200000003', true,  '2024-01-01', NULL),
(4,  4,  NULL, 'Clínica San Jorge S.L.',       'ES7621000418450200000004', true,  '2024-01-01', NULL),
(5,  5,  NULL, 'Distribuciones Monegros S.L.', 'ES7621000418450200000005', true,  '2024-01-01', NULL),
(6,  6,  NULL, 'Transportes del Jalón S.L.',   'ES7621000418450200000006', true,  '2024-01-01', NULL),
(7,  7,  NULL, 'Agroalimentaria Somontano S.L.','ES7621000418450200000007', true,  '2024-01-01', NULL),
(8,  8,  NULL, 'Ferretería Maestrazgo S.L.',   'ES7621000418450200000008', true,  '2024-01-01', NULL),
(9,  9,  NULL, 'Comercial Cinco Villas S.L.',  'ES7621000418450200000009', true,  '2024-01-01', NULL),
(10, 10, NULL, 'Servicios Pueyo S.L.',         'ES7621000418450200000010', true,  '2024-01-01', NULL),
(11, 11, NULL, 'Panadería La Concepción S.L.', 'ES7621000418450200000011', true,  '2024-01-01', NULL),
(12, 12, NULL, 'Electricidad Bajo Aragón S.L.','ES7621000418450200000012', true,  '2024-01-01', NULL),
(13, 13, NULL, 'Gestorías Ribera S.L.',        'ES7621000418450200000013', true,  '2024-01-01', NULL),
(14, 14, NULL, 'Reformas Tarazona S.L.',       'ES7621000418450200000014', true,  '2024-01-01', NULL),
(15, 15, NULL, 'Ana Lasheras Gracia',          'ES7621000418450200000015', true,  '2024-01-01', NULL),
(16, 16, NULL, 'Luis Abadía Tena',             'ES7621000418450200000016', true,  '2024-01-01', NULL),
(17, 17, NULL, 'Pilar Bernad Allué',           'ES7621000418450200000017', true,  '2024-01-01', NULL),
(18, 18, NULL, 'Jorge Cativiela Betrán',       'ES7621000418450200000018', true,  '2024-01-01', NULL),
(19, 19, NULL, 'Carmen Escartín Lafuente',     'ES7621000418450200000019', true,  '2024-01-01', NULL),
(20, 20, NULL, 'Raúl Mairal Tena',             'ES7621000418450200000020', true,  '2024-01-01', '2026-06-30'),
(21, 1,  NULL, 'Talleres Ebro S.L.',           'ES7621000418450200000099', false, '2019-04-01', '2023-12-31'),
(22, NULL, 1,  'Miguel Aznar Bolea',           'ES7620950000000000000022', true,  '2019-02-01', NULL),
(23, NULL, 5,  'Daniel Royo Marco',            'ES7620950000000000000023', true,  '2018-06-01', NULL);

-- 7. Documentos: un contrato por trabajador (conservar_hasta lo calcula el trigger)
INSERT INTO documento (id_documento, id_cliente, id_trabajador, id_tipo_documento, fecha_documento, ruta_fichero, hash_sha256, id_empleado_alta) VALUES
(1, 1, 1, 1, '2019-02-01', '/ficheros/laboral/c1/contrato_t1.pdf', 'a065da6cf61526214bf4d01fa1772eb26131dcd9d204853410f76f50049ecc77', 1),
(2, 1, 2, 1, '2020-03-01', '/ficheros/laboral/c1/contrato_t2.pdf', 'bb931a959ec0fb15ec21655740a7c68e3cbc521a7937290978d40420453134f5', 1),
(3, 1, 3, 1, '2025-01-15', '/ficheros/laboral/c1/contrato_t3.pdf', 'fc480a1a58c9106f6c663246917b839263820d01099822b631294e2a7a21406e', 1),
(4, 1, 4, 1, '2025-09-01', '/ficheros/laboral/c1/contrato_t4.pdf', 'b9c2330e5295f8f4c4d4ca96e15446cfdea244ef3a2e28cfccc290e047d1d9c8', 1),
(5, 2, 5, 1, '2018-06-01', '/ficheros/laboral/c2/contrato_t5.pdf', '9a917a43151e69502868c6bf3fa5b220b7342662f9628da5b8db6cb6a2c1898e', 1),
(6, 2, 6, 1, '2021-04-01', '/ficheros/laboral/c2/contrato_t6.pdf', '4f71649a4529b61a6dadc5e0e29ef19ec177c3b20a3d6f0b07ae764bcc3c70f0', 1),
(7, 2, 7, 1, '2024-02-01', '/ficheros/laboral/c2/contrato_t7.pdf', '630ed950c41c5818a1594608083355aa89560ba8ad2ecaa0f28b2abf265e9c8d', 1),
(8, 2, 8, 1, '2022-09-01', '/ficheros/laboral/c2/contrato_t8.pdf', '52a249844f5e493c706f4a8213b68dd1de050a20b0f344e2c762d8ecc59c5675', 1),
(9, 3, 9, 1, '2017-01-10', '/ficheros/laboral/c3/contrato_t9.pdf', '204b287be315caa9393940316a1b2b0637e9ce9ae41ab7eab77d7b8bad7e1b64', 1),
(10, 3, 10, 1, '2019-07-01', '/ficheros/laboral/c3/contrato_t10.pdf', '8b0f3aade4f2ef38cafd52088b8c302fe6a39a00a42313b387ee3f94ceb6cc35', 1),
(11, 3, 11, 1, '2025-03-01', '/ficheros/laboral/c3/contrato_t11.pdf', '71e84e12ccfad44faad152aa2a7eaba3e417a7851d776951de4a01f1c840d2f8', 1),
(12, 3, 12, 1, '2023-05-01', '/ficheros/laboral/c3/contrato_t12.pdf', 'aae21eb54731e6c9ea4d6c8b50598d87dff47120fa94f06ff0b28132751fa45f', 1);

-- 8. Nóminas ordinarias de enero a marzo de 2026 para los 12 trabajadores
INSERT INTO nomina (id_trabajador, periodo, tipo_paga, bruto, deducciones) VALUES
(1, '2026-01-01', 'ORDINARIA', 1485.00, 282.15),
(1, '2026-02-01', 'ORDINARIA', 1485.00, 282.15),
(1, '2026-03-01', 'ORDINARIA', 1485.00, 282.15),
(2, '2026-01-01', 'ORDINARIA', 1570.00, 298.30),
(2, '2026-02-01', 'ORDINARIA', 1570.00, 298.30),
(2, '2026-03-01', 'ORDINARIA', 1570.00, 298.30),
(3, '2026-01-01', 'ORDINARIA', 1655.00, 314.45),
(3, '2026-02-01', 'ORDINARIA', 1655.00, 314.45),
(3, '2026-03-01', 'ORDINARIA', 1655.00, 314.45),
(4, '2026-01-01', 'ORDINARIA', 1740.00, 330.60),
(4, '2026-02-01', 'ORDINARIA', 1740.00, 330.60),
(4, '2026-03-01', 'ORDINARIA', 1740.00, 330.60),
(5, '2026-01-01', 'ORDINARIA', 1825.00, 346.75),
(5, '2026-02-01', 'ORDINARIA', 1825.00, 346.75),
(5, '2026-03-01', 'ORDINARIA', 1825.00, 346.75),
(6, '2026-01-01', 'ORDINARIA', 1910.00, 362.90),
(6, '2026-02-01', 'ORDINARIA', 1910.00, 362.90),
(6, '2026-03-01', 'ORDINARIA', 1910.00, 362.90),
(7, '2026-01-01', 'ORDINARIA', 1995.00, 379.05),
(7, '2026-02-01', 'ORDINARIA', 1995.00, 379.05),
(7, '2026-03-01', 'ORDINARIA', 1995.00, 379.05),
(8, '2026-01-01', 'ORDINARIA', 2080.00, 395.20),
(8, '2026-02-01', 'ORDINARIA', 2080.00, 395.20),
(8, '2026-03-01', 'ORDINARIA', 2080.00, 395.20),
(9, '2026-01-01', 'ORDINARIA', 2165.00, 411.35),
(9, '2026-02-01', 'ORDINARIA', 2165.00, 411.35),
(9, '2026-03-01', 'ORDINARIA', 2165.00, 411.35),
(10, '2026-01-01', 'ORDINARIA', 2250.00, 427.50),
(10, '2026-02-01', 'ORDINARIA', 2250.00, 427.50),
(10, '2026-03-01', 'ORDINARIA', 2250.00, 427.50),
(11, '2026-01-01', 'ORDINARIA', 2335.00, 443.65),
(11, '2026-02-01', 'ORDINARIA', 2335.00, 443.65),
(11, '2026-03-01', 'ORDINARIA', 2335.00, 443.65),
(12, '2026-01-01', 'ORDINARIA', 2420.00, 459.80),
(12, '2026-02-01', 'ORDINARIA', 2420.00, 459.80),
(12, '2026-03-01', 'ORDINARIA', 2420.00, 459.80);

-- 9. Obligaciones fiscales del 3T de 2026 ----------------------------------
INSERT INTO obligacion (id_obligacion, id_cliente, id_tipo_obligacion, ejercicio, periodo, fecha_limite, estado, fecha_presentacion, id_empleado_responsable) VALUES
(1,  1,  1, 2026, '3T', '2026-10-20', 'PRESENTADA', '2026-10-18', 4),
(2,  2,  1, 2026, '3T', '2026-10-20', 'PRESENTADA', '2026-10-18', 5),
(3,  3,  1, 2026, '3T', '2026-10-20', 'PRESENTADA', '2026-10-18', 6),
(4,  4,  1, 2026, '3T', '2026-10-20', 'PRESENTADA', '2026-10-18', 4),
(5,  5,  1, 2026, '3T', '2026-10-20', 'PRESENTADA', '2026-10-18', 5),
(6,  6,  1, 2026, '3T', '2026-10-20', 'PRESENTADA', '2026-10-18', 6),
(7,  7,  1, 2026, '3T', '2026-10-20', 'PRESENTADA', '2026-10-18', 4),
(8,  8,  1, 2026, '3T', '2026-10-20', 'PRESENTADA', '2026-10-18', 5),
(9,  9,  1, 2026, '3T', '2026-10-20', 'PRESENTADA', '2026-10-18', 6),
(10, 10, 1, 2026, '3T', '2026-10-20', 'PENDIENTE',  NULL,         4),
(11, 11, 1, 2026, '3T', '2026-10-20', 'PENDIENTE',  NULL,         5),
(12, 12, 1, 2026, '3T', '2026-10-20', 'PENDIENTE',  NULL,         6),
(13, 13, 1, 2026, '3T', '2026-10-20', 'PENDIENTE',  NULL,         4),
(14, 14, 1, 2026, '3T', '2026-10-20', 'PENDIENTE',  NULL,         5),
(15, 15, 3, 2026, '3T', '2026-10-20', 'PENDIENTE',  NULL,         4),
(16, 16, 3, 2026, '3T', '2026-10-20', 'PENDIENTE',  NULL,         5),
(17, 17, 3, 2026, '3T', '2026-10-20', 'PRESENTADA', '2026-10-19', 6),
(18, 18, 3, 2026, '3T', '2026-10-20', 'PRESENTADA', '2026-10-19', 4),
(19, 19, 3, 2026, '3T', '2026-10-20', 'PRESENTADA', '2026-10-19', 5);

-- 10. Facturas de septiembre de 2026 (una por cliente activo) y dos impagadas de agosto
INSERT INTO factura (id_factura, id_cliente, numero, fecha_emision, periodo_desde, periodo_hasta, estado_cobro, fecha_cobro) VALUES
(1,  1,  'F2026-000001', '2026-09-30', '2026-09-01', '2026-09-30', 'IMPAGADA',  NULL),
(2,  2,  'F2026-000002', '2026-09-30', '2026-09-01', '2026-09-30', 'IMPAGADA',  NULL),
(3,  3,  'F2026-000003', '2026-09-30', '2026-09-01', '2026-09-30', 'IMPAGADA',  NULL),
(4,  4,  'F2026-000004', '2026-09-30', '2026-09-01', '2026-09-30', 'PENDIENTE', NULL),
(5,  5,  'F2026-000005', '2026-09-30', '2026-09-01', '2026-09-30', 'PENDIENTE', NULL),
(6,  6,  'F2026-000006', '2026-09-30', '2026-09-01', '2026-09-30', 'PENDIENTE', NULL),
(7,  7,  'F2026-000007', '2026-09-30', '2026-09-01', '2026-09-30', 'COBRADA',   '2026-10-20'),
(8,  8,  'F2026-000008', '2026-09-30', '2026-09-01', '2026-09-30', 'COBRADA',   '2026-10-20'),
(9,  9,  'F2026-000009', '2026-09-30', '2026-09-01', '2026-09-30', 'COBRADA',   '2026-10-20'),
(10, 10, 'F2026-000010', '2026-09-30', '2026-09-01', '2026-09-30', 'COBRADA',   '2026-10-20'),
(11, 11, 'F2026-000011', '2026-09-30', '2026-09-01', '2026-09-30', 'COBRADA',   '2026-10-20'),
(12, 12, 'F2026-000012', '2026-09-30', '2026-09-01', '2026-09-30', 'COBRADA',   '2026-10-20'),
(13, 13, 'F2026-000013', '2026-09-30', '2026-09-01', '2026-09-30', 'COBRADA',   '2026-10-20'),
(14, 14, 'F2026-000014', '2026-09-30', '2026-09-01', '2026-09-30', 'COBRADA',   '2026-10-20'),
(15, 15, 'F2026-000015', '2026-09-30', '2026-09-01', '2026-09-30', 'COBRADA',   '2026-10-20'),
(16, 16, 'F2026-000016', '2026-09-30', '2026-09-01', '2026-09-30', 'PENDIENTE', NULL),
(17, 17, 'F2026-000017', '2026-09-30', '2026-09-01', '2026-09-30', 'COBRADA',   '2026-10-20'),
(18, 18, 'F2026-000018', '2026-09-30', '2026-09-01', '2026-09-30', 'COBRADA',   '2026-10-20'),
(19, 19, 'F2026-000019', '2026-09-30', '2026-09-01', '2026-09-30', 'COBRADA',   '2026-10-20'),
(20, 1,  'F2026-000020', '2026-08-31', '2026-08-01', '2026-08-31', 'IMPAGADA',  NULL),
(21, 2,  'F2026-000021', '2026-08-31', '2026-08-01', '2026-08-31', 'IMPAGADA',  NULL),
(22, 3,  'F2026-000022', '2026-08-31', '2026-08-01', '2026-08-31', 'IMPAGADA',  NULL);

-- Una línea por factura: honorarios mensuales (IVA 21 % por defecto)
INSERT INTO linea_factura (id_linea, id_factura, num_linea, id_servicio, concepto, cantidad, precio_unitario) VALUES
(1,  1,  1, 3, 'Honorarios mensuales de septiembre de 2026', 1, 250.00),
(2,  2,  1, 3, 'Honorarios mensuales de septiembre de 2026', 1, 250.00),
(3,  3,  1, 3, 'Honorarios mensuales de septiembre de 2026', 1, 250.00),
(4,  4,  1, 3, 'Honorarios mensuales de septiembre de 2026', 1, 250.00),
(5,  5,  1, 3, 'Honorarios mensuales de septiembre de 2026', 1, 250.00),
(6,  6,  1, 3, 'Honorarios mensuales de septiembre de 2026', 1, 250.00),
(7,  7,  1, 3, 'Honorarios mensuales de septiembre de 2026', 1, 250.00),
(8,  8,  1, 3, 'Honorarios mensuales de septiembre de 2026', 1, 250.00),
(9,  9,  1, 3, 'Honorarios mensuales de septiembre de 2026', 1, 250.00),
(10, 10, 1, 3, 'Honorarios mensuales de septiembre de 2026', 1, 250.00),
(11, 11, 1, 3, 'Honorarios mensuales de septiembre de 2026', 1, 250.00),
(12, 12, 1, 3, 'Honorarios mensuales de septiembre de 2026', 1, 250.00),
(13, 13, 1, 3, 'Honorarios mensuales de septiembre de 2026', 1, 250.00),
(14, 14, 1, 3, 'Honorarios mensuales de septiembre de 2026', 1, 250.00),
(15, 15, 1, 6, 'Honorarios mensuales de septiembre de 2026', 1, 120.00),
(16, 16, 1, 6, 'Honorarios mensuales de septiembre de 2026', 1, 120.00),
(17, 17, 1, 6, 'Honorarios mensuales de septiembre de 2026', 1, 120.00),
(18, 18, 1, 6, 'Honorarios mensuales de septiembre de 2026', 1, 120.00),
(19, 19, 1, 6, 'Honorarios mensuales de septiembre de 2026', 1, 120.00),
(20, 20, 1, 3, 'Honorarios mensuales de agosto de 2026', 1, 250.00),
(21, 21, 1, 3, 'Honorarios mensuales de agosto de 2026', 1, 250.00),
(22, 22, 1, 3, 'Honorarios mensuales de agosto de 2026', 1, 250.00);

-- 11. Consultas de atención al cliente (empleados 9, 10 y 11)
INSERT INTO consulta (id_consulta, id_cliente, id_contacto, id_empleado, fecha_hora, canal, motivo, estado, resolucion, fecha_cierre) VALUES
(1,  1,  1,  9,  '2026-08-03 10:15+02', 'TELEFONO',   'Duda sobre una nómina',          'CERRADA', 'Explicado el cálculo de la nómina',  '2026-08-03 11:00+02'),
(2,  1,  1,  10, '2026-08-05 09:30+02', 'CORREO',     'Plazo de presentación del IVA',  'CERRADA', 'Enviado calendario fiscal',         '2026-08-06 09:00+02'),
(3,  2,  2,  9,  '2026-08-07 12:00+02', 'PRESENCIAL', 'Solicitud de certificado',        'ABIERTA', NULL,                                NULL),
(4,  2,  2,  11, '2026-08-10 16:20+02', 'PORTAL',     'Cambio de domicilio fiscal',     'EN_CURSO', NULL,                               NULL),
(5,  3,  3,  9,  '2026-08-12 11:00+02', 'TELEFONO',   'Alta de un trabajador',          'CERRADA', 'Alta tramitada',                    '2026-08-12 12:00+02'),
(6,  3,  3,  10, '2026-08-14 17:45+02', 'CORREO',     'Revisión de una factura',        'ABIERTA', NULL,                                NULL),
(7,  4,  4,  11, '2026-08-18 10:00+02', 'PORTAL',     'Estado de un trámite',           'CERRADA', 'Trámite completado',                '2026-08-19 10:00+02'),
(8,  5,  5,  9,  '2026-08-20 09:00+02', 'TELEFONO',   'Baja de un trabajador',          'EN_CURSO', NULL,                               NULL),
(9,  6,  6,  10, '2026-08-25 13:10+02', 'CORREO',     'Duda sobre una nómina',          'ABIERTA', NULL,                                NULL),
(10, 7,  7,  11, '2026-09-01 10:30+02', 'PRESENCIAL', 'Solicitud de certificado',        'CERRADA', 'Certificado entregado',             '2026-09-01 11:00+02'),
(11, 8,  8,  9,  '2026-09-03 15:00+02', 'TELEFONO',   'Plazo de presentación del IVA',  'CERRADA', 'Recordatorio enviado',              '2026-09-03 15:20+02'),
(12, 9,  9,  10, '2026-09-05 09:45+02', 'CORREO',     'Revisión de una factura',        'CERRADA', 'Factura corregida',                 '2026-09-07 10:00+02'),
(13, 10, 10, 11, '2026-09-08 11:30+02', 'PORTAL',     'Cambio de domicilio fiscal',     'ABIERTA', NULL,                                NULL),
(14, 11, 11, 9,  '2026-09-10 12:15+02', 'TELEFONO',   'Alta de un trabajador',          'EN_CURSO', NULL,                               NULL),
(15, 12, 12, 10, '2026-09-14 16:00+02', 'CORREO',     'Duda sobre una nómina',          'CERRADA', 'Nómina aclarada',                   '2026-09-15 09:00+02'),
(16, 13, 13, 9,  '2026-09-16 10:20+02', 'PRESENCIAL', 'Estado de un trámite',           'CERRADA', 'Trámite completado',                '2026-09-16 10:50+02'),
(17, 14, 14, 11, '2026-09-22 09:00+02', 'TELEFONO',   'Solicitud de certificado',       'ABIERTA', NULL,                                NULL),
(18, 15, 15, 10, '2026-09-24 11:40+02', 'PORTAL',     'Alta de un trabajador',          'CERRADA', 'Alta tramitada',                    '2026-09-25 12:00+02'),
(19, 16, 16, 9,  '2026-09-28 08:50+02', 'CORREO',     'Baja de un trabajador',          'EN_CURSO', NULL,                               NULL),
(20, 17, 17, 11, '2026-10-01 10:00+02', 'TELEFONO',   'Revisión de una factura',        'ABIERTA', NULL,                                NULL),
(21, 18, 18, 10, '2026-10-05 13:00+02', 'PORTAL',     'Duda sobre una nómina',          'CERRADA', 'Explicado',                         '2026-10-05 13:30+02'),
(22, 1,  1,  9,  '2026-10-12 09:15+02', 'TELEFONO',   'Plazo de presentación del IVA',  'CERRADA', 'Confirmado el plazo',               '2026-10-12 09:30+02'),
(23, 2,  2,  11, '2026-10-20 16:00+02', 'CORREO',     'Estado de un trámite',           'EN_CURSO', NULL,                               NULL),
(24, 3,  3,  10, '2026-10-27 10:40+02', 'PRESENCIAL', 'Revisión de una factura',        'ABIERTA', NULL,                                NULL);

COMMIT;
ANALYZE;
