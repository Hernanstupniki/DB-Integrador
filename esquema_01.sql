-- =====================================================
-- SISTEMA DE GESTIÓN DE CRÉDITOS Y COBRANZAS (COMPLETO)
-- MySQL 8.x - Sin ENGINE / Sin CHARACTER SET / Sin COLLATE
-- =====================================================

DROP DATABASE IF EXISTS gestion_creditos;
CREATE DATABASE gestion_creditos;
USE gestion_creditos;

SET FOREIGN_KEY_CHECKS = 0;
SET sql_notes = 0;

-- =========================
-- 1) TABLAS
-- =========================

CREATE TABLE provincias (
  id_provincia INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  UNIQUE KEY uq_provincia_nombre (nombre)
);

CREATE TABLE sucursales (
  id_sucursal INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  id_provincia INT NOT NULL,
  ciudad VARCHAR(50) NOT NULL,
  direccion VARCHAR(200),
  telefono VARCHAR(20),
  email VARCHAR(100),
  fecha_apertura DATE,
  estado ENUM('Activa','Inactiva') DEFAULT 'Activa',
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_sucursal_prov (id_provincia),
  INDEX idx_sucursal_estado (estado),
  FOREIGN KEY (id_provincia) REFERENCES provincias(id_provincia)
);

CREATE TABLE empleados (
  id_empleado INT AUTO_INCREMENT PRIMARY KEY,
  id_sucursal INT NOT NULL,
  nombre VARCHAR(100) NOT NULL,
  apellido VARCHAR(100) NOT NULL,
  dni VARCHAR(20) UNIQUE NOT NULL,
  cargo ENUM('Atencion_Cliente','Analista_Credito','Gerente','Cobranza','Administrador') NOT NULL,
  email VARCHAR(100) UNIQUE,
  telefono VARCHAR(20),
  fecha_ingreso DATE,
  salario DECIMAL(10,2),
  estado ENUM('Activo','Inactivo') DEFAULT 'Activo',
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_emp_sucursal (id_sucursal),
  INDEX idx_emp_cargo (cargo),
  FOREIGN KEY (id_sucursal) REFERENCES sucursales(id_sucursal)
);

CREATE TABLE clientes (
  id_cliente INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  apellido VARCHAR(100) NOT NULL,
  dni VARCHAR(20) UNIQUE NOT NULL,
  fecha_nacimiento DATE,
  email VARCHAR(100),
  telefono VARCHAR(20),
  direccion VARCHAR(200),
  ciudad VARCHAR(50),
  provincia VARCHAR(50),
  ingresos_declarados DECIMAL(12,2) DEFAULT 0,
  situacion_laboral ENUM('Empleado','Autonomo','Empresario','Jubilado','Desempleado'),
  id_campania_ingreso INT NULL,
  fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  estado ENUM('Activo','Inactivo','Moroso','Bloqueado') DEFAULT 'Activo',
  -- normalizadas (virtuales) para búsquedas consistentes
  provincia_norm VARCHAR(100) GENERATED ALWAYS AS (UPPER(TRIM(provincia))) VIRTUAL,
  ciudad_norm    VARCHAR(100) GENERATED ALWAYS AS (UPPER(TRIM(ciudad))) VIRTUAL,
  INDEX idx_cli_dni (dni),
  INDEX idx_cli_estado (estado),
  INDEX idx_cli_prov_norm (provincia_norm),
  INDEX idx_cli_ciud_norm (ciudad_norm)
);

CREATE TABLE productos_financieros (
  id_producto INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  tipo ENUM('Personal','Hipotecario','Empresarial','Leasing','Tarjeta_Corporativa') NOT NULL,
  descripcion TEXT,
  tasa_base DECIMAL(7,3) NOT NULL, -- % nominal anual base
  monto_minimo DECIMAL(12,2) NOT NULL,
  monto_maximo DECIMAL(14,2) NOT NULL,
  plazo_minimo_meses INT NOT NULL,
  plazo_maximo_meses INT NOT NULL,
  requisitos TEXT,
  estado ENUM('Activo','Inactivo') DEFAULT 'Activo',
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_producto_tipo (tipo)
);

