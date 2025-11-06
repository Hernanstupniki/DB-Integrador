-- ===========================================
-- seed.sql  |  Datos demo masivos (MySQL 8)
-- Genera >= 60 filas por tabla (muchas >> 60)
-- SIN WITH RECURSIVE  |  SIN CTE en INSERT | Fechas acotadas
-- Fix 1442: INSERT pagos via tablas temporales
-- ===========================================

USE gestion_creditos;

-- Limpieza controlada (vaciar manteniendo estructura)
SET FOREIGN_KEY_CHECKS = 0;

-- Borrar en orden seguro (hijos -> padres)
DELETE FROM auditoria_tasas;
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
DELETE FROM provincias;

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

-- -----------------------------
-- 1) Provincias (60)
-- -----------------------------
INSERT INTO provincias(nombre)
SELECT CONCAT('Provincia ', n)
FROM helper_seq WHERE n <= 60;

-- ---------------------------------
-- 2) Sucursales (80)
-- ---------------------------------
INSERT INTO sucursales(nombre, id_provincia, ciudad, direccion, telefono, email, fecha_apertura, estado)
SELECT
  CONCAT('Sucursal ', n),
  ((n - 1) % 60) + 1,
  CONCAT('Ciudad ', ((n - 1) % 60) + 1),
  CONCAT('Calle ', n, ' #', 100 + n),
  CONCAT('0376-', LPAD(n, 4, '0')),
  CONCAT('suc', n, '@empresa.com'),
  DATE_ADD('2018-01-01', INTERVAL n DAY),
  IF(n % 20 = 0, 'Inactiva', 'Activa')
FROM helper_seq WHERE n <= 80;

-- ------------------------------------------------
-- 3) Empleados (300)
-- ------------------------------------------------
INSERT INTO empleados(id_sucursal,nombre,apellido,dni,cargo,email,telefono,fecha_ingreso,salario,estado)
SELECT
  ((n - 1) % 80) + 1,
  CONCAT('EmpNombre', n),
  CONCAT('EmpApellido', n),
  CONCAT('40', LPAD(n, 8, '0')),
  ELT( (n % 5)+1, 'Atencion_Cliente','Analista_Credito','Gerente','Cobranza','Administrador'),
  CONCAT('emp', n, '@empresa.com'),
  CONCAT('0376-', LPAD(5000 + n, 4, '0')),
  DATE_ADD('2020-01-01', INTERVAL (n % 1500) DAY),
  250000 + (n * 100),
  IF(n % 50 = 0, 'Inactivo', 'Activo')
FROM helper_seq WHERE n <= 300;

-- -----------------------------------------------
-- 4) Campañas promocionales (60)
-- -----------------------------------------------
INSERT INTO campanias_promocionales(nombre, descripcion, tasa_promocional, fecha_inicio, fecha_fin, descuento_porcentaje, estado, presupuesto, inversion_realizada, clientes_captados)
SELECT
  CONCAT('Campaña ', n),
  CONCAT('Campaña de captación #', n),
  10 + (n % 30),
  DATE_ADD('2023-01-01', INTERVAL n MONTH),
  DATE_ADD('2023-01-01', INTERVAL n+3 MONTH),
  (n % 20),
  IF(n % 17 = 0, 'Cancelada', IF(n % 7 = 0, 'Finalizada', 'Activa')),
  1000000 + n*5000,
  100000 + n*1200,
  0
FROM helper_seq WHERE n <= 60;

-- ------------------------------------------------------
-- 5) Clientes (500)
-- ------------------------------------------------------
INSERT INTO clientes(nombre, apellido, dni, fecha_nacimiento, email, telefono, direccion, ciudad, provincia, ingresos_declarados, situacion_laboral, id_campania_ingreso, estado)
SELECT
  CONCAT('CliNombre', n),
  CONCAT('CliApellido', n),
  CONCAT('30', LPAD(n, 8, '0')),
  DATE_ADD('1985-01-01', INTERVAL (n % 15000) DAY),
  CONCAT('cli', n, '@mail.com'),
  CONCAT('+54-9-376-', LPAD(n, 4, '0')),
  CONCAT('Av. Siempre Viva ', n),
  CONCAT('Ciudad ', ((n-1) % 60) + 1),
  CONCAT('Provincia ', ((n-1) % 60) + 1),
  300000 + (n * 200),
  ELT((n % 5)+1,'Empleado','Autonomo','Empresario','Jubilado','Desempleado'),
  IF(n % 4 = 0, ((n-1) % 60) + 1, NULL),
  IF(n % 97 = 0, 'Bloqueado', IF(n % 53 = 0, 'Moroso', 'Activo'))
