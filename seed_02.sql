-- ===========================================
-- seed_02.sql  |  Datos demo masivos (MySQL 8)
-- Esquema: gestion_creditos  (con tablas de dominio)
-- Genera >= 60 filas por tabla (muchas >> 60)
-- Listas de dominio: <60 por diseño (justificado)
-- Compatible con esquema_01.sql provisto
-- ===========================================

USE gestion_creditos;
SET sql_safe_updates = 0;

-- -------------------------------------------------
-- Limpieza controlada (solo datos; mantiene objetos)
-- -------------------------------------------------
SET FOREIGN_KEY_CHECKS = 0;

-- tablas dependientes (orden FK)
DELETE FROM campanias_clientes;
DELETE FROM campanias_productos;
DELETE FROM evaluaciones_seguimiento;
DELETE FROM penalizaciones;
DELETE FROM pagos;
DELETE FROM cuotas;
DELETE FROM creditos;
DELETE FROM solicitudes_garantes;
DELETE FROM solicitudes_credito;
DELETE FROM garantes;
DELETE FROM historico_tasas;
DELETE FROM productos_financieros;
DELETE FROM clientes;
DELETE FROM campanias_promocionales;
DELETE FROM empleados;
DELETE FROM sucursales;

-- geo maestro
DELETE FROM ciudades;
DELETE FROM provincias;

-- dominios (catálogos finitos)
DELETE FROM estado_sucursal;
DELETE FROM cargo_empleado;
DELETE FROM estado_empleado;
DELETE FROM estado_cliente;
DELETE FROM situacion_laboral;
DELETE FROM tipo_producto;
DELETE FROM estado_producto;
DELETE FROM estado_campania;
DELETE FROM estado_solicitud;
DELETE FROM estado_credito;
DELETE FROM estado_cuota;
DELETE FROM metodo_pago;
DELETE FROM estado_penalizacion;
DELETE FROM comp_pago;

SET FOREIGN_KEY_CHECKS = 1;