-- Histórico con VIGENCIAS reales
CREATE TABLE historico_tasas (
  id_historico INT AUTO_INCREMENT PRIMARY KEY,
  id_producto INT NOT NULL,
  tasa_anterior DECIMAL(7,3) NOT NULL,
  tasa_nueva DECIMAL(7,3) NOT NULL,
  fecha_cambio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  motivo VARCHAR(200),
  usuario_responsable VARCHAR(100),
  vigente_desde DATE NULL,
  vigente_hasta DATE NULL,
  FOREIGN KEY (id_producto) REFERENCES productos_financieros(id_producto),
  INDEX idx_hist_producto_fecha (id_producto, fecha_cambio),
  INDEX idx_hist_vigencia (id_producto, vigente_desde, vigente_hasta)
);

CREATE TABLE garantes (
  id_garante INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  apellido VARCHAR(100) NOT NULL,
  dni VARCHAR(20) UNIQUE NOT NULL,
  email VARCHAR(100),
  telefono VARCHAR(20),
  direccion VARCHAR(200),
  ingresos_declarados DECIMAL(12,2) DEFAULT 0,
  relacion_cliente VARCHAR(50),
  fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_garante_dni (dni)
);

CREATE TABLE solicitudes_credito (
  id_solicitud INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente INT NOT NULL,
  id_sucursal INT NOT NULL,
  id_empleado_gestor INT NOT NULL,
  id_producto INT NOT NULL,
  monto_solicitado DECIMAL(14,2) NOT NULL,
  plazo_meses INT NOT NULL,
  destino_credito VARCHAR(200),
  fecha_solicitud TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  estado ENUM('Pendiente','En_Revision','Aprobada','Rechazada') DEFAULT 'Pendiente',
  puntaje_riesgo INT,
  id_analista INT,
  observaciones TEXT,
  fecha_evaluacion TIMESTAMP NULL,
  INDEX idx_sol_cliente (id_cliente),
  INDEX idx_sol_estado (estado),
  INDEX idx_sol_fecha (fecha_solicitud),
  FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
  FOREIGN KEY (id_sucursal) REFERENCES sucursales(id_sucursal),
  FOREIGN KEY (id_empleado_gestor) REFERENCES empleados(id_empleado),
  FOREIGN KEY (id_producto) REFERENCES productos_financieros(id_producto),
  FOREIGN KEY (id_analista) REFERENCES empleados(id_empleado)
);

CREATE TABLE solicitudes_garantes (
  id_solicitud INT NOT NULL,
  id_garante INT NOT NULL,
  fecha_vinculacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_solicitud, id_garante),
  FOREIGN KEY (id_solicitud) REFERENCES solicitudes_credito(id_solicitud) ON DELETE CASCADE,
  FOREIGN KEY (id_garante) REFERENCES garantes(id_garante)
);

CREATE TABLE creditos (
  id_credito INT AUTO_INCREMENT PRIMARY KEY,
  id_solicitud INT NOT NULL UNIQUE,
  id_cliente INT NOT NULL,
  id_producto INT NOT NULL,
  monto_otorgado DECIMAL(14,2) NOT NULL,
  tasa_interes DECIMAL(7,3) NOT NULL,
  plazo_meses INT NOT NULL,
  fecha_inicio DATE NOT NULL,
  fecha_finalizacion DATE NOT NULL,
  estado ENUM('Activo','Pagado','Refinanciado','En_Mora','Cancelado') DEFAULT 'Activo',
  id_credito_refinanciado INT NULL,
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_cre_cliente_estado (id_cliente, estado),
  INDEX idx_cre_fecha_inicio (fecha_inicio),
  FOREIGN KEY (id_solicitud) REFERENCES solicitudes_credito(id_solicitud),
  FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
  FOREIGN KEY (id_producto) REFERENCES productos_financieros(id_producto),
  FOREIGN KEY (id_credito_refinanciado) REFERENCES creditos(id_credito)
);