FROM helper_seq WHERE n <= 500;

-- ------------------------------------------------
-- 6) Productos (60) + Histórico (180 con vigencias)
-- ------------------------------------------------
INSERT INTO productos_financieros(nombre, tipo, descripcion, tasa_base, monto_minimo, monto_maximo, plazo_minimo_meses, plazo_maximo_meses, requisitos, estado)
SELECT
  CONCAT('Producto ', n),
  ELT((n % 5)+1,'Personal','Hipotecario','Empresarial','Leasing','Tarjeta_Corporativa'),
  CONCAT('Descripción del producto ', n),
  40 + (n % 40),
  50000 + (n * 1000),
  1000000 + (n * 50000),
  6,
  60,
  'DNI, comprobantes, scoring',
  IF(n % 13 = 0, 'Inactivo', 'Activo')
FROM helper_seq WHERE n <= 60;

-- Histórico: 3 cambios por producto con vigencias encadenadas
-- Clamp: fecha_cambio limitada a 2037-12-31 para no exceder TIMESTAMP
INSERT INTO historico_tasas(
  id_producto, tasa_anterior, tasa_nueva, fecha_cambio,
  motivo, usuario_responsable, vigente_desde, vigente_hasta
)
SELECT
  p.id_producto,
  (p.tasa_base - 2) + (k - 1),
  (p.tasa_base - 1) + (k - 1),
  CASE
    WHEN DATE_ADD('2023-01-01', INTERVAL (p.id_producto*3 + k) MONTH) > '2037-12-31'
      THEN '2037-12-31 00:00:00'
    ELSE DATE_ADD('2023-01-01', INTERVAL (p.id_producto*3 + k) MONTH)
  END,
  CONCAT('Ajuste #', k),
  'seed@loader',
  DATE_ADD('2023-01-01', INTERVAL (k - 1) * 6 MONTH),
  CASE
    WHEN k = 3 THEN NULL
    ELSE DATE_SUB(DATE_ADD('2023-01-01', INTERVAL k * 6 MONTH), INTERVAL 1 DAY)
  END
FROM productos_financieros p
JOIN (SELECT 1 AS k UNION ALL SELECT 2 UNION ALL SELECT 3) ks;

-- -----------------------------------
-- 7) Garantes (300)
-- -----------------------------------
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

-- -----------------------------------
-- 8) Solicitudes (600)  **SIN CTE**
-- -----------------------------------
INSERT INTO solicitudes_credito(
  id_cliente, id_sucursal, id_empleado_gestor, id_producto,
  monto_solicitado, plazo_meses, destino_credito, fecha_solicitud,
  estado, puntaje_riesgo, id_analista, observaciones, fecha_evaluacion
)
SELECT
  ((s.n - 1) % 500) + 1,
  ((s.n - 1) % 80) + 1,
  (
    SELECT g.id_empleado FROM (
      SELECT id_empleado, ROW_NUMBER() OVER (ORDER BY id_empleado) rn
      FROM empleados
      WHERE cargo='Atencion_Cliente' AND estado='Activo'
    ) g
    WHERE g.rn = (
      ((s.n - 1) % (SELECT COUNT(*) FROM empleados WHERE cargo='Atencion_Cliente' AND estado='Activo')) + 1
    )
  ),
  ((s.n - 1) % 60) + 1,
  150000 + (s.n * 1000),
  6 + (s.n % 36),
  ELT((s.n % 5)+1,'Consumo','Capital de trabajo','Refacción','Vehículo','Varios'),
  DATE_ADD('2024-01-01', INTERVAL s.n DAY),
  ELT((s.n % 4)+1,'Pendiente','En_Revision','Aprobada','Rechazada'),
  600 + (s.n % 300),
  (
    SELECT a.id_empleado FROM (
      SELECT id_empleado, ROW_NUMBER() OVER (ORDER BY id_empleado) rn
      FROM empleados
      WHERE cargo='Analista_Credito' AND estado='Activo'
    ) a
    WHERE a.rn = (
      ((s.n - 1) % (SELECT COUNT(*) FROM empleados WHERE cargo='Analista_Credito' AND estado='Activo')) + 1
    )
  ),
  IF(s.n % 9 = 0, 'Observación de riesgo', NULL),
  IF(s.n % 4 IN (2,3), DATE_ADD('2024-01-01', INTERVAL s.n+5 DAY), NULL)