-- ------------------------------------------------------------------
-- 0) Helper: Secuencia 1..5000 SIN recursividad
-- ------------------------------------------------------------------
DROP TABLE IF EXISTS helper_seq;
CREATE TABLE helper_seq (n INT PRIMARY KEY);
INSERT INTO helper_seq (n)
SELECT num
FROM (
  SELECT (a.N + b.N*10 + c.N*100 + d.N*1000) + 1 AS num
  FROM (SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
  CROSS JOIN (SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
              UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
  CROSS JOIN (SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
              UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) c
  CROSS JOIN (SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
              UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d
) t
WHERE t.num <= 5000;

-- ------------------------------------------------------------------
-- A) DOMINIOS (listas finitas; <60 por diseño)  [Justificado]
-- ------------------------------------------------------------------
INSERT INTO estado_sucursal (codigo,nombre) VALUES
 ('Activa','Activa'),('Inactiva','Inactiva');

INSERT INTO cargo_empleado (codigo,nombre) VALUES
 ('Atencion_Cliente','Atención al Cliente'),
 ('Analista_Credito','Analista de Crédito'),
 ('Gerente','Gerente'),
 ('Cobranza','Gestor de Cobranza'),
 ('Administrador','Administrador');

INSERT INTO estado_empleado (codigo,nombre) VALUES
 ('Activo','Activo'),('Inactivo','Inactivo');

INSERT INTO estado_cliente (codigo,nombre) VALUES
 ('Activo','Activo'),('Inactivo','Inactivo'),('Moroso','Moroso'),('Bloqueado','Bloqueado');

INSERT INTO situacion_laboral (codigo,nombre) VALUES
 ('Empleado','Empleado'),('Autonomo','Autónomo'),('Empresario','Empresario'),('Jubilado','Jubilado'),('Desempleado','Desempleado');

INSERT INTO tipo_producto (codigo,nombre) VALUES
 ('Personal','Crédito Personal'),('Hipotecario','Hipotecario'),
 ('Empresarial','Empresarial'),('Leasing','Leasing'),
 ('Tarjeta_Corporativa','Tarjeta Corporativa');

INSERT INTO estado_producto (codigo,nombre) VALUES
 ('Activo','Activo'),('Inactivo','Inactivo');

INSERT INTO estado_campania (codigo,nombre) VALUES
 ('Activa','Activa'),('Finalizada','Finalizada'),('Cancelada','Cancelada');

INSERT INTO estado_solicitud (codigo,nombre) VALUES
 ('Pendiente','Pendiente'),('En_Revision','En Revisión'),
 ('Aprobada','Aprobada'),('Rechazada','Rechazada');

INSERT INTO estado_credito (codigo,nombre) VALUES
 ('Activo','Activo'),('Pagado','Pagado'),('Refinanciado','Refinanciado'),
 ('En_Mora','En Mora'),('Cancelado','Cancelado');

INSERT INTO estado_cuota (codigo,nombre) VALUES
 ('Pendiente','Pendiente'),('Pagada','Pagada'),
 ('Vencida','Vencida'),('Pagada_Con_Mora','Pagada con Mora');

INSERT INTO metodo_pago (codigo,nombre) VALUES
 ('Efectivo','Efectivo'),('Transferencia','Transferencia'),
 ('Debito_Automatico','Débito Automático'),('Tarjeta','Tarjeta'),
 ('Cheque','Cheque');

INSERT INTO estado_penalizacion (codigo,nombre) VALUES
 ('Pendiente','Pendiente'),('Pagada','Pagada');

INSERT INTO comp_pago (codigo,nombre) VALUES
 ('Excelente','Excelente'),('Bueno','Bueno'),('Regular','Regular'),
 ('Malo','Malo'),('Muy_Malo','Muy Malo');

-- IDs de dominio (para referencias)
SET @id_suc_act  = (SELECT id FROM estado_sucursal  WHERE codigo='Activa');
SET @id_suc_inact= (SELECT id FROM estado_sucursal  WHERE codigo='Inactiva');

SET @id_emp_act  = (SELECT id FROM estado_empleado  WHERE codigo='Activo');
SET @id_emp_inact= (SELECT id FROM estado_empleado  WHERE codigo='Inactivo');

SET @id_cli_act  = (SELECT id FROM estado_cliente   WHERE codigo='Activo');
SET @id_cli_mor  = (SELECT id FROM estado_cliente   WHERE codigo='Moroso');
SET @id_cli_bloq = (SELECT id FROM estado_cliente   WHERE codigo='Bloqueado');

SET @id_sol_pend = (SELECT id FROM estado_solicitud WHERE codigo='Pendiente');
SET @id_sol_enrev= (SELECT id FROM estado_solicitud WHERE codigo='En_Revision');
SET @id_sol_aprb = (SELECT id FROM estado_solicitud WHERE codigo='Aprobada');
SET @id_sol_rech = (SELECT id FROM estado_solicitud WHERE codigo='Rechazada');

SET @id_cre_act  = (SELECT id FROM estado_credito   WHERE codigo='Activo');
SET @id_cre_pag  = (SELECT id FROM estado_credito   WHERE codigo='Pagado');
SET @id_cre_mor  = (SELECT id FROM estado_credito   WHERE codigo='En_Mora');

SET @id_cuo_pend = (SELECT id FROM estado_cuota     WHERE codigo='Pendiente');
SET @id_cuo_pag  = (SELECT id FROM estado_cuota     WHERE codigo='Pagada');
SET @id_cuo_venc = (SELECT id FROM estado_cuota     WHERE codigo='Vencida');
SET @id_cuo_pagmor = (SELECT id FROM estado_cuota   WHERE codigo='Pagada_Con_Mora');

SET @id_met_trf  = (SELECT id FROM metodo_pago      WHERE codigo='Transferencia');
SET @id_met_efv  = (SELECT id FROM metodo_pago      WHERE codigo='Efectivo');
SET @id_met_deb  = (SELECT id FROM metodo_pago      WHERE codigo='Debito_Automatico');

SET @id_pen_pend = (SELECT id FROM estado_penalizacion WHERE codigo='Pendiente');

SET @id_cargo_ac = (SELECT id FROM cargo_empleado WHERE codigo='Atencion_Cliente');
SET @id_cargo_an = (SELECT id FROM cargo_empleado WHERE codigo='Analista_Credito');
SET @id_cargo_ge = (SELECT id FROM cargo_empleado WHERE codigo='Gerente');
SET @id_cargo_cb = (SELECT id FROM cargo_empleado WHERE codigo='Cobranza');
SET @id_cargo_ad = (SELECT id FROM cargo_empleado WHERE codigo='Administrador');

SET @id_tipo_per = (SELECT id FROM tipo_producto WHERE codigo='Personal');
SET @id_tipo_hip = (SELECT id FROM tipo_producto WHERE codigo='Hipotecario');
SET @id_tipo_emp = (SELECT id FROM tipo_producto WHERE codigo='Empresarial');
SET @id_tipo_lea = (SELECT id FROM tipo_producto WHERE codigo='Leasing');
SET @id_tipo_tar = (SELECT id FROM tipo_producto WHERE codigo='Tarjeta_Corporativa');

-- ------------------------------------------------------------------
-- 1) Provincias (60)  ✔
-- ------------------------------------------------------------------
INSERT INTO provincias(nombre)
SELECT CONCAT('Provincia ', n)
FROM helper_seq WHERE n <= 60;

-- ------------------------------------------------------------------
-- 1.b) Ciudades (5 por provincia = 300)  ✔
-- ------------------------------------------------------------------
INSERT INTO ciudades(id_provincia, nombre)
SELECT p.id_provincia,
       CONCAT('Ciudad P', p.id_provincia, ' - ', k.k)
FROM provincias p
JOIN (SELECT 1 AS k UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) k;

DROP TEMPORARY TABLE IF EXISTS map_ciudades;
CREATE TEMPORARY TABLE map_ciudades AS
SELECT
  id_provincia,
  id_ciudad,
  ROW_NUMBER() OVER (PARTITION BY id_provincia ORDER BY id_ciudad) AS rn,
  nombre AS nombre_ciudad
FROM ciudades;

-- ------------------------------------------------------------------
-- 2) Sucursales (80)  ✔
-- ------------------------------------------------------------------
INSERT INTO sucursales(nombre, id_provincia, id_ciudad, ciudad, direccion, telefono, email, fecha_apertura, id_estado)
SELECT
  CONCAT('Sucursal ', n)                                AS nombre,
  ((n - 1) % 60) + 1                                   AS id_provincia,
  mc.id_ciudad                                          AS id_ciudad,
  mc.nombre_ciudad                                      AS ciudad_txt,
  CONCAT('Calle ', n, ' #', 100 + n)                    AS direccion,
  CONCAT('0376-', LPAD(n, 4, '0'))                      AS telefono,
  CONCAT('suc', n, '@empresa.com')                      AS email,
  DATE_ADD('2018-01-01', INTERVAL n DAY)                AS fecha_apertura,
  IF(n % 20 = 0, @id_suc_inact, @id_suc_act)           AS id_estado