CREATE TABLE cuotas (
  id_cuota BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_credito INT NOT NULL,
  numero_cuota INT NOT NULL,
  fecha_vencimiento DATE NOT NULL,
  monto_cuota DECIMAL(14,2) NOT NULL,
  monto_capital DECIMAL(14,2) NOT NULL DEFAULT 0,
  monto_interes DECIMAL(14,2) NOT NULL DEFAULT 0,
  saldo_pendiente DECIMAL(14,2) NOT NULL DEFAULT 0,
  monto_pagado DECIMAL(14,2) NOT NULL DEFAULT 0,
  estado ENUM('Pendiente','Pagada','Vencida','Pagada_Con_Mora') DEFAULT 'Pendiente',
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_cuota (id_credito, numero_cuota),
  INDEX idx_cuota_credito_estado (id_credito, estado),
  INDEX idx_cuota_venc (fecha_vencimiento),
  FOREIGN KEY (id_credito) REFERENCES creditos(id_credito)
);

CREATE TABLE pagos (
  id_pago BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_cuota BIGINT NOT NULL,
  fecha_pago TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  monto_pagado DECIMAL(14,2) NOT NULL,
  metodo_pago ENUM('Efectivo','Transferencia','Debito_Automatico','Tarjeta','Cheque') NOT NULL,
  dias_demora INT DEFAULT 0,
  numero_comprobante VARCHAR(50),
  observaciones TEXT,
  INDEX idx_pago_cuota_fecha (id_cuota, fecha_pago),
  INDEX idx_pago_fecha_metodo (fecha_pago, metodo_pago),
  FOREIGN KEY (id_cuota) REFERENCES cuotas(id_cuota)
);

CREATE TABLE penalizaciones (
  id_penalizacion BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_cuota BIGINT NOT NULL,
  dias_mora INT NOT NULL,
  monto_penalizacion DECIMAL(14,2) NOT NULL,
  tasa_mora DECIMAL(7,3) NOT NULL,
  fecha_aplicacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  estado ENUM('Pendiente','Pagada') DEFAULT 'Pendiente',
  INDEX idx_pen_cuota (id_cuota),
  INDEX idx_pen_estado (estado),
  FOREIGN KEY (id_cuota) REFERENCES cuotas(id_cuota)
);

CREATE TABLE evaluaciones_seguimiento (
  id_evaluacion INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente INT NOT NULL,
  id_credito INT NOT NULL,
  id_analista INT NOT NULL,
  fecha_evaluacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  comportamiento_pago ENUM('Excelente','Bueno','Regular','Malo','Muy_Malo') NOT NULL,
  nivel_endeudamiento DECIMAL(7,3),
  puntaje_actualizado INT,
  observaciones TEXT,
  recomendaciones TEXT,
  INDEX idx_ev_cli (id_cliente),
  INDEX idx_ev_fecha (fecha_evaluacion),
  FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
  FOREIGN KEY (id_credito) REFERENCES creditos(id_credito),
  FOREIGN KEY (id_analista) REFERENCES empleados(id_empleado)
);

CREATE TABLE campanias_promocionales (
  id_campania INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  descripcion TEXT,
  tasa_promocional DECIMAL(7,3) NOT NULL,
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE NOT NULL,
  descuento_porcentaje DECIMAL(7,3),
  estado ENUM('Activa','Finalizada','Cancelada') DEFAULT 'Activa',
  presupuesto DECIMAL(14,2),
  inversion_realizada DECIMAL(14,2) DEFAULT 0,
  clientes_captados INT DEFAULT 0,
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_camp_fechas (fecha_inicio, fecha_fin),
  INDEX idx_camp_estado (estado)
);

CREATE TABLE campanias_productos (
  id_campania INT NOT NULL,
  id_producto INT NOT NULL,
  PRIMARY KEY (id_campania, id_producto),
  FOREIGN KEY (id_campania) REFERENCES campanias_promocionales(id_campania) ON DELETE CASCADE,
  FOREIGN KEY (id_producto) REFERENCES productos_financieros(id_producto)
);

ALTER TABLE clientes
  ADD CONSTRAINT fk_cli_campania_ingreso
  FOREIGN KEY (id_campania_ingreso) REFERENCES campanias_promocionales(id_campania);

-- Auditoría de cambios de tasas (tabla simple)
CREATE TABLE auditoria_tasas (
  id_aud BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_historico INT,
  id_producto INT,
  tasa DECIMAL(7,3),
  vigente_desde DATE,
  vigente_hasta DATE,
  operacion ENUM('INSERT','UPDATE'),
  audit_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

SET FOREIGN_KEY_CHECKS = 1;

-- =========================
-- 2) ÍNDICES ADICIONALES (≥5; con compuestos)
-- =========================