FROM helper_seq s
WHERE s.n <= 600;

-- ---------------------------------------------
-- 9) Solicitudes-Garantes (≥600)
-- ---------------------------------------------
INSERT INTO solicitudes_garantes(id_solicitud, id_garante)
SELECT s.id_solicitud,
       ((s.id_solicitud - 1) % 300) + 1
FROM solicitudes_credito s;

INSERT INTO solicitudes_garantes(id_solicitud, id_garante)
SELECT s.id_solicitud,
       ((s.id_solicitud + 77) % 300) + 1
FROM solicitudes_credito s
WHERE s.id_solicitud % 3 = 0;

-- -----------------------------------
-- 10) Créditos (todas las Aprobadas)
-- -----------------------------------
INSERT INTO creditos(
  id_solicitud, id_cliente, id_producto, monto_otorgado, tasa_interes,
  plazo_meses, fecha_inicio, fecha_finalizacion, estado, id_credito_refinanciado
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
  'Activo',
  NULL
FROM solicitudes_credito sc
WHERE sc.estado = 'Aprobada';

-- -----------------------------------
-- 11) Generar CUOTAS para todos los créditos
-- -----------------------------------
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

-- -----------------------------------
-- 12) PAGOS (parciales/completos; con y sin mora)
-- -----------------------------------
-- Por seguridad si re-corrés el seed
DELETE FROM pagos;
DELETE FROM penalizaciones;

-- a) 1ª cuota "al día" en la mitad de los créditos (EVITA 1442 con tabla temporal)
DROP TEMPORARY TABLE IF EXISTS tmp_pagos_a;
CREATE TEMPORARY TABLE tmp_pagos_a AS
SELECT
  c1.id_cuota  AS id_cuota,
  DATE_SUB(c1.fecha_vencimiento, INTERVAL 1 DAY) AS fecha_pago,
  ROUND(c1.monto_cuota * 0.5, 2) AS monto_pagado,
  'Transferencia' AS metodo_pago,
  CONCAT('CMP-ON-', c1.id_cuota) AS numero_comprobante
FROM cuotas c1
JOIN creditos cr ON cr.id_credito = c1.id_credito
WHERE c1.numero_cuota = 1 AND cr.id_credito % 2 = 0;

INSERT INTO pagos(id_cuota, fecha_pago, monto_pagado, metodo_pago, numero_comprobante)
SELECT id_cuota, fecha_pago, monto_pagado, metodo_pago, numero_comprobante
FROM tmp_pagos_a;

DROP TEMPORARY TABLE IF EXISTS tmp_pagos_a;

-- b) 1ª cuota con mora en la otra mitad (usa SP para penalización)
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
    WHERE c1.numero_cuota = 1 AND cr.id_credito % 2 = 1;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO vcuota;
    IF done = 1 THEN LEAVE read_loop; END IF;
    CALL sp_registrar_pago(
      vcuota,
      (SELECT ROUND(monto_cuota*0.6,2) FROM cuotas WHERE id_cuota=vcuota),
      'Efectivo',
      CONCAT('CMP-LT-', vcuota),
      0.0005  -- 0.05% diario
    );
  END LOOP;
  CLOSE cur;
END$$
DELIMITER ;

CALL sp_seed_pagar_mora_primera();
DROP PROCEDURE IF EXISTS sp_seed_pagar_mora_primera;

-- c) 2ª cuota al día para ~30% (EVITA 1442 con tabla temporal)
DROP TEMPORARY TABLE IF EXISTS tmp_pagos_c;
CREATE TEMPORARY TABLE tmp_pagos_c AS
SELECT
  c2.id_cuota AS id_cuota,
  DATE_SUB(c2.fecha_vencimiento, INTERVAL 2 DAY) AS fecha_pago,
  c2.monto_cuota AS monto_pagado,
  'Debito_Automatico' AS metodo_pago,
  CONCAT('CMP-2-', c2.id_cuota) AS numero_comprobante