FROM helper_seq s
JOIN map_ciudades mc
  ON mc.id_provincia = (((s.n - 1) % 60) + 1)
 AND mc.rn = (((s.n - 1) % 5) + 1)
WHERE s.n <= 80;

-- ------------------------------------------------------------------
-- 3) Empleados (300)  ✔
-- ------------------------------------------------------------------
INSERT INTO empleados(id_sucursal,nombre,apellido,dni,id_cargo,email,telefono,fecha_ingreso,salario,id_estado)
SELECT
  ((n - 1) % 80) + 1,
  CONCAT('EmpNombre', n),
  CONCAT('EmpApellido', n),
  CONCAT('40', LPAD(n, 8, '0')),
  ELT( (n % 5)+1, @id_cargo_ac, @id_cargo_an, @id_cargo_ge, @id_cargo_cb, @id_cargo_ad ),
  CONCAT('emp', n, '@empresa.com'),
  CONCAT('0376-', LPAD(5000 + n, 4, '0')),
  DATE_ADD('2020-01-01', INTERVAL (n % 1500) DAY),
  250000 + (n * 100),
  IF(n % 50 = 0, @id_emp_inact, @id_emp_act)
FROM helper_seq WHERE n <= 300;

-- ------------------------------------------------------------------
-- 4) Campañas (60)  ✔
-- ------------------------------------------------------------------
INSERT INTO campanias_promocionales(nombre, descripcion, tasa_promocional, fecha_inicio, fecha_fin, descuento_porcentaje, id_estado, presupuesto, inversion_realizada, clientes_captados)
SELECT
  CONCAT('Campaña ', n),
  CONCAT('Campaña de captación #', n),
  10 + (n % 30),
  DATE_ADD('2023-01-01', INTERVAL n MONTH),
  DATE_ADD('2023-01-01', INTERVAL n+3 MONTH),
  (n % 20),
  CASE WHEN n % 17 = 0 THEN (SELECT id FROM estado_campania WHERE codigo='Cancelada')
       WHEN n % 7  = 0 THEN (SELECT id FROM estado_campania WHERE codigo='Finalizada')
       ELSE (SELECT id FROM estado_campania WHERE codigo='Activa')
  END,
  1000000 + n*5000,
  100000 + n*1200,
  0
FROM helper_seq WHERE n <= 60;

-- ------------------------------------------------------------------
-- 5) Clientes (500)  ✔
-- ------------------------------------------------------------------
INSERT INTO clientes(
  nombre, apellido, dni, fecha_nacimiento, email, telefono, direccion,
  ciudad, provincia, id_provincia, id_ciudad,
  ingresos_declarados, id_situacion_laboral, id_campania_ingreso, id_estado
)
SELECT
  CONCAT('CliNombre', n),
  CONCAT('CliApellido', n),
  CONCAT('30', LPAD(n, 8, '0')),
  DATE_ADD('1985-01-01', INTERVAL (n % 15000) DAY),
  CONCAT('cli', n, '@mail.com'),
  CONCAT('+54-9-376-', LPAD(n, 4, '0')),
  CONCAT('Av. Siempre Viva ', n),
  mc.nombre_ciudad,
  CONCAT('Provincia ', (((n-1)%60)+1)),
  (((n-1)%60)+1) AS id_provincia,
  mc.id_ciudad   AS id_ciudad,
  300000 + (n * 200),
  ELT((n % 5)+1,
      (SELECT id FROM situacion_laboral WHERE codigo='Empleado'),
      (SELECT id FROM situacion_laboral WHERE codigo='Autonomo'),
      (SELECT id FROM situacion_laboral WHERE codigo='Empresario'),
      (SELECT id FROM situacion_laboral WHERE codigo='Jubilado'),
      (SELECT id FROM situacion_laboral WHERE codigo='Desempleado')),
  IF(n % 4 = 0, ((n-1) % 60) + 1, NULL),
  IF(n % 97 = 0, @id_cli_bloq, IF(n % 53 = 0, @id_cli_mor, @id_cli_act))
FROM helper_seq s
JOIN map_ciudades mc
  ON mc.id_provincia = (((s.n - 1) % 60) + 1)
 AND mc.rn = (((s.n - 1) % 5) + 1)
WHERE s.n <= 500;

-- ------------------------------------------------------------------
-- 6) Productos (60) + Histórico (≥3 por producto)  ✔
-- ------------------------------------------------------------------
INSERT INTO productos_financieros(nombre, id_tipo, descripcion, tasa_base, monto_minimo, monto_maximo, plazo_minimo_meses, plazo_maximo_meses, requisitos, id_estado)
SELECT
  CONCAT('Producto ', n),
  ELT((n % 5)+1, @id_tipo_per, @id_tipo_hip, @id_tipo_emp, @id_tipo_lea, @id_tipo_tar),
  CONCAT('Descripción del producto ', n),
  40 + (n % 40),
  50000 + (n * 1000),
  1000000 + (n * 50000),
  6,
  60,
  'DNI, comprobantes, scoring',
  IF(n % 13 = 0, (SELECT id FROM estado_producto WHERE codigo='Inactivo'),
                 (SELECT id FROM estado_producto WHERE codigo='Activo'))