CREATE INDEX idx_solicitud_producto_fecha ON solicitudes_credito(id_producto, fecha_solicitud, estado);
CREATE INDEX idx_credito_cliente_estado ON creditos(id_cliente, estado, fecha_inicio);
CREATE INDEX idx_cuota_estado_vencimiento ON cuotas(estado, fecha_vencimiento);
CREATE INDEX idx_empleado_sucursal_cargo ON empleados(id_sucursal, cargo, estado);
CREATE INDEX idx_cliente_provincia_estado ON clientes(provincia_norm, estado);

-- =========================
-- 3) FUNCIONES Y PROCEDIMIENTOS (≥5)
-- =========================
DELIMITER $$

-- F1: calcular mora simple
CREATE FUNCTION fn_calcular_mora(monto DECIMAL(14,2), dias INT, tasa_diaria DECIMAL(7,5))
RETURNS DECIMAL(14,2)
DETERMINISTIC
BEGIN
  IF dias <= 0 OR monto <= 0 THEN RETURN 0.00; END IF;
  RETURN ROUND(monto * tasa_diaria * dias, 2);
END$$

-- F2: tasa vigente a una fecha usando ventanas (vigente_desde/hasta)
CREATE FUNCTION fn_tasa_vigente(p_id_producto INT, p_fecha DATE)
RETURNS DECIMAL(7,3)
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE v_tasa DECIMAL(7,3);
  SELECT h.tasa_nueva INTO v_tasa
  FROM historico_tasas h
  WHERE h.id_producto = p_id_producto
    AND (
      (h.vigente_desde IS NOT NULL AND h.vigente_hasta IS NOT NULL AND p_fecha BETWEEN h.vigente_desde AND h.vigente_hasta)
      OR (h.vigente_desde IS NOT NULL AND h.vigente_hasta IS NULL AND p_fecha >= h.vigente_desde)
    )
  ORDER BY h.vigente_desde DESC
  LIMIT 1;
  IF v_tasa IS NULL THEN
    SELECT h.tasa_nueva INTO v_tasa
    FROM historico_tasas h
    WHERE h.id_producto = p_id_producto AND DATE(h.fecha_cambio) <= p_fecha
    ORDER BY h.fecha_cambio DESC LIMIT 1;
  END IF;
  RETURN COALESCE(v_tasa, 0.000);
END$$

-- SP1: generar plan de cuotas (sistema francés)
CREATE PROCEDURE sp_generar_cuotas(IN p_id_credito INT)
BEGIN
  DECLARE v_monto DECIMAL(14,2);
  DECLARE v_tasa_a DECIMAL(7,3);
  DECLARE v_plazo INT;
  DECLARE v_inicio DATE;
  DECLARE v_i INT DEFAULT 1;
  DECLARE v_im DECIMAL(10,8);
  DECLARE v_cuota DECIMAL(14,2);
  DECLARE v_saldo DECIMAL(14,2);
  DECLARE v_int DECIMAL(14,2);
  DECLARE v_cap DECIMAL(14,2);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN ROLLBACK; SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Error generando cuotas'; END;

  START TRANSACTION;
    SELECT monto_otorgado, tasa_interes, plazo_meses, fecha_inicio
      INTO v_monto, v_tasa_a, v_plazo, v_inicio
    FROM creditos WHERE id_credito = p_id_credito FOR UPDATE;

    SET v_im = (v_tasa_a/100)/12;
    SET v_cuota = ROUND(v_monto * (v_im) / (1 - POW(1+v_im, -v_plazo)), 2);
    SET v_saldo = v_monto;

    WHILE v_i <= v_plazo DO
      SET v_int = ROUND(v_saldo * v_im, 2);
      SET v_cap = ROUND(v_cuota - v_int, 2);
      SET v_saldo = ROUND(GREATEST(0, v_saldo - v_cap), 2);

      INSERT INTO cuotas(id_credito, numero_cuota, fecha_vencimiento, monto_cuota, monto_capital, monto_interes, saldo_pendiente)
      VALUES (p_id_credito, v_i, DATE_ADD(v_inicio, INTERVAL v_i MONTH), v_cuota, v_cap, v_int, v_saldo);
      SET v_i = v_i + 1;
    END WHILE;
  COMMIT;