FROM cuotas c2
JOIN creditos cr ON cr.id_credito = c2.id_credito
WHERE c2.numero_cuota = 2 AND (cr.id_credito % 3 = 0);

INSERT INTO pagos(id_cuota, fecha_pago, monto_pagado, metodo_pago, numero_comprobante)
SELECT id_cuota, fecha_pago, monto_pagado, metodo_pago, numero_comprobante
FROM tmp_pagos_c;

DROP TEMPORARY TABLE IF EXISTS tmp_pagos_c;

-- -----------------------------------
-- 13) Evaluaciones de seguimiento (200)
-- -----------------------------------
INSERT INTO evaluaciones_seguimiento(id_cliente, id_credito, id_analista, comportamiento_pago, nivel_endeudamiento, puntaje_actualizado, observaciones, recomendaciones)
SELECT
  cr.id_cliente,
  cr.id_credito,
  (SELECT id_empleado FROM empleados WHERE cargo='Analista_Credito' AND estado='Activo' ORDER BY id_empleado LIMIT 1),
  ELT((cr.id_credito % 5)+1,'Excelente','Bueno','Regular','Malo','Muy_Malo'),
  ROUND( ( (SELECT COALESCE(SUM(cu.monto_cuota - cu.monto_pagado),0) FROM cuotas cu WHERE cu.id_credito=cr.id_credito)
          / GREATEST(1,(SELECT ingresos_declarados FROM clientes WHERE id_cliente=cr.id_cliente)) ) * 100, 2),
  600 + (cr.id_credito % 300),
  IF(cr.id_credito % 11=0, 'Revisar comportamiento reciente', NULL),
  IF(cr.id_credito % 7=0, 'Aumentar recordatorios de pago', 'Mantener monitoreo')
FROM creditos cr
WHERE cr.id_credito <= 200;

-- -----------------------------------
-- 14) Relación Campaña-Producto (180)
-- -----------------------------------
-- Reemplazá tu INSERT de campanias_productos por este
DELETE FROM campanias_productos;

INSERT INTO campanias_productos(id_campania, id_producto)
SELECT camp, prod
FROM (
  SELECT
    ((n - 1) % 60) + 1 AS camp,                           -- 1..60 (se repite por ciclo)
    (                                                     -- producto permutado + offset por ciclo
      (
        (( (n - 1) % 60) * 7) +                           -- permutación coprima (×7)
        (FLOOR((n - 1)/60) * 13)                          -- offset por ciclo: 0, 13, 26
      ) % 60
    ) + 1 AS prod
  FROM helper_seq
  WHERE n <= 180                                          -- 3 ciclos de 60
) t;

-- -----------------------------------
-- 15) Ajustes de estados (consistencia)
-- -----------------------------------
UPDATE cuotas
SET estado = CASE
  WHEN monto_pagado >= monto_cuota AND CURDATE() > fecha_vencimiento THEN 'Pagada_Con_Mora'
  WHEN monto_pagado >= monto_cuota THEN 'Pagada'
  WHEN CURDATE() > fecha_vencimiento THEN 'Vencida'
  ELSE 'Pendiente'
END;

UPDATE creditos c
JOIN (
  SELECT id_credito,
         SUM(estado IN ('Pagada','Pagada_Con_Mora')) pagadas,
         SUM(estado='Vencida') vencidas,
         COUNT(*) total
  FROM cuotas GROUP BY id_credito
) x ON x.id_credito=c.id_credito
SET c.estado = CASE
  WHEN x.pagadas = x.total THEN 'Pagado'
  WHEN x.vencidas > 0 THEN 'En_Mora'
  ELSE 'Activo'
END;

-- -----------------------------------
-- 16) Conteo por tabla (verificación)
-- -----------------------------------
SELECT 'provincias' AS tabla, COUNT(*) AS filas FROM provincias
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
UNION ALL SELECT 'auditoria_tasas', COUNT(*) FROM auditoria_tasas;

-- Limpieza helper
DROP TABLE IF EXISTS helper_seq;