FROM helper_seq WHERE n <= 60;

-- Histórico base (3 por producto) con anti-clamp Y2038
INSERT INTO historico_tasas(
  id_producto, tasa_anterior, tasa_nueva, fecha_cambio,
  motivo, usuario_responsable, vigente_desde, vigente_hasta
)
SELECT
  p.id_producto,
  (p.tasa_base - 2) + (k - 1),
  (p.tasa_base - 1) + (k - 1),
  CASE
    WHEN DATE_ADD('2022-01-01', INTERVAL (p.id_producto*5 + k) MONTH) > '2038-01-18 23:59:50'
      THEN TIMESTAMP(DATE('2038-01-18'), SEC_TO_TIME(86390 - (3 - k)))
    ELSE DATE_ADD('2022-01-01', INTERVAL (p.id_producto*5 + k) MONTH)
  END,
  CONCAT('Ajuste histórico #', k),
  'seed@loader',
  DATE_ADD('2022-01-01', INTERVAL (k - 1) * 8 MONTH),
  CASE WHEN k = 3 THEN NULL
       ELSE DATE_SUB(DATE_ADD('2022-01-01', INTERVAL k * 8 MONTH), INTERVAL 1 DAY)
  END
FROM productos_financieros p
JOIN (SELECT 1 AS k UNION ALL SELECT 2 UNION ALL SELECT 3) ks;

-- ===== Parche anti-solapamiento de vigencias (2 tramos por producto) =====
START TRANSACTION;
SET @corte_300 := DATE_SUB(CURDATE(), INTERVAL 300 DAY);
SET @corte_150 := DATE_SUB(CURDATE(), INTERVAL 150 DAY);

UPDATE historico_tasas h
SET h.vigente_hasta = DATE_SUB(@corte_300, INTERVAL 1 DAY)
WHERE h.borrado_logico = 0
  AND h.vigente_hasta IS NULL
  AND h.vigente_desde IS NOT NULL
  AND h.vigente_desde <= @corte_300;

UPDATE historico_tasas h
SET h.vigente_hasta = DATE_SUB(@corte_150, INTERVAL 1 DAY)
WHERE h.borrado_logico = 0
  AND h.vigente_hasta IS NULL
  AND h.vigente_desde IS NOT NULL
  AND h.vigente_desde > @corte_300
  AND h.vigente_desde <= @corte_150;

INSERT INTO historico_tasas
(id_producto, tasa_anterior, tasa_nueva, fecha_cambio, motivo, usuario_responsable, vigente_desde, vigente_hasta)
SELECT 
  p.id_producto,
  p.tasa_base - 0.40,
  p.tasa_base - 0.20,
  @corte_300,
  'Ajuste por política',
  'seed@loader',
  @corte_300,
  DATE_SUB(@corte_150, INTERVAL 1 DAY)
FROM productos_financieros p
WHERE NOT EXISTS (
  SELECT 1 FROM historico_tasas h
  WHERE h.id_producto = p.id_producto
    AND h.borrado_logico = 0
    AND COALESCE(h.vigente_hasta, '9999-12-31') >= @corte_300
    AND COALESCE(h.vigente_desde, '0001-01-01') <= DATE_SUB(@corte_150, INTERVAL 1 DAY)
);

INSERT INTO historico_tasas
(id_producto, tasa_anterior, tasa_nueva, fecha_cambio, motivo, usuario_responsable, vigente_desde, vigente_hasta)
SELECT 
  p.id_producto,
  p.tasa_base - 0.20,
  p.tasa_base + 0.10,
  @corte_150,
  'Revisión trimestral',
  'seed@loader',
  @corte_150,
  NULL
FROM productos_financieros p
WHERE NOT EXISTS (
  SELECT 1 FROM historico_tasas h
  WHERE h.id_producto = p.id_producto
    AND h.borrado_logico = 0
    AND COALESCE(h.vigente_hasta, '9999-12-31') >= @corte_150
    AND COALESCE(h.vigente_desde, '0001-01-01') <= '9999-12-31'
);
COMMIT;
-- ===== Fin parche =====

-- ------------------------------------------------------------------
-- 7) Garantes (300)  ✔
-- ------------------------------------------------------------------
INSERT INTO garantes(nombre, apellido, dni, email, telefono, direccion, ingresos_declarados, relacion_cliente)
SELECT
  CONCAT('GarNombre', n),
  CONCAT('GarApellido', n),
  CONCAT('20', LPAD(n, 8, '0')),
  CONCAT('gar', n, '@mail.com'),
  CONCAT('+54-9-11-', LPAD(n, 4, '0')),
  CONCAT('Calle Garante ', n),
  400000 + (n * 300),
  ELT((n % 4)+1, 'Familiar','Amigo','Socio','Cónyuge')
FROM helper_seq WHERE n <= 300;

-- ------------------------------------------------------------------
-- 8) Solicitudes (600)  ✔
-- ------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS tmp_gestores;
CREATE TEMPORARY TABLE tmp_gestores AS
SELECT e.id_empleado,
       ROW_NUMBER() OVER (ORDER BY e.id_empleado) AS rn