END$$

-- SP2 (PARCHEADO): aprobar solicitud con reglas de negocio
CREATE PROCEDURE sp_aprobar_solicitud(
  IN p_id_solicitud INT,
  IN p_monto_aprobado DECIMAL(14,2),
  IN p_tasa_anual DECIMAL(7,3),
  IN p_id_analista INT,
  IN p_puntaje INT
)
BEGIN
  DECLARE v_id_cliente INT; DECLARE v_id_producto INT; DECLARE v_plazo INT;
  DECLARE v_min DECIMAL(14,2); DECLARE v_max DECIMAL(14,2);
  DECLARE v_pmin INT; DECLARE v_pmax INT; DECLARE v_es_analista INT;
  DECLARE v_fecha_inicio DATE; DECLARE v_fecha_fin DATE; DECLARE v_id_credito INT;
  DECLARE v_cnt_gar INT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN ROLLBACK; SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Error al aprobar solicitud'; END;

  START TRANSACTION;
    -- 1) Solicitud válida y no procesada
    IF NOT EXISTS (SELECT 1 FROM solicitudes_credito
                   WHERE id_solicitud=p_id_solicitud AND estado IN ('Pendiente','En_Revision')) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Solicitud no válida o ya procesada';
    END IF;

    -- 2) Debe tener al menos un garante
    SELECT COUNT(*) INTO v_cnt_gar FROM solicitudes_garantes WHERE id_solicitud=p_id_solicitud;
    IF v_cnt_gar < 1 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La solicitud no posee garantes vinculados';
    END IF;

    -- 3) Cargar datos base
    SELECT id_cliente, id_producto, plazo_meses
      INTO v_id_cliente, v_id_producto, v_plazo
    FROM solicitudes_credito WHERE id_solicitud=p_id_solicitud FOR UPDATE;

    -- 4) Validar límites del producto
    SELECT monto_minimo, monto_maximo, plazo_minimo_meses, plazo_maximo_meses
      INTO v_min, v_max, v_pmin, v_pmax
    FROM productos_financieros WHERE id_producto=v_id_producto FOR UPDATE;

    IF p_monto_aprobado < v_min OR p_monto_aprobado > v_max THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Monto fuera de los límites del producto';
    END IF;

    IF v_plazo < v_pmin OR v_plazo > v_pmax THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Plazo fuera de los límites del producto';
    END IF;

    -- 5) Validar rol del analista
    SELECT COUNT(*) INTO v_es_analista
    FROM empleados WHERE id_empleado=p_id_analista AND cargo='Analista_Credito';
    IF v_es_analista = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El evaluador no tiene cargo Analista_Credito';
    END IF;

    -- 6) Aprobar + crear crédito + cuotas
    UPDATE solicitudes_credito
      SET estado='Aprobada', puntaje_riesgo=p_puntaje, id_analista=p_id_analista, fecha_evaluacion=NOW()
    WHERE id_solicitud=p_id_solicitud;

    SET v_fecha_inicio = CURDATE();
    SET v_fecha_fin = DATE_ADD(v_fecha_inicio, INTERVAL v_plazo MONTH);

    INSERT INTO creditos(id_solicitud,id_cliente,id_producto,monto_otorgado,tasa_interes,plazo_meses,fecha_inicio,fecha_finalizacion)
    VALUES (p_id_solicitud, v_id_cliente, v_id_producto, p_monto_aprobado, p_tasa_anual, v_plazo, v_fecha_inicio, v_fecha_fin);

    SET v_id_credito = LAST_INSERT_ID();
    CALL sp_generar_cuotas(v_id_credito);
  COMMIT;

  SELECT v_id_credito AS id_credito_creado;
END$$