FROM empleados e
WHERE e.id_cargo=@id_cargo_ac AND e.id_estado=@id_emp_act;

DROP TEMPORARY TABLE IF EXISTS tmp_analistas;
CREATE TEMPORARY TABLE tmp_analistas AS
SELECT e.id_empleado,
       ROW_NUMBER() OVER (ORDER BY e.id_empleado) AS rn
FROM empleados e
WHERE e.id_cargo=@id_cargo_an AND e.id_estado=@id_emp_act;

SET @cnt_gest = (SELECT COUNT(*) FROM tmp_gestores);
SET @cnt_an   = (SELECT COUNT(*) FROM tmp_analistas);

INSERT INTO solicitudes_credito(
  id_cliente, id_sucursal, id_empleado_gestor, id_producto,
  monto_solicitado, plazo_meses, destino_credito, fecha_solicitud,
  id_estado, puntaje_riesgo, id_analista, observaciones, fecha_evaluacion
)
SELECT
  ((s.n - 1) % 500) + 1,
  ((s.n - 1) % 80) + 1,
  (SELECT g.id_empleado FROM tmp_gestores g WHERE g.rn = ((s.n - 1) % @cnt_gest) + 1),
  ((s.n - 1) % 60) + 1,
  150000 + (s.n * 1000),
  6 + (s.n % 36),
  ELT((s.n % 5)+1,'Consumo','Capital de trabajo','Refacción','Vehículo','Varios'),
  DATE_ADD('2024-01-01', INTERVAL s.n DAY),
  ELT((s.n % 4)+1, @id_sol_pend, @id_sol_enrev, @id_sol_aprb, @id_sol_rech),
  600 + (s.n % 300),
  (SELECT a.id_empleado FROM tmp_analistas a WHERE a.rn = ((s.n - 1) % @cnt_an) + 1),
  IF(s.n % 9 = 0, 'Observación de riesgo', NULL),
  IF(s.n % 4 IN (2,3), DATE_ADD('2024-01-01', INTERVAL s.n+5 DAY), NULL)
FROM helper_seq s
WHERE s.n <= 600;

-- ------------------------------------------------------------------
-- 9) Solicitudes-Garantes (≥600)  ✔
-- ------------------------------------------------------------------
INSERT INTO solicitudes_garantes(id_solicitud, id_garante)
SELECT s.id_solicitud, ((s.id_solicitud - 1) % 300) + 1
FROM solicitudes_credito s;

INSERT INTO solicitudes_garantes(id_solicitud, id_garante)
SELECT s.id_solicitud, ((s.id_solicitud + 77) % 300) + 1
FROM solicitudes_credito s
WHERE s.id_solicitud % 3 = 0;

-- ------------------------------------------------------------------
-- 10) Créditos (todas las Aprobadas)  ✔
-- ------------------------------------------------------------------
INSERT INTO creditos(
  id_solicitud, id_cliente, id_producto, monto_otorgado, tasa_interes,
  plazo_meses, fecha_inicio, fecha_finalizacion, id_estado, id_credito_refinanciado
)
SELECT
  sc.id_solicitud,
  sc.id_cliente,
  sc.id_producto,
  ROUND(sc.monto_solicitado * (0.9 + ((sc.id_solicitud % 21)/100.0)), 2),
  (SELECT fn_tasa_vigente(sc.id_producto, CURDATE())),
  sc.plazo_meses,
  DATE_ADD('2024-02-01', INTERVAL sc.id_solicitud DAY),
  DATE_ADD(DATE_ADD('2024-02-01', INTERVAL sc.id_solicitud DAY), INTERVAL sc.plazo_meses MONTH),
  @id_cre_act,
  NULL
FROM solicitudes_credito sc
WHERE sc.id_estado = @id_sol_aprb;

-- ------------------------------------------------------------------
-- 11) Generar CUOTAS para todos los créditos  ✔
-- ------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_seed_generar_cuotas_all;
DELIMITER $$
CREATE PROCEDURE sp_seed_generar_cuotas_all()
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE vid INT;
  DECLARE cur CURSOR FOR SELECT id_credito FROM creditos;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO vid;
    IF done = 1 THEN LEAVE read_loop; END IF;
    CALL sp_generar_cuotas(vid);
  END LOOP;
  CLOSE cur;
END$$
DELIMITER ;
CALL sp_seed_generar_cuotas_all();
DROP PROCEDURE IF EXISTS sp_seed_generar_cuotas_all;

-- ==========================================================
-- 11.bis) Wrapper compatibilidad para sp_registrar_pago  ✔
-- ==========================================================
DROP PROCEDURE IF EXISTS sp_seed_registrar_pago;
DELIMITER $$
CREATE PROCEDURE sp_seed_registrar_pago(
  IN p_id_cuota BIGINT,
  IN p_monto DECIMAL(14,2),
  IN p_id_metodo INT,
  IN p_nro_comp VARCHAR(50),
  IN p_tasa_mora_diaria DECIMAL(7,5)
)
BEGIN
  DECLARE v_argc INT;
  SELECT COUNT(*) INTO v_argc
  FROM INFORMATION_SCHEMA.PARAMETERS
  WHERE SPECIFIC_SCHEMA = DATABASE()
    AND SPECIFIC_NAME   = 'sp_registrar_pago';

  IF v_argc = 5 THEN
    CALL sp_registrar_pago(p_id_cuota, p_monto, p_id_metodo, p_nro_comp, p_tasa_mora_diaria);
  ELSEIF v_argc = 6 THEN
    CALL sp_registrar_pago(p_id_cuota, p_monto, p_id_metodo, p_nro_comp, NOW(), p_tasa_mora_diaria);
  ELSE
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sp_registrar_pago con aridad desconocida (esperado 5 o 6 args).';
  END IF;