-- SP3: registrar pago (con penalización automática)
CREATE PROCEDURE sp_registrar_pago(
  IN p_id_cuota BIGINT,
  IN p_monto DECIMAL(14,2),
  IN p_metodo VARCHAR(30),
  IN p_nro_comp VARCHAR(50),
  IN p_tasa_mora_diaria DECIMAL(7,5) -- ej 0.0005 (0.05% diario)
)
BEGIN
  DECLARE v_venc DATE; DECLARE v_monto_cuota DECIMAL(14,2);
  DECLARE v_dias INT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN ROLLBACK; SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Error al registrar pago'; END;

  START TRANSACTION;
    SELECT fecha_vencimiento, monto_cuota
      INTO v_venc, v_monto_cuota
    FROM cuotas WHERE id_cuota=p_id_cuota FOR UPDATE;

    SET v_dias = GREATEST(0, DATEDIFF(CURDATE(), v_venc));

    INSERT INTO pagos(id_cuota, monto_pagado, metodo_pago, dias_demora, numero_comprobante)
    VALUES (p_id_cuota, p_monto, p_metodo, v_dias, p_nro_comp);

    UPDATE cuotas
      SET monto_pagado = monto_pagado + p_monto
    WHERE id_cuota = p_id_cuota;

    IF v_dias > 0 THEN
      INSERT INTO penalizaciones(id_cuota, dias_mora, monto_penalizacion, tasa_mora)
      VALUES (p_id_cuota, v_dias, fn_calcular_mora(v_monto_cuota, v_dias, p_tasa_mora_diaria), p_tasa_mora_diaria*100);
    END IF;

    UPDATE cuotas
      SET estado = CASE
        WHEN monto_pagado >= monto_cuota AND v_dias>0 THEN 'Pagada_Con_Mora'
        WHEN monto_pagado >= monto_cuota THEN 'Pagada'
        WHEN CURDATE() > fecha_vencimiento THEN 'Vencida'
        ELSE 'Pendiente'
      END
    WHERE id_cuota=p_id_cuota;

    UPDATE creditos c
    JOIN (
      SELECT id_credito,
             SUM(estado='Pagada' OR estado='Pagada_Con_Mora') pagadas,
             SUM(estado='Vencida') vencidas,
             COUNT(*) total
      FROM cuotas WHERE id_credito = (SELECT id_credito FROM cuotas WHERE id_cuota=p_id_cuota)
      GROUP BY id_credito
    ) x ON x.id_credito = c.id_credito
    SET c.estado = CASE
                     WHEN x.pagadas = x.total THEN 'Pagado'
                     WHEN x.vencidas > 0 THEN 'En_Mora'
                     ELSE 'Activo'
                   END;
  COMMIT;
END$$

-- SP4: asignar evaluación (Aprobada | Rechazada | En_Revision)
CREATE PROCEDURE sp_asignar_evaluacion(
  IN p_id_solicitud INT,
  IN p_id_analista INT,
  IN p_puntaje INT,
  IN p_decision VARCHAR(20),
  IN p_obs TEXT
)
BEGIN
  DECLARE v_decision VARCHAR(20);
  SET v_decision = UPPER(REPLACE(p_decision,' ',''));

  IF v_decision NOT IN ('APROBADA','RECHAZADA','EN_REVISION') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Decisión inválida (Aprobada|Rechazada|En_Revision)';
  END IF;

  UPDATE solicitudes_credito
    SET estado = CASE
                   WHEN v_decision='APROBADA' THEN 'Aprobada'
                   WHEN v_decision='RECHAZADA' THEN 'Rechazada'
                   ELSE 'En_Revision'
                 END,
        puntaje_riesgo = p_puntaje,
        id_analista = p_id_analista,
        fecha_evaluacion = NOW(),
        observaciones = p_obs
  WHERE id_solicitud = p_id_solicitud;
END$$