END$$
DELIMITER ;

-- ------------------------------------------------------------------
-- 12) PAGOS (parciales/completos; con y sin mora)  ✔
-- ------------------------------------------------------------------
DELETE FROM pagos;
DELETE FROM penalizaciones;

-- a) 1ª cuota “al día” (parcial)
SET @__allow_pago_insert := 1;
DROP TEMPORARY TABLE IF EXISTS tmp_pagos_a;
CREATE TEMPORARY TABLE tmp_pagos_a AS
SELECT
  c1.id_cuota,
  DATE_SUB(c1.fecha_vencimiento, INTERVAL 1 DAY) AS fecha_pago,
  ROUND(c1.monto_cuota * 0.5, 2) AS monto_pagado,
  @id_met_trf AS id_metodo,
  CONCAT('CMP-ON-', c1.id_cuota) AS numero_comprobante
FROM cuotas c1
JOIN creditos cr ON cr.id_credito = c1.id_credito
WHERE c1.numero_cuota = 1 AND (cr.id_credito % 2 = 0);

INSERT INTO pagos(id_cuota, fecha_pago, monto_pagado, id_metodo, numero_comprobante)
SELECT id_cuota, fecha_pago, monto_pagado, id_metodo, numero_comprobante
FROM tmp_pagos_a;
SET @__allow_pago_insert := NULL;
DROP TEMPORARY TABLE IF EXISTS tmp_pagos_a;

-- b) 1ª cuota con mora (parcial)
DROP PROCEDURE IF EXISTS sp_seed_pagar_mora_primera;
DELIMITER $$
CREATE PROCEDURE sp_seed_pagar_mora_primera()
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE vcuota BIGINT;
  DECLARE cur CURSOR FOR
    SELECT c1.id_cuota
    FROM cuotas c1
    JOIN creditos cr ON cr.id_credito = c1.id_credito
    WHERE c1.numero_cuota = 1 AND (cr.id_credito % 2 = 1);
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO vcuota;
    IF done = 1 THEN LEAVE read_loop; END IF;
    CALL sp_seed_registrar_pago(
      vcuota,
      (SELECT ROUND(monto_cuota*0.6,2) FROM cuotas WHERE id_cuota=vcuota),
      @id_met_efv,
      CONCAT('CMP-LT-', vcuota),
      0.0005
    );
  END LOOP;
  CLOSE cur;
END$$
DELIMITER ;
CALL sp_seed_pagar_mora_primera();
DROP PROCEDURE IF EXISTS sp_seed_pagar_mora_primera;

-- c) 2ª cuota al día (completo) ~30%
SET @__allow_pago_insert := 1;
DROP TEMPORARY TABLE IF EXISTS tmp_pagos_c;
CREATE TEMPORARY TABLE tmp_pagos_c AS
SELECT
  c2.id_cuota,
  DATE_SUB(c2.fecha_vencimiento, INTERVAL 2 DAY) AS fecha_pago,
  c2.monto_cuota AS monto_pagado,
  @id_met_deb AS id_metodo,
  CONCAT('CMP-2-', c2.id_cuota) AS numero_comprobante
FROM cuotas c2
JOIN creditos cr ON cr.id_credito = c2.id_credito
WHERE c2.numero_cuota = 2 AND (cr.id_credito % 3 = 0);

INSERT INTO pagos(id_cuota, fecha_pago, monto_pagado, id_metodo, numero_comprobante)
SELECT id_cuota, fecha_pago, monto_pagado, id_metodo, numero_comprobante
FROM tmp_pagos_c;
SET @__allow_pago_insert := NULL;
DROP TEMPORARY TABLE IF EXISTS tmp_pagos_c;

-- ------------------------------------------------------------------
-- 13) Evaluaciones de seguimiento (200)  ✔
-- ------------------------------------------------------------------
SET @id_analista_demo = (
  SELECT e.id_empleado
  FROM empleados e
  WHERE e.id_cargo=@id_cargo_an AND e.id_estado=@id_emp_act
  ORDER BY e.id_empleado LIMIT 1
);

INSERT INTO evaluaciones_seguimiento(id_cliente, id_credito, id_analista, id_comp_pago, nivel_endeudamiento, puntaje_actualizado, observaciones, recomendaciones)
SELECT
  cr.id_cliente,
  cr.id_credito,
  @id_analista_demo,
  ELT((cr.id_credito % 5)+1,
      (SELECT id FROM comp_pago WHERE codigo='Excelente'),
      (SELECT id FROM comp_pago WHERE codigo='Bueno'),
      (SELECT id FROM comp_pago WHERE codigo='Regular'),
      (SELECT id FROM comp_pago WHERE codigo='Malo'),
      (SELECT id FROM comp_pago WHERE codigo='Muy_Malo')),
  ROUND( ( (SELECT COALESCE(SUM(cu.monto_cuota - cu.monto_pagado),0) FROM cuotas cu WHERE cu.id_credito=cr.id_credito)
          / GREATEST(1,(SELECT ingresos_declarados FROM clientes WHERE id_cliente=cr.id_cliente)) ) * 100, 2),
  600 + (cr.id_credito % 300),
  IF(cr.id_credito % 11=0, 'Revisar comportamiento reciente', NULL),
  IF(cr.id_credito % 7=0, 'Aumentar recordatorios de pago', 'Mantener monitoreo')