-- SP5: refinanciar crédito (crea nuevo vinculado)
CREATE PROCEDURE sp_refinanciar_credito(
  IN p_id_credito_original INT,
  IN p_monto_nuevo DECIMAL(14,2),
  IN p_plazo_nuevo INT,
  IN p_tasa_nueva DECIMAL(7,3)
)
BEGIN
  DECLARE v_id_cliente INT; DECLARE v_id_producto INT; DECLARE v_id_solicitud INT;
  DECLARE v_id_nuevo_credito INT; DECLARE v_inicio DATE; DECLARE v_fin DATE;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN ROLLBACK; SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Error en refinanciación'; END;

  START TRANSACTION;
    IF NOT EXISTS (SELECT 1 FROM creditos WHERE id_credito=p_id_credito_original AND estado IN ('Activo','En_Mora')) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Crédito no válido para refinanciación';
    END IF;

    SELECT id_cliente, id_producto, id_solicitud
      INTO v_id_cliente, v_id_producto, v_id_solicitud
    FROM creditos WHERE id_credito=p_id_credito_original FOR UPDATE;

    UPDATE creditos SET estado='Refinanciado' WHERE id_credito=p_id_credito_original;

    SET v_inicio = CURDATE();
    SET v_fin = DATE_ADD(v_inicio, INTERVAL p_plazo_nuevo MONTH);

    INSERT INTO creditos(id_solicitud,id_cliente,id_producto,monto_otorgado,tasa_interes,plazo_meses,fecha_inicio,fecha_finalizacion,id_credito_refinanciado,estado)
    VALUES (v_id_solicitud, v_id_cliente, v_id_producto, p_monto_nuevo, p_tasa_nueva, p_plazo_nuevo, v_inicio, v_fin, p_id_credito_original, 'Activo');

    SET v_id_nuevo_credito = LAST_INSERT_ID();
    CALL sp_generar_cuotas(v_id_nuevo_credito);
  COMMIT;

  SELECT v_id_nuevo_credito AS id_credito_refinanciado;
END$$

DELIMITER ;

-- =========================
-- 4) TRIGGERS (≥5)
-- =========================
DELIMITER $$

-- T1/T2: normalizar provincia/ciudad en clientes (trim/espacios)
CREATE TRIGGER trg_clientes_bi BEFORE INSERT ON clientes
FOR EACH ROW
BEGIN
  SET NEW.provincia = TRIM(REPLACE(REPLACE(NEW.provincia,'  ',' '),'  ',' '));
  SET NEW.ciudad    = TRIM(REPLACE(REPLACE(NEW.ciudad,'  ',' '),'  ',' '));
END$$

CREATE TRIGGER trg_clientes_bu BEFORE UPDATE ON clientes
FOR EACH ROW
BEGIN
  SET NEW.provincia = TRIM(REPLACE(REPLACE(NEW.provincia,'  ',' '),'  ',' '));
  SET NEW.ciudad    = TRIM(REPLACE(REPLACE(NEW.ciudad,'  ',' '),'  ',' '));
END$$

-- T3: calcular días de demora antes de insertar pago
CREATE TRIGGER trg_pago_calcular_demora BEFORE INSERT ON pagos
FOR EACH ROW
BEGIN
  DECLARE v_venc DATE;
  SELECT fecha_vencimiento INTO v_venc FROM cuotas WHERE id_cuota = NEW.id_cuota;
  SET NEW.dias_demora = GREATEST(0, DATEDIFF(DATE(NEW.fecha_pago), v_venc));
END$$

-- T4: actualizar estado de cuota después de pago
CREATE TRIGGER trg_pago_actualiza_cuota AFTER INSERT ON pagos
FOR EACH ROW
BEGIN
  UPDATE cuotas
    SET estado = CASE
      WHEN monto_pagado >= monto_cuota AND NEW.dias_demora>0 THEN 'Pagada_Con_Mora'
      WHEN monto_pagado >= monto_cuota THEN 'Pagada'
      WHEN CURDATE() > fecha_vencimiento THEN 'Vencida'
      ELSE 'Pendiente'
    END
  WHERE id_cuota = NEW.id_cuota;
END$$

-- T5: estado del crédito por cambios en cuota
CREATE TRIGGER trg_cuota_actualiza_credito AFTER UPDATE ON cuotas
FOR EACH ROW
BEGIN
  DECLARE v_id_credito INT;
  SET v_id_credito = NEW.id_credito;

  UPDATE creditos c
  JOIN (
    SELECT id_credito,
           SUM(estado='Pagada' OR estado='Pagada_Con_Mora') pagadas,
           SUM(estado='Vencida') vencidas,
           COUNT(*) total
    FROM cuotas WHERE id_credito=v_id_credito
    GROUP BY id_credito
  ) x ON x.id_credito = c.id_credito
  SET c.estado = CASE
                   WHEN x.pagadas = x.total THEN 'Pagado'
                   WHEN x.vencidas > 0 THEN 'En_Mora'
                   ELSE 'Activo'
                 END
  WHERE c.id_credito = v_id_credito;
END$$

-- T6/T7: auditoría de tasas (insert/update)
CREATE TRIGGER trg_hist_insert AFTER INSERT ON historico_tasas
FOR EACH ROW
BEGIN
  INSERT INTO auditoria_tasas(id_historico,id_producto,tasa,vigente_desde,vigente_hasta,operacion)
  VALUES (NEW.id_historico, NEW.id_producto, NEW.tasa_nueva, NEW.vigente_desde, NEW.vigente_hasta, 'INSERT');
END$$

CREATE TRIGGER trg_hist_update AFTER UPDATE ON historico_tasas
FOR EACH ROW
BEGIN
  INSERT INTO auditoria_tasas(id_historico,id_producto,tasa,vigente_desde,vigente_hasta,operacion)
  VALUES (NEW.id_historico, NEW.id_producto, NEW.tasa_nueva, NEW.vigente_desde, NEW.vigente_hasta, 'UPDATE');
END$$

-- T8: al crear cliente con campaña, incrementar captados
CREATE TRIGGER trg_cliente_campania AFTER INSERT ON clientes
FOR EACH ROW
BEGIN
  IF NEW.id_campania_ingreso IS NOT NULL THEN
    UPDATE campanias_promocionales
      SET clientes_captados = clientes_captados + 1
    WHERE id_campania = NEW.id_campania_ingreso;
  END IF;
END$$

DELIMITER ;

-- =========================
-- 5) Backfill de vigencias en historico_tasas (si hubieran inserts sin vigencia)
-- =========================
WITH ord AS (
  SELECT id_historico, id_producto,
         DATE(fecha_cambio) d_desde,
         LEAD(DATE(fecha_cambio)) OVER (PARTITION BY id_producto ORDER BY fecha_cambio) prox
  FROM historico_tasas
)
UPDATE historico_tasas h
JOIN ord o ON o.id_historico=h.id_historico
SET h.vigente_desde = COALESCE(h.vigente_desde, o.d_desde),
    h.vigente_hasta = COALESCE(h.vigente_hasta, CASE WHEN o.prox IS NULL THEN NULL ELSE DATE_SUB(o.prox, INTERVAL 1 DAY) END);

-- =========================
-- 6) USUARIOS Y PERMISOS (≥3) + EXECUTE
-- =========================

-- Admin del sistema
CREATE USER IF NOT EXISTS 'admin_creditos'@'localhost' IDENTIFIED BY 'Admin2024$Secure';
GRANT ALL PRIVILEGES ON gestion_creditos.* TO 'admin_creditos'@'localhost';
GRANT CREATE USER ON *.* TO 'admin_creditos'@'localhost';

-- Analista de crédito
CREATE USER IF NOT EXISTS 'analista_credito'@'localhost' IDENTIFIED BY 'Analista2024$Pass';
GRANT SELECT ON gestion_creditos.* TO 'analista_credito'@'localhost';
GRANT UPDATE (puntaje_riesgo, id_analista, estado, fecha_evaluacion, observaciones)
ON gestion_creditos.solicitudes_credito
TO 'analista_credito'@'localhost';
GRANT EXECUTE ON PROCEDURE gestion_creditos.sp_aprobar_solicitud   TO 'analista_credito'@'localhost';
GRANT EXECUTE ON PROCEDURE gestion_creditos.sp_refinanciar_credito TO 'analista_credito'@'localhost';
GRANT EXECUTE ON PROCEDURE gestion_creditos.sp_asignar_evaluacion  TO 'analista_credito'@'localhost';

-- Gestor de cobranzas
CREATE USER IF NOT EXISTS 'gestor_cobranza'@'localhost' IDENTIFIED BY 'Cobranza2024$Key';
GRANT SELECT ON gestion_creditos.clientes TO 'gestor_cobranza'@'localhost';
GRANT SELECT ON gestion_creditos.creditos TO 'gestor_cobranza'@'localhost';
GRANT SELECT, UPDATE ON gestion_creditos.cuotas TO 'gestor_cobranza'@'localhost';
GRANT SELECT, INSERT ON gestion_creditos.pagos TO 'gestor_cobranza'@'localhost';
GRANT SELECT, INSERT ON gestion_creditos.penalizaciones TO 'gestor_cobranza'@'localhost';
GRANT EXECUTE ON PROCEDURE gestion_creditos.sp_registrar_pago TO 'gestor_cobranza'@'localhost';

FLUSH PRIVILEGES;

SET sql_notes = 1;