FROM creditos cr
WHERE cr.id_credito <= 200;

-- ------------------------------------------------------------------
-- 14) Relación Campaña-Producto (180)  ✔
-- ------------------------------------------------------------------
SET @camp_total := (SELECT COUNT(*) FROM campanias_promocionales);
SET @prod_total := (SELECT COUNT(*) FROM productos_financieros);

DROP TEMPORARY TABLE IF EXISTS map_campanias;
CREATE TEMPORARY TABLE map_campanias AS
SELECT ROW_NUMBER() OVER (ORDER BY id_campania) AS rn, id_campania
FROM campanias_promocionales;

DROP TEMPORARY TABLE IF EXISTS map_productos;
CREATE TEMPORARY TABLE map_productos AS
SELECT ROW_NUMBER() OVER (ORDER BY id_producto) AS rn, id_producto
FROM productos_financieros;

INSERT INTO campanias_productos(id_campania, id_producto)
SELECT mc.id_campania, mp.id_producto
FROM (
  SELECT n,
         ((n - 1) % @camp_total) + 1 AS rn_camp,
         ( (((n - 1) % @prod_total) * 7) + (FLOOR((n - 1)/@prod_total) * 13) )
           % @prod_total + 1 AS rn_prod
  FROM helper_seq
  WHERE n <= 180
) t
JOIN map_campanias mc ON mc.rn = t.rn_camp
JOIN map_productos  mp ON mp.rn = t.rn_prod;

-- ------------------------------------------------------------------
-- 15) Asignación de campañas a clientes existentes + Reconteo  ✔
-- ------------------------------------------------------------------
UPDATE clientes cl
JOIN creditos cr ON cr.id_cliente = cl.id_cliente
LEFT JOIN campanias_promocionales cp ON cp.id_campania = ((cr.id_credito - 1) % 60) + 1
SET cl.id_campania_ingreso = cp.id_campania
WHERE cl.id_campania_ingreso IS NULL;

UPDATE clientes cl
LEFT JOIN campanias_promocionales cp ON cp.id_campania = ((cl.id_cliente - 1) % 60) + 1
SET cl.id_campania_ingreso = cp.id_campania
WHERE cl.id_campania_ingreso IS NULL;

-- Recalcular contador de clientes captados
UPDATE campanias_promocionales cp
LEFT JOIN (
  SELECT id_campania_ingreso AS id_campania, COUNT(*) AS captados
  FROM clientes
  WHERE id_campania_ingreso IS NOT NULL
  GROUP BY id_campania_ingreso
) x ON x.id_campania = cp.id_campania
SET cp.clientes_captados = COALESCE(x.captados, 0);

-- ------------------------------------------------------------------
-- 15.bis) Campañas ↔ Clientes (trazabilidad N:M)  ✔
-- ------------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS tmp_cli_camp;
CREATE TEMPORARY TABLE tmp_cli_camp AS
SELECT
  cl.id_cliente,
  ((cl.id_cliente - 1) % 60) + 1 AS id_campania_base,
  DATE_ADD('2024-03-01', INTERVAL ((cl.id_cliente - 1) % 240) DAY) AS fecha_base
FROM clientes cl;

INSERT INTO campanias_clientes (id_campania, id_cliente, canal, resultado, fecha_contacto)
SELECT
  id_campania_base,
  id_cliente,
  ELT( (id_cliente % 4)+1, 'Web','Sucursal','Email','WhatsApp'),
  ELT( (id_cliente % 3)+1, 'Convirtio','No','No'),
  fecha_base
FROM tmp_cli_camp;

INSERT INTO campanias_clientes (id_campania, id_cliente, canal, resultado, fecha_contacto)
SELECT
  ((id_campania_base + 7 - 1) % 60) + 1,
  id_cliente,
  ELT( ((id_cliente+1) % 4)+1, 'Web','Sucursal','Email','WhatsApp'),
  ELT( ((id_cliente+1) % 3)+1, 'Convirtio','No','No'),
  DATE_ADD(fecha_base, INTERVAL (15 + (id_cliente % 31)) DAY)
FROM tmp_cli_camp
WHERE id_cliente % 2 = 0;

INSERT INTO campanias_clientes (id_campania, id_cliente, canal, resultado, fecha_contacto)
SELECT
  ((id_campania_base + 13 - 1) % 60) + 1,
  id_cliente,
  ELT( ((id_cliente+2) % 4)+1, 'Web','Sucursal','Email','WhatsApp'),
  ELT( ((id_cliente+2) % 3)+1, 'Convirtio','No','No'),
  DATE_ADD(fecha_base, INTERVAL (60 + (id_cliente % 45)) DAY)
FROM tmp_cli_camp
WHERE id_cliente % 10 IN (0,3,7);

DROP TEMPORARY TABLE IF EXISTS tmp_cli_camp;

-- ------------------------------------------------------------------
-- 16) Ajustes de estados (consistencia)  ✔
-- ------------------------------------------------------------------
UPDATE cuotas cu
JOIN (SELECT id AS id_pagada FROM estado_cuota WHERE codigo='Pagada') d1
JOIN (SELECT id AS id_pag_mora FROM estado_cuota WHERE codigo='Pagada_Con_Mora') d2
JOIN (SELECT id AS id_vencida FROM estado_cuota WHERE codigo='Vencida') d3
JOIN (SELECT id AS id_pend FROM estado_cuota WHERE codigo='Pendiente') d4
SET cu.id_estado = CASE
  WHEN cu.monto_pagado >= cu.monto_cuota AND CURDATE() > cu.fecha_vencimiento THEN d2.id_pag_mora
  WHEN cu.monto_pagado >= cu.monto_cuota THEN d1.id_pagada
  WHEN CURDATE() > cu.fecha_vencimiento THEN d3.id_vencida
  ELSE d4.id_pend
END
WHERE cu.borrado_logico = 0;

UPDATE creditos c
JOIN (
  SELECT id_credito,
         SUM(id_estado IN ((SELECT id FROM estado_cuota WHERE codigo='Pagada'),
                           (SELECT id FROM estado_cuota WHERE codigo='Pagada_Con_Mora'))) pagadas,
         SUM(id_estado = (SELECT id FROM estado_cuota WHERE codigo='Vencida')) vencidas,
         COUNT(*) total
  FROM cuotas WHERE borrado_logico=0 GROUP BY id_credito
) x ON x.id_credito=c.id_credito
JOIN (SELECT id AS id_act FROM estado_credito WHERE codigo='Activo') ec_act
JOIN (SELECT id AS id_mor FROM estado_credito WHERE codigo='En_Mora') ec_mor
JOIN (SELECT id AS id_pag FROM estado_credito WHERE codigo='Pagado') ec_pag
SET c.id_estado = CASE
  WHEN x.pagadas = x.total THEN ec_pag.id_pag
  WHEN x.vencidas > 0 THEN ec_mor.id_mor
  ELSE ec_act.id_act
END
WHERE c.borrado_logico=0;

-- ------------------------------------------------------------------
-- 17) Conteo por tabla (verificación)  ✔
-- ------------------------------------------------------------------
SELECT 'provincias' AS tabla, COUNT(*) AS filas FROM provincias
UNION ALL SELECT 'ciudades', COUNT(*) FROM ciudades
UNION ALL SELECT 'sucursales', COUNT(*) FROM sucursales
UNION ALL SELECT 'empleados', COUNT(*) FROM empleados
UNION ALL SELECT 'clientes', COUNT(*) FROM clientes
UNION ALL SELECT 'productos_financieros', COUNT(*) FROM productos_financieros
UNION ALL SELECT 'historico_tasas', COUNT(*) FROM historico_tasas
UNION ALL SELECT 'garantes', COUNT(*) FROM garantes
UNION ALL SELECT 'solicitudes_credito', COUNT(*) FROM solicitudes_credito
UNION ALL SELECT 'solicitudes_garantes', COUNT(*) FROM solicitudes_garantes
UNION ALL SELECT 'creditos', COUNT(*) FROM creditos
UNION ALL SELECT 'cuotas', COUNT(*) FROM cuotas
UNION ALL SELECT 'pagos', COUNT(*) FROM pagos
UNION ALL SELECT 'penalizaciones', COUNT(*) FROM penalizaciones
UNION ALL SELECT 'evaluaciones_seguimiento', COUNT(*) FROM evaluaciones_seguimiento
UNION ALL SELECT 'campanias_promocionales', COUNT(*) FROM campanias_promocionales
UNION ALL SELECT 'campanias_productos', COUNT(*) FROM campanias_productos
UNION ALL SELECT 'campanias_clientes', COUNT(*) FROM campanias_clientes
UNION ALL SELECT 'estado_sucursal', COUNT(*) FROM estado_sucursal
UNION ALL SELECT 'cargo_empleado', COUNT(*) FROM cargo_empleado
UNION ALL SELECT 'estado_empleado', COUNT(*) FROM estado_empleado
UNION ALL SELECT 'estado_cliente', COUNT(*) FROM estado_cliente
UNION ALL SELECT 'situacion_laboral', COUNT(*) FROM situacion_laboral
UNION ALL SELECT 'tipo_producto', COUNT(*) FROM tipo_producto
UNION ALL SELECT 'estado_producto', COUNT(*) FROM estado_producto
UNION ALL SELECT 'estado_campania', COUNT(*) FROM estado_campania
UNION ALL SELECT 'estado_solicitud', COUNT(*) FROM estado_solicitud
UNION ALL SELECT 'estado_credito', COUNT(*) FROM estado_credito
UNION ALL SELECT 'estado_cuota', COUNT(*) FROM estado_cuota
UNION ALL SELECT 'metodo_pago', COUNT(*) FROM metodo_pago
UNION ALL SELECT 'estado_penalizacion', COUNT(*) FROM estado_penalizacion
UNION ALL SELECT 'comp_pago', COUNT(*) FROM comp_pago;

-- Limpieza helper
DROP TABLE IF EXISTS helper_seq;
DROP TEMPORARY TABLE IF EXISTS map_ciudades;

SET sql_safe_updates = 1;
