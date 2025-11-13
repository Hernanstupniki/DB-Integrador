-- =====================================================
-- SISTEMA DE GESTIÓN DE CRÉDITOS Y COBRANZAS (MEJORADO, ESCALABLE GEO)
-- MySQL 8.x - Sin ENGINE / CHARSET / COLLATE explícitos
-- ✓ Soft-delete + auditoría (alta/mod/baja)
-- ✓ Catálogos (sin ENUM) + DOM
-- ✓ Penalización AFTER INSERT en pagos (tasa diaria 0.0005)
-- ✓ SPs/funciones con validaciones de negocio
-- ✓ Auditoría centralizada: auditoria_eventos + triggers (VARCHAR+CHECK)
-- ✓ Guardia en pagos: variable de sesión @__allow_pago_insert
-- ✓ Anti-solape en histórico de tasas
-- ✓ Anti-aprobación sin garantes
-- ✓ Evita sobrepago de cuota
-- ✓ Trazabilidad N:M: campanias_clientes
-- ✓ Geografía escalable: provincias + ciudades (FKs) + columnas texto de compatibilidad
-- SIN INSERTS de datos (cargar con seed_02.sql)
-- =====================================================

DROP DATABASE IF EXISTS gestion_creditos;
CREATE DATABASE gestion_creditos;
USE gestion_creditos;

SET FOREIGN_KEY_CHECKS = 0;
SET sql_notes = 0;

-- =========================
-- 0) TABLAS DE DOMINIO
-- =========================
CREATE TABLE dom_estado_sucursal (
  id INT AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(50) NOT NULL UNIQUE,
  nombre VARCHAR(100) NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100)
);

CREATE TABLE dom_cargo_empleado (
  id INT AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(50) NOT NULL UNIQUE,
  nombre VARCHAR(100) NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100)
);

CREATE TABLE dom_estado_empleado (
  id INT AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(50) NOT NULL UNIQUE,
  nombre VARCHAR(100) NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100)
);

CREATE TABLE dom_estado_cliente (
  id INT AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(50) NOT NULL UNIQUE,
  nombre VARCHAR(100) NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100)
);

CREATE TABLE dom_situacion_laboral (
  id INT AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(50) NOT NULL UNIQUE,
  nombre VARCHAR(100) NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100)
);

CREATE TABLE dom_tipo_producto (
  id INT AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(50) NOT NULL UNIQUE,
  nombre VARCHAR(100) NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100)
);

CREATE TABLE dom_estado_producto (
  id INT AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(50) NOT NULL UNIQUE,
  nombre VARCHAR(100) NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100)
);

CREATE TABLE dom_estado_campania (
  id INT AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(50) NOT NULL UNIQUE,
  nombre VARCHAR(100) NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100)
);

CREATE TABLE dom_estado_solicitud (
  id INT AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(50) NOT NULL UNIQUE,
  nombre VARCHAR(100) NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100)
);

CREATE TABLE dom_estado_credito (
  id INT AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(50) NOT NULL UNIQUE,
  nombre VARCHAR(100) NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100)
);

CREATE TABLE dom_estado_cuota (
  id INT AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(50) NOT NULL UNIQUE,
  nombre VARCHAR(100) NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100)
);

CREATE TABLE dom_metodo_pago (
  id INT AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(50) NOT NULL UNIQUE,
  nombre VARCHAR(100) NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100)
);

CREATE TABLE dom_estado_penalizacion (
  id INT AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(50) NOT NULL UNIQUE,
  nombre VARCHAR(100) NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100)
);

CREATE TABLE dom_comp_pago (
  id INT AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(50) NOT NULL UNIQUE,
  nombre VARCHAR(100) NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100)
);

-- =========================
-- 1) MAESTROS GEO (escalable)
-- =========================
CREATE TABLE provincias (
  id_provincia INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100),
  UNIQUE KEY uq_provincia_nombre (nombre),
  INDEX idx_prov_isdel (is_deleted)
);

CREATE TABLE ciudades (
  id_ciudad INT AUTO_INCREMENT PRIMARY KEY,
  id_provincia INT NOT NULL,
  nombre VARCHAR(100) NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100),
  CONSTRAINT uq_ciudad UNIQUE KEY (id_provincia, nombre),
  INDEX idx_ciudad_prov (id_provincia),
  INDEX idx_ciudad_isdel (is_deleted),
  FOREIGN KEY (id_provincia) REFERENCES provincias(id_provincia)
);

-- =========================
-- 2) NEGOCIO
-- =========================
CREATE TABLE campanias_promocionales (
  id_campania INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  descripcion TEXT,
  tasa_promocional DECIMAL(7,3) NOT NULL,
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE NOT NULL,
  descuento_porcentaje DECIMAL(7,3),
  id_estado INT NOT NULL, -- dom_estado_campania
  presupuesto DECIMAL(14,2),
  inversion_realizada DECIMAL(14,2) DEFAULT 0,
  clientes_captados INT DEFAULT 0,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100),
  INDEX idx_camp_fechas (fecha_inicio, fecha_fin),
  INDEX idx_camp_estado (id_estado),
  INDEX idx_camp_isdel (is_deleted),
  FOREIGN KEY (id_estado) REFERENCES dom_estado_campania(id),
  CHECK (fecha_fin > fecha_inicio)
);

CREATE TABLE sucursales (
  id_sucursal INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  id_provincia INT NOT NULL,
  id_ciudad INT NULL,             -- NUEVO FK (escalable)
  ciudad VARCHAR(50) NOT NULL,    -- compatibilidad con seeds actuales
  direccion VARCHAR(200),
  telefono VARCHAR(20),
  email VARCHAR(100),
  fecha_apertura DATE,
  id_estado INT NOT NULL, -- dom_estado_sucursal
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100),
  INDEX idx_sucursal_prov (id_provincia),
  INDEX idx_sucursal_ciud (id_ciudad),
  INDEX idx_sucursal_estado (id_estado),
  INDEX idx_sucursal_isdel (is_deleted),
  FOREIGN KEY (id_provincia) REFERENCES provincias(id_provincia),
  FOREIGN KEY (id_ciudad)    REFERENCES ciudades(id_ciudad),
  FOREIGN KEY (id_estado)    REFERENCES dom_estado_sucursal(id)
);

CREATE TABLE empleados (
  id_empleado INT AUTO_INCREMENT PRIMARY KEY,
  id_sucursal INT NOT NULL,
  nombre VARCHAR(100) NOT NULL,
  apellido VARCHAR(100) NOT NULL,
  dni VARCHAR(20) UNIQUE NOT NULL,
  id_cargo INT NOT NULL,
  email VARCHAR(100) UNIQUE,
  telefono VARCHAR(20),
  fecha_ingreso DATE,
  salario DECIMAL(10,2),
  id_estado INT NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100),
  INDEX idx_emp_sucursal (id_sucursal),
  INDEX idx_emp_cargo (id_cargo),
  INDEX idx_emp_estado (id_estado),
  INDEX idx_emp_isdel (is_deleted),
  FOREIGN KEY (id_sucursal) REFERENCES sucursales(id_sucursal),
  FOREIGN KEY (id_cargo)    REFERENCES dom_cargo_empleado(id),
  FOREIGN KEY (id_estado)   REFERENCES dom_estado_empleado(id)
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
  ciudad VARCHAR(50),              -- compatibilidad
  provincia VARCHAR(50),          -- compatibilidad
  id_provincia INT NULL,          -- NUEVO FK escalable
  id_ciudad INT NULL,             -- NUEVO FK escalable
  ingresos_declarados DECIMAL(12,2) DEFAULT 0 CHECK (ingresos_declarados >= 0),
  id_situacion_laboral INT,
  id_campania_ingreso INT NULL,
  id_estado INT NOT NULL,
  provincia_norm VARCHAR(100) GENERATED ALWAYS AS (UPPER(TRIM(provincia))) VIRTUAL,
  ciudad_norm    VARCHAR(100) GENERATED ALWAYS AS (UPPER(TRIM(ciudad))) VIRTUAL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100),
  INDEX idx_cli_dni (dni),
  INDEX idx_cli_estado (id_estado),
  INDEX idx_cli_prov_norm (provincia_norm),
  INDEX idx_cli_ciud_norm (ciudad_norm),
  INDEX idx_cli_idprov (id_provincia),
  INDEX idx_cli_idciud (id_ciudad),
  INDEX idx_cli_isdel (is_deleted),
  FOREIGN KEY (id_situacion_laboral) REFERENCES dom_situacion_laboral(id),
  FOREIGN KEY (id_campania_ingreso) REFERENCES campanias_promocionales(id_campania),
  FOREIGN KEY (id_estado) REFERENCES dom_estado_cliente(id),
  FOREIGN KEY (id_provincia) REFERENCES provincias(id_provincia),
  FOREIGN KEY (id_ciudad)    REFERENCES ciudades(id_ciudad)
);

CREATE TABLE productos_financieros (
  id_producto INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  id_tipo INT NOT NULL,
  descripcion TEXT,
  tasa_base DECIMAL(7,3) NOT NULL CHECK (tasa_base >= 0),
  monto_minimo DECIMAL(12,2) NOT NULL CHECK (monto_minimo >= 0),
  monto_maximo DECIMAL(14,2) NOT NULL,
  plazo_minimo_meses INT NOT NULL CHECK (plazo_minimo_meses > 0),
  plazo_maximo_meses INT NOT NULL,
  requisitos TEXT,
  id_estado INT NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100),
  INDEX idx_producto_tipo (id_tipo),
  INDEX idx_pf_estado (id_estado),
  INDEX idx_pf_isdel (is_deleted),
  FOREIGN KEY (id_tipo)   REFERENCES dom_tipo_producto(id),
  FOREIGN KEY (id_estado) REFERENCES dom_estado_producto(id),
  CHECK (monto_maximo >= monto_minimo),
  CHECK (plazo_maximo_meses >= plazo_minimo_meses)
);

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
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100),
  FOREIGN KEY (id_producto) REFERENCES productos_financieros(id_producto),
  INDEX idx_hist_producto_fecha (id_producto, fecha_cambio),
  INDEX idx_hist_vigencia (id_producto, vigente_desde, vigente_hasta),
  INDEX idx_ht_isdel (is_deleted),
  UNIQUE KEY uq_hist_producto_fecha (id_producto, fecha_cambio)
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
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100),
  INDEX idx_garante_dni (dni),
  INDEX idx_garante_isdel (is_deleted)
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
  id_estado INT NOT NULL,
  puntaje_riesgo INT,
  id_analista INT,
  observaciones TEXT,
  fecha_evaluacion TIMESTAMP NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100),
  INDEX idx_sol_cliente (id_cliente),
  INDEX idx_sol_estado (id_estado),
  INDEX idx_sol_fecha (fecha_solicitud),
  INDEX idx_sol_isdel (is_deleted),
  FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
  FOREIGN KEY (id_sucursal) REFERENCES sucursales(id_sucursal),
  FOREIGN KEY (id_empleado_gestor) REFERENCES empleados(id_empleado),
  FOREIGN KEY (id_producto) REFERENCES productos_financieros(id_producto),
  FOREIGN KEY (id_analista) REFERENCES empleados(id_empleado),
  FOREIGN KEY (id_estado) REFERENCES dom_estado_solicitud(id)
);

CREATE TABLE solicitudes_garantes (
  id_solicitud INT NOT NULL,
  id_garante INT NOT NULL,
  fecha_vinculacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100),
  PRIMARY KEY (id_solicitud, id_garante),
  FOREIGN KEY (id_solicitud) REFERENCES solicitudes_credito(id_solicitud) ON DELETE CASCADE,
  FOREIGN KEY (id_garante) REFERENCES garantes(id_garante),
  INDEX idx_sg_sol_isdel (id_solicitud, is_deleted)
);

CREATE TABLE creditos (
  id_credito INT AUTO_INCREMENT PRIMARY KEY,
  id_solicitud INT NOT NULL,
  id_cliente INT NOT NULL,
  id_producto INT NOT NULL,
  monto_otorgado DECIMAL(14,2) NOT NULL,
  tasa_interes  DECIMAL(7,3)  NOT NULL,
  plazo_meses   INT           NOT NULL,
  fecha_inicio DATE NOT NULL,
  fecha_finalizacion DATE NOT NULL,
  id_estado INT NOT NULL,
  id_credito_refinanciado INT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100),
  INDEX idx_creditos_solicitud (id_solicitud),
  INDEX idx_cre_fecha_inicio (fecha_inicio),
  INDEX idx_cre_isdel (is_deleted),
  FOREIGN KEY (id_solicitud) REFERENCES solicitudes_credito(id_solicitud),
  FOREIGN KEY (id_cliente)  REFERENCES clientes(id_cliente),
  FOREIGN KEY (id_producto) REFERENCES productos_financieros(id_producto),
  FOREIGN KEY (id_estado)   REFERENCES dom_estado_credito(id),
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
  id_estado INT NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100),
  UNIQUE KEY uq_cuota (id_credito, numero_cuota),
  INDEX idx_cuota_credito_estado (id_credito, id_estado),
  INDEX idx_cuota_venc (fecha_vencimiento),
  INDEX idx_cuota_isdel (is_deleted),
  INDEX idx_cuota_credito_isdel (id_credito, is_deleted),
  FOREIGN KEY (id_credito) REFERENCES creditos(id_credito),
  FOREIGN KEY (id_estado)  REFERENCES dom_estado_cuota(id)
);

CREATE TABLE pagos (
  id_pago BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_cuota BIGINT NOT NULL,
  fecha_pago TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  monto_pagado DECIMAL(14,2) NOT NULL,
  id_metodo INT NOT NULL,
  dias_demora INT DEFAULT 0,
  numero_comprobante VARCHAR(50),
  observaciones TEXT,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100),
  INDEX idx_pago_cuota_fecha (id_cuota, fecha_pago),
  INDEX idx_pago_fecha_metodo (fecha_pago, id_metodo),
  INDEX idx_pago_isdel (is_deleted),
  INDEX idx_pago_cuota_isdel (id_cuota, is_deleted),
  UNIQUE KEY uq_pagos_comprobante (numero_comprobante),
  FOREIGN KEY (id_cuota) REFERENCES cuotas(id_cuota),
  FOREIGN KEY (id_metodo) REFERENCES dom_metodo_pago(id)
);

CREATE TABLE penalizaciones (
  id_penalizacion BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_cuota BIGINT NOT NULL,
  dias_mora INT NOT NULL,
  monto_penalizacion DECIMAL(14,2) NOT NULL,
  tasa_mora DECIMAL(7,5) NOT NULL,
  fecha_aplicacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  id_estado INT NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100),
  INDEX idx_pen_cuota (id_cuota),
  INDEX idx_pen_estado (id_estado),
  INDEX idx_pen_isdel (is_deleted),
  FOREIGN KEY (id_cuota) REFERENCES cuotas(id_cuota),
  FOREIGN KEY (id_estado) REFERENCES dom_estado_penalizacion(id)
);

CREATE TABLE evaluaciones_seguimiento (
  id_evaluacion INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente INT NOT NULL,
  id_credito INT NOT NULL,
  id_analista INT NOT NULL,
  fecha_evaluacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  id_comp_pago INT NOT NULL,
  nivel_endeudamiento DECIMAL(7,3),
  puntaje_actualizado INT,
  observaciones TEXT,
  recomendaciones TEXT,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100),
  INDEX idx_ev_cli (id_cliente),
  INDEX idx_ev_fecha (fecha_evaluacion),
  INDEX idx_ev_isdel (is_deleted),
  FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
  FOREIGN KEY (id_credito) REFERENCES creditos(id_credito),
  FOREIGN KEY (id_analista) REFERENCES empleados(id_empleado),
  FOREIGN KEY (id_comp_pago) REFERENCES dom_comp_pago(id)
);

CREATE TABLE campanias_productos (
  id_campania INT NOT NULL,
  id_producto INT NOT NULL,
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100),
  PRIMARY KEY (id_campania, id_producto),
  FOREIGN KEY (id_campania) REFERENCES campanias_promocionales(id_campania) ON DELETE CASCADE,
  FOREIGN KEY (id_producto) REFERENCES productos_financieros(id_producto),
  INDEX idx_cp_isdel (is_deleted)
);

CREATE TABLE campanias_clientes (
  id_campania INT NOT NULL,
  id_cliente INT NOT NULL,
  canal VARCHAR(50),
  resultado VARCHAR(15),
  fecha_contacto DATE NOT NULL DEFAULT (CURRENT_DATE),
  is_deleted TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by VARCHAR(100),
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  updated_by VARCHAR(100),
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  deleted_by VARCHAR(100),
  PRIMARY KEY (id_campania, id_cliente, fecha_contacto),
  FOREIGN KEY (id_campania) REFERENCES campanias_promocionales(id_campania) ON DELETE CASCADE,
  FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
  INDEX idx_cc_camp_cli (id_campania, id_cliente),
  INDEX idx_cc_fecha (fecha_contacto),
  INDEX idx_cc_isdel (is_deleted),
  CHECK (resultado IN ('Convirtio','No') OR resultado IS NULL)
);

-- Auditoría auxiliar (histórico de tasas)
CREATE TABLE auditoria_tasas (
  id_aud BIGINT AUTO_INCREMENT PRIMARY KEY,
  id_historico INT,
  id_producto INT,
  tasa DECIMAL(7,3),
  vigente_desde DATE,
  vigente_hasta DATE,
  operacion VARCHAR(10) NOT NULL,
  audit_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CHECK (operacion IN ('INSERT','UPDATE'))
);

-- =====================================================
-- 2.b) AUDITORÍA CENTRALIZADA (tabla)
-- =====================================================
CREATE TABLE auditoria_eventos (
  id_audit      BIGINT AUTO_INCREMENT PRIMARY KEY,
  tabla         VARCHAR(64) NOT NULL,
  pk_nombre     VARCHAR(64) NOT NULL,
  pk_valor      VARCHAR(64) NOT NULL,
  operacion     VARCHAR(10) NOT NULL,
  usuario       VARCHAR(100) NULL,
  evento_ts     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  datos_antes   JSON NULL,
  datos_despues JSON NULL,
  CHECK (operacion IN ('INSERT','UPDATE','DELETE')),
  INDEX idx_aud_tabla_ts (tabla, evento_ts),
  INDEX idx_aud_pk (tabla, pk_nombre, pk_valor, evento_ts)
);

SET FOREIGN_KEY_CHECKS = 1;

-- =========================
-- 3) ÍNDICES ADICIONALES
-- =========================
CREATE INDEX idx_solicitud_producto_fecha
  ON solicitudes_credito(id_producto, fecha_solicitud, id_estado);

CREATE INDEX idx_credito_cliente_estado
  ON creditos(id_cliente, id_estado, fecha_inicio);

CREATE INDEX idx_cuota_estado_vencimiento
  ON cuotas(id_estado, fecha_vencimiento);

CREATE INDEX idx_empleado_sucursal_cargo
  ON empleados(id_sucursal, id_cargo, id_estado);

CREATE INDEX idx_cliente_provincia_estado
  ON clientes(provincia_norm, id_estado);

-- Extras con is_deleted
CREATE INDEX idx_pago_isdel_cuota
  ON pagos(id_cuota, is_deleted);

CREATE INDEX idx_cuota_isdel_credito
  ON cuotas(id_credito, is_deleted);

CREATE INDEX idx_sg_isdel_solicitud
  ON solicitudes_garantes(id_solicitud, is_deleted);

CREATE INDEX idx_hist_vigencia_ext
  ON historico_tasas(id_producto, vigente_desde, vigente_hasta);

-- =========================
-- 4) FUNCIONES & PROCEDURES
-- =========================
DELIMITER $$

CREATE FUNCTION fn_calcular_mora(monto DECIMAL(14,2), dias INT, tasa_diaria DECIMAL(7,5))
RETURNS DECIMAL(14,2)
DETERMINISTIC
BEGIN
  IF dias <= 0 OR monto <= 0 THEN RETURN 0.00; END IF;
  RETURN ROUND(monto * tasa_diaria * dias, 2);
END$$

CREATE FUNCTION fn_tasa_vigente(p_id_producto INT, p_fecha DATE)
RETURNS DECIMAL(7,3)
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE v_tasa DECIMAL(7,3);
  SELECT h.tasa_nueva INTO v_tasa
  FROM historico_tasas h
  WHERE h.is_deleted = 0
    AND h.id_producto = p_id_producto
    AND (
      (h.vigente_desde IS NOT NULL AND h.vigente_hasta IS NOT NULL AND p_fecha BETWEEN h.vigente_desde AND h.vigente_hasta)
      OR (h.vigente_desde IS NOT NULL AND h.vigente_hasta IS NULL AND p_fecha >= h.vigente_desde)
    )
  ORDER BY h.vigente_desde DESC
  LIMIT 1;

  IF v_tasa IS NULL THEN
    SELECT h.tasa_nueva INTO v_tasa
    FROM historico_tasas h
    WHERE h.is_deleted = 0
      AND h.id_producto = p_id_producto AND DATE(h.fecha_cambio) <= p_fecha
    ORDER BY h.fecha_cambio DESC LIMIT 1;
  END IF;
  RETURN COALESCE(v_tasa, 0.000);
END$$

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
  DECLARE v_id_estado_pend INT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Error generando cuotas';
  END;

  SELECT id INTO v_id_estado_pend FROM dom_estado_cuota WHERE codigo='Pendiente';

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

      INSERT INTO cuotas(
        id_credito, numero_cuota, fecha_vencimiento, monto_cuota,
        monto_capital, monto_interes, saldo_pendiente, id_estado
      )
      VALUES (
        p_id_credito, v_i, DATE_ADD(v_inicio, INTERVAL v_i MONTH), v_cuota,
        v_cap, v_int, v_saldo, v_id_estado_pend
      );
      SET v_i = v_i + 1;
    END WHILE;
  COMMIT;
END$$

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
  DECLARE v_id_aprob INT; DECLARE v_id_enrev INT; DECLARE v_id_pend INT;
  DECLARE v_id_credito_activo INT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN ROLLBACK; SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Error al aprobar solicitud'; END;

  SELECT id INTO v_id_aprob FROM dom_estado_solicitud WHERE codigo='Aprobada';
  SELECT id INTO v_id_enrev FROM dom_estado_solicitud WHERE codigo='En_Revision';
  SELECT id INTO v_id_pend  FROM dom_estado_solicitud WHERE codigo='Pendiente';
  SELECT id INTO v_id_credito_activo FROM dom_estado_credito WHERE codigo='Activo';

  START TRANSACTION;
    IF NOT EXISTS (
      SELECT 1 FROM solicitudes_credito
      WHERE id_solicitud=p_id_solicitud AND is_deleted=0 AND id_estado IN (v_id_pend, v_id_enrev)
    ) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Solicitud no válida o ya procesada';
    END IF;

    SELECT COUNT(*) INTO v_cnt_gar
    FROM solicitudes_garantes
    WHERE id_solicitud=p_id_solicitud AND is_deleted=0;
    IF v_cnt_gar < 1 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La solicitud no posee garantes vinculados';
    END IF;

    SELECT id_cliente, id_producto, plazo_meses
      INTO v_id_cliente, v_id_producto, v_plazo
    FROM solicitudes_credito WHERE id_solicitud=p_id_solicitud FOR UPDATE;

    SELECT monto_minimo, monto_maximo, plazo_minimo_meses, plazo_maximo_meses
      INTO v_min, v_max, v_pmin, v_pmax
    FROM productos_financieros WHERE id_producto=v_id_producto AND is_deleted=0 FOR UPDATE;

    IF p_monto_aprobado < v_min OR p_monto_aprobado > v_max THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Monto fuera de los límites del producto';
    END IF;
    IF v_plazo < v_pmin OR v_plazo > v_pmax THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Plazo fuera de los límites del producto';
    END IF;

    SELECT COUNT(*) INTO v_es_analista
    FROM empleados e
    JOIN dom_cargo_empleado c ON c.id=e.id_cargo AND c.codigo='Analista_Credito'
    WHERE e.id_empleado=p_id_analista AND e.is_deleted=0;
    IF v_es_analista = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El evaluador no tiene cargo Analista_Credito';
    END IF;

    IF p_tasa_anual IS NULL THEN
      SET p_tasa_anual = fn_tasa_vigente(v_id_producto, CURDATE());
    END IF;

    UPDATE solicitudes_credito
      SET id_estado=v_id_aprob,
          puntaje_riesgo=p_puntaje,
          id_analista=p_id_analista,
          fecha_evaluacion=NOW()
    WHERE id_solicitud=p_id_solicitud;

    SET v_fecha_inicio = CURDATE();
    SET v_fecha_fin = DATE_ADD(v_fecha_inicio, INTERVAL v_plazo MONTH);

    INSERT INTO creditos(
      id_solicitud,id_cliente,id_producto,monto_otorgado,tasa_interes,
      plazo_meses,fecha_inicio,fecha_finalizacion,id_estado
    )
    VALUES (
      p_id_solicitud, v_id_cliente, v_id_producto, p_monto_aprobado, p_tasa_anual,
      v_plazo, v_fecha_inicio, v_fecha_fin, v_id_credito_activo
    );

    SET v_id_credito = LAST_INSERT_ID();
    CALL sp_generar_cuotas(v_id_credito);
  COMMIT;

  SELECT v_id_credito AS id_credito_creado;
END$$

CREATE PROCEDURE sp_registrar_pago(
  IN p_id_cuota BIGINT,
  IN p_monto DECIMAL(14,2),
  IN p_id_metodo INT,
  IN p_nro_comp VARCHAR(50),
  IN p_fecha_pago DATETIME,
  IN p_tasa_mora_diaria DECIMAL(7,5)
)
BEGIN
  DECLARE v_venc DATE;
  DECLARE v_monto_cuota DECIMAL(14,2);
  DECLARE v_monto_pagado DECIMAL(14,2);
  DECLARE v_saldo_restante DECIMAL(14,2);
  DECLARE v_dias INT;
  DECLARE v_id_pagada INT; DECLARE v_id_pag_mora INT; DECLARE v_id_vencida INT; DECLARE v_id_pend INT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    SET @__allow_pago_insert := NULL;
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Error al registrar pago';
  END;

  SELECT id INTO v_id_pagada   FROM dom_estado_cuota WHERE codigo='Pagada';
  SELECT id INTO v_id_pag_mora FROM dom_estado_cuota WHERE codigo='Pagada_Con_Mora';
  SELECT id INTO v_id_vencida  FROM dom_estado_cuota WHERE codigo='Vencida';
  SELECT id INTO v_id_pend     FROM dom_estado_cuota WHERE codigo='Pendiente';

  START TRANSACTION;
    SELECT fecha_vencimiento, monto_cuota, monto_pagado
      INTO v_venc, v_monto_cuota, v_monto_pagado
    FROM cuotas WHERE id_cuota=p_id_cuota AND is_deleted=0 FOR UPDATE;

    SET v_saldo_restante = ROUND(v_monto_cuota - v_monto_pagado, 2);
    IF p_monto > v_saldo_restante THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El pago excede el saldo de la cuota';
    END IF;

    SET v_dias = GREATEST(0, DATEDIFF(DATE(COALESCE(p_fecha_pago, NOW())), v_venc));

    SET @__allow_pago_insert := 1;
    INSERT INTO pagos(id_cuota, fecha_pago, monto_pagado, id_metodo, dias_demora, numero_comprobante)
    VALUES (p_id_cuota, COALESCE(p_fecha_pago, NOW()), p_monto, p_id_metodo, v_dias, p_nro_comp);
    SET @__allow_pago_insert := NULL;

    UPDATE cuotas
      SET monto_pagado = monto_pagado + p_monto
    WHERE id_cuota = p_id_cuota;

    UPDATE cuotas
      SET saldo_pendiente = GREATEST(0, ROUND(monto_cuota - monto_pagado, 2))
    WHERE id_cuota = p_id_cuota;

    UPDATE cuotas
      SET id_estado = CASE
        WHEN monto_pagado >= monto_cuota AND v_dias>0 THEN v_id_pag_mora
        WHEN monto_pagado >= monto_cuota THEN v_id_pagada
        WHEN DATE(COALESCE(p_fecha_pago, NOW())) > fecha_vencimiento THEN v_id_vencida
        ELSE v_id_pend
      END
    WHERE id_cuota=p_id_cuota;

    UPDATE creditos c
    JOIN (
      SELECT id_credito,
             SUM(id_estado IN (v_id_pagada, v_id_pag_mora)) pagadas,
             SUM(id_estado = v_id_vencida) vencidas,
             COUNT(*) total
      FROM cuotas WHERE id_credito = (SELECT id_credito FROM cuotas WHERE id_cuota=p_id_cuota) AND is_deleted=0
      GROUP BY id_credito
    ) x ON x.id_credito = c.id_credito
    JOIN dom_estado_credito ec_act ON ec_act.codigo='Activo'
    JOIN dom_estado_credito ec_mor ON ec_mor.codigo='En_Mora'
    JOIN dom_estado_credito ec_pag ON ec_pag.codigo='Pagado'
    SET c.id_estado = CASE
                        WHEN x.pagadas = x.total THEN ec_pag.id
                        WHEN x.vencidas > 0 THEN ec_mor.id
                        ELSE ec_act.id
                      END;
  COMMIT;
END$$

CREATE PROCEDURE sp_asignar_evaluacion(
  IN p_id_solicitud INT,
  IN p_id_analista INT,
  IN p_puntaje INT,
  IN p_decision VARCHAR(20),
  IN p_obs TEXT
)
BEGIN
  DECLARE v_decision VARCHAR(20);
  DECLARE v_id_aprob INT; DECLARE v_id_rech INT; DECLARE v_id_enrev INT;

  SET v_decision = UPPER(REPLACE(p_decision,' ',''));

  SELECT id INTO v_id_aprob FROM dom_estado_solicitud WHERE codigo='Aprobada';
  SELECT id INTO v_id_rech  FROM dom_estado_solicitud WHERE codigo='Rechazada';
  SELECT id INTO v_id_enrev FROM dom_estado_solicitud WHERE codigo='En_Revision';

  IF v_decision NOT IN ('APROBADA','RECHAZADA','EN_REVISION') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Decisión inválida (Aprobada|Rechazada|En_Revision)';
  END IF;

  UPDATE solicitudes_credito
    SET id_estado = CASE
                      WHEN v_decision='APROBADA'  THEN v_id_aprob
                      WHEN v_decision='RECHAZADA' THEN v_id_rech
                      ELSE v_id_enrev
                    END,
        puntaje_riesgo = p_puntaje,
        id_analista = p_id_analista,
        fecha_evaluacion = NOW(),
        observaciones = p_obs
  WHERE id_solicitud = p_id_solicitud AND is_deleted=0;
END$$

CREATE PROCEDURE sp_refinanciar_credito(
  IN p_id_credito_original INT,
  IN p_monto_nuevo DECIMAL(14,2),
  IN p_plazo_nuevo INT,
  IN p_tasa_nueva DECIMAL(7,3)
)
BEGIN
  DECLARE v_id_cliente INT; DECLARE v_id_producto INT; DECLARE v_id_solicitud INT;
  DECLARE v_id_nuevo_credito INT; DECLARE v_inicio DATE; DECLARE v_fin DATE;
  DECLARE v_id_act INT; DECLARE v_id_ref INT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN ROLLBACK; SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Error en refinanciación'; END;

  SELECT id INTO v_id_act FROM dom_estado_credito WHERE codigo='Activo';
  SELECT id INTO v_id_ref FROM dom_estado_credito WHERE codigo='Refinanciado';

  START TRANSACTION;
    IF NOT EXISTS (
      SELECT 1 FROM creditos WHERE id_credito=p_id_credito_original AND is_deleted=0 AND id_estado IN (v_id_act)
    ) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Crédito no válido para refinanciación';
    END IF;

    SELECT id_cliente, id_producto, id_solicitud
      INTO v_id_cliente, v_id_producto, v_id_solicitud
    FROM creditos WHERE id_credito=p_id_credito_original FOR UPDATE;

    UPDATE creditos SET id_estado=v_id_ref WHERE id_credito=p_id_credito_original;

    SET v_inicio = CURDATE();
    SET v_fin = DATE_ADD(v_inicio, INTERVAL p_plazo_nuevo MONTH);

    INSERT INTO creditos(
      id_solicitud,id_cliente,id_producto,monto_otorgado,tasa_interes,
      plazo_meses,fecha_inicio,fecha_finalizacion,id_credito_refinanciado,id_estado
    )
    VALUES (v_id_solicitud, v_id_cliente, v_id_producto, p_monto_nuevo, p_tasa_nueva,
            p_plazo_nuevo, v_inicio, v_fin, p_id_credito_original, v_id_act);

    SET v_id_nuevo_credito = LAST_INSERT_ID();
    CALL sp_generar_cuotas(v_id_nuevo_credito);
  COMMIT;

  SELECT v_id_nuevo_credito AS id_credito_refinanciado;
END$$

DELIMITER ;

-- =========================
-- 5) TRIGGERS (auditoría + blindaje)
-- =========================
DELIMITER $$

-- Limpieza por rerun (drops)
DROP TRIGGER IF EXISTS trg_clientes_bi $$
DROP TRIGGER IF EXISTS trg_clientes_bu $$
DROP TRIGGER IF EXISTS trg_pago_calcular_demora $$
DROP TRIGGER IF EXISTS trg_pagos_ai_penalizacion $$
DROP TRIGGER IF EXISTS trg_cuota_actualiza_credito $$
DROP TRIGGER IF EXISTS trg_penalizacion_marcar_pagada $$
DROP TRIGGER IF EXISTS trg_generico_bi_prov $$
DROP TRIGGER IF EXISTS trg_generico_bu_prov $$
DROP TRIGGER IF EXISTS trg_generico_bi_ciudad $$
DROP TRIGGER IF EXISTS trg_generico_bu_ciudad $$
DROP TRIGGER IF EXISTS trg_generico_bi_suc $$
DROP TRIGGER IF EXISTS trg_generico_bu_suc $$
DROP TRIGGER IF EXISTS trg_generico_bi_emp $$
DROP TRIGGER IF EXISTS trg_generico_bu_emp $$
DROP TRIGGER IF EXISTS trg_generico_bi_camp $$
DROP TRIGGER IF EXISTS trg_generico_bu_camp $$
DROP TRIGGER IF EXISTS trg_generico_bi_pf $$
DROP TRIGGER IF EXISTS trg_generico_bu_pf $$
DROP TRIGGER IF EXISTS trg_generico_bi_hist $$
DROP TRIGGER IF EXISTS trg_generico_bu_hist $$
DROP TRIGGER IF EXISTS trg_generico_bi_gar $$
DROP TRIGGER IF EXISTS trg_generico_bu_gar $$
DROP TRIGGER IF EXISTS trg_generico_bi_sol $$
DROP TRIGGER IF EXISTS trg_generico_bu_sol $$
DROP TRIGGER IF EXISTS trg_generico_bi_sg $$
DROP TRIGGER IF EXISTS trg_generico_bu_sg $$
DROP TRIGGER IF EXISTS trg_generico_bi_cre $$
DROP TRIGGER IF EXISTS trg_generico_bu_cre $$
DROP TRIGGER IF EXISTS trg_generico_bi_pen $$
DROP TRIGGER IF EXISTS trg_generico_bu_pen $$
DROP TRIGGER IF EXISTS trg_generico_bi_eval $$
DROP TRIGGER IF EXISTS trg_generico_bu_eval $$
DROP TRIGGER IF EXISTS aud_clientes_ins $$
DROP TRIGGER IF EXISTS aud_clientes_upd $$
DROP TRIGGER IF EXISTS aud_clientes_del $$
DROP TRIGGER IF EXISTS aud_pagos_ins $$
DROP TRIGGER IF EXISTS aud_pagos_upd $$
DROP TRIGGER IF EXISTS aud_pagos_del $$
DROP TRIGGER IF EXISTS aud_creditos_ins $$
DROP TRIGGER IF EXISTS aud_creditos_upd $$
DROP TRIGGER IF EXISTS aud_creditos_del $$
DROP TRIGGER IF EXISTS trg_sol_no_aprobar_sin_garante $$
DROP TRIGGER IF EXISTS trg_hist_no_solape $$

-- CLIENTES normaliza & metadatos
CREATE TRIGGER trg_clientes_bi BEFORE INSERT ON clientes
FOR EACH ROW
BEGIN
  SET NEW.provincia = TRIM(REPLACE(REPLACE(NEW.provincia,'  ',' '),'  ',' '));
  SET NEW.ciudad    = TRIM(REPLACE(REPLACE(NEW.ciudad,'  ',' '),'  ',' '));
  IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF;
END$$

CREATE TRIGGER trg_clientes_bu BEFORE UPDATE ON clientes
FOR EACH ROW
BEGIN
  SET NEW.provincia = TRIM(REPLACE(REPLACE(NEW.provincia,'  ',' '),'  ',' '));
  SET NEW.ciudad    = TRIM(REPLACE(REPLACE(NEW.ciudad,'  ',' '),'  ',' '));
  SET NEW.updated_by = CURRENT_USER();
  IF NEW.is_deleted = 1 AND OLD.is_deleted = 0 THEN
    SET NEW.deleted_at = CURRENT_TIMESTAMP;
    IF NEW.deleted_by IS NULL THEN SET NEW.deleted_by = CURRENT_USER(); END IF;
  END IF;
END$$

-- PAGOS guardia + demora
CREATE TRIGGER trg_pago_calcular_demora
BEFORE INSERT ON pagos
FOR EACH ROW
BEGIN
  DECLARE v_venc DATE;
  IF COALESCE(@__allow_pago_insert, 0) <> 1 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Inserción directa en pagos no permitida. Use sp_registrar_pago.';
  END IF;

  SELECT fecha_vencimiento INTO v_venc
  FROM cuotas WHERE id_cuota = NEW.id_cuota;

  SET NEW.dias_demora = GREATEST(0, DATEDIFF(DATE(COALESCE(NEW.fecha_pago, NOW())), v_venc));
  IF NEW.created_by IS NULL THEN
    SET NEW.created_by = CURRENT_USER();
  END IF;
END$$

CREATE TRIGGER trg_pagos_ai_penalizacion
AFTER INSERT ON pagos
FOR EACH ROW
BEGIN
  DECLARE v_venc DATE; DECLARE v_monto DECIMAL(14,2); DECLARE v_dias INT; DECLARE v_pen_pend INT;
  IF NEW.is_deleted = 0 THEN
    SELECT fecha_vencimiento, monto_cuota INTO v_venc, v_monto
    FROM cuotas WHERE id_cuota = NEW.id_cuota AND is_deleted=0;
    SET v_dias = GREATEST(0, DATEDIFF(DATE(NEW.fecha_pago), v_venc));
    SELECT id INTO v_pen_pend FROM dom_estado_penalizacion WHERE codigo='Pendiente';
    IF v_dias > 0 THEN
      INSERT INTO penalizaciones(id_cuota, dias_mora, monto_penalizacion, tasa_mora, id_estado)
      VALUES (NEW.id_cuota, v_dias, fn_calcular_mora(v_monto, v_dias, 0.0005), 0.0005, v_pen_pend);
    END IF;
  END IF;
END$$

CREATE TRIGGER trg_cuota_actualiza_credito AFTER UPDATE ON cuotas
FOR EACH ROW
BEGIN
  DECLARE v_id_credito INT;
  DECLARE v_id_pagada INT; DECLARE v_id_pag_mora INT; DECLARE v_id_vencida INT;
  DECLARE v_id_cre_act INT; DECLARE v_id_cre_mor INT; DECLARE v_id_cre_pag INT;

  SELECT id INTO v_id_pagada   FROM dom_estado_cuota WHERE codigo='Pagada';
  SELECT id INTO v_id_pag_mora FROM dom_estado_cuota WHERE codigo='Pagada_Con_Mora';
  SELECT id INTO v_id_vencida  FROM dom_estado_cuota WHERE codigo='Vencida';

  SELECT id INTO v_id_cre_act FROM dom_estado_credito WHERE codigo='Activo';
  SELECT id INTO v_id_cre_mor FROM dom_estado_credito WHERE codigo='En_Mora';
  SELECT id INTO v_id_cre_pag FROM dom_estado_credito WHERE codigo='Pagado';

  SET v_id_credito = NEW.id_credito;

  UPDATE creditos c
  JOIN (
    SELECT id_credito,
           SUM(id_estado IN (v_id_pagada, v_id_pag_mora)) pagadas,
           SUM(id_estado = v_id_vencida) vencidas,
           COUNT(*) total
    FROM cuotas WHERE id_credito=v_id_credito AND is_deleted=0
    GROUP BY id_credito
  ) x ON x.id_credito = c.id_credito
  SET c.id_estado = CASE
                      WHEN x.pagadas = x.total THEN v_id_cre_pag
                      WHEN x.vencidas > 0 THEN v_id_cre_mor
                      ELSE v_id_cre_act
                    END
  WHERE c.id_credito = v_id_credito;
END$$

CREATE TRIGGER trg_penalizacion_marcar_pagada
AFTER UPDATE ON cuotas
FOR EACH ROW
BEGIN
  DECLARE v_id_pagada   INT;
  DECLARE v_id_pag_mora INT;
  DECLARE v_id_pen_pag  INT;

  SELECT id INTO v_id_pagada   FROM dom_estado_cuota        WHERE codigo='Pagada';
  SELECT id INTO v_id_pag_mora FROM dom_estado_cuota        WHERE codigo='Pagada_Con_Mora';
  SELECT id INTO v_id_pen_pag  FROM dom_estado_penalizacion WHERE codigo='Pagada';

  IF NEW.id_estado IN (v_id_pagada, v_id_pag_mora) THEN
    UPDATE penalizaciones
    SET id_estado = v_id_pen_pag, updated_at = NOW(), updated_by = CURRENT_USER()
    WHERE id_cuota = NEW.id_cuota AND is_deleted = 0;
  END IF;
END$$

-- Triggers genéricos metadatos (incluye provincias/ciudades)
CREATE TRIGGER trg_generico_bi_prov BEFORE INSERT ON provincias
FOR EACH ROW BEGIN IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF; END$$
CREATE TRIGGER trg_generico_bu_prov BEFORE UPDATE ON provincias
FOR EACH ROW BEGIN SET NEW.updated_by = CURRENT_USER(); IF NEW.is_deleted=1 AND OLD.is_deleted=0 THEN SET NEW.deleted_at=NOW(); IF NEW.deleted_by IS NULL THEN SET NEW.deleted_by=CURRENT_USER(); END IF; END IF; END$$

CREATE TRIGGER trg_generico_bi_ciudad BEFORE INSERT ON ciudades
FOR EACH ROW BEGIN IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF; END$$
CREATE TRIGGER trg_generico_bu_ciudad BEFORE UPDATE ON ciudades
FOR EACH ROW BEGIN SET NEW.updated_by = CURRENT_USER(); IF NEW.is_deleted=1 AND OLD.is_deleted=0 THEN SET NEW.deleted_at=NOW(); IF NEW.deleted_by IS NULL THEN SET NEW.deleted_by=CURRENT_USER(); END IF; END IF; END$$

CREATE TRIGGER trg_generico_bi_suc BEFORE INSERT ON sucursales
FOR EACH ROW BEGIN IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF; END$$
CREATE TRIGGER trg_generico_bu_suc BEFORE UPDATE ON sucursales
FOR EACH ROW BEGIN SET NEW.updated_by = CURRENT_USER(); IF NEW.is_deleted=1 AND OLD.is_deleted=0 THEN SET NEW.deleted_at=NOW(); IF NEW.deleted_by IS NULL THEN SET NEW.deleted_by=CURRENT_USER(); END IF; END IF; END$$

CREATE TRIGGER trg_generico_bi_emp BEFORE INSERT ON empleados
FOR EACH ROW BEGIN IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF; END$$
CREATE TRIGGER trg_generico_bu_emp BEFORE UPDATE ON empleados
FOR EACH ROW BEGIN SET NEW.updated_by = CURRENT_USER(); IF NEW.is_deleted=1 AND OLD.is_deleted=0 THEN SET NEW.deleted_at=NOW(); IF NEW.deleted_by IS NULL THEN SET NEW.deleted_by=CURRENT_USER(); END IF; END IF; END$$

CREATE TRIGGER trg_generico_bi_camp BEFORE INSERT ON campanias_promocionales
FOR EACH ROW BEGIN IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF; END$$
CREATE TRIGGER trg_generico_bu_camp BEFORE UPDATE ON campanias_promocionales
FOR EACH ROW BEGIN SET NEW.updated_by = CURRENT_USER(); IF NEW.is_deleted=1 AND OLD.is_deleted=0 THEN SET NEW.deleted_at=NOW(); IF NEW.deleted_by IS NULL THEN SET NEW.deleted_by=CURRENT_USER(); END IF; END IF; END$$

CREATE TRIGGER trg_generico_bi_pf BEFORE INSERT ON productos_financieros
FOR EACH ROW BEGIN IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF; END$$
CREATE TRIGGER trg_generico_bu_pf BEFORE UPDATE ON productos_financieros
FOR EACH ROW BEGIN SET NEW.updated_by = CURRENT_USER(); IF NEW.is_deleted=1 AND OLD.is_deleted=0 THEN SET NEW.deleted_at=NOW(); IF NEW.deleted_by IS NULL THEN SET NEW.deleted_by=CURRENT_USER(); END IF; END IF; END$$

CREATE TRIGGER trg_generico_bi_hist BEFORE INSERT ON historico_tasas
FOR EACH ROW BEGIN IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF; END$$
CREATE TRIGGER trg_generico_bu_hist BEFORE UPDATE ON historico_tasas
FOR EACH ROW BEGIN SET NEW.updated_by = CURRENT_USER(); IF NEW.is_deleted=1 AND OLD.is_deleted=0 THEN SET NEW.deleted_at=NOW(); IF NEW.deleted_by IS NULL THEN SET NEW.deleted_by=CURRENT_USER(); END IF; END IF; END$$

CREATE TRIGGER trg_generico_bi_gar BEFORE INSERT ON garantes
FOR EACH ROW BEGIN IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF; END$$
CREATE TRIGGER trg_generico_bu_gar BEFORE UPDATE ON garantes
FOR EACH ROW BEGIN SET NEW.updated_by = CURRENT_USER(); IF NEW.is_deleted=1 AND OLD.is_deleted=0 THEN SET NEW.deleted_at=NOW(); IF NEW.deleted_by IS NULL THEN SET NEW.deleted_by=CURRENT_USER(); END IF; END IF; END$$

CREATE TRIGGER trg_generico_bi_sol BEFORE INSERT ON solicitudes_credito
FOR EACH ROW BEGIN IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF; END$$
CREATE TRIGGER trg_generico_bu_sol BEFORE UPDATE ON solicitudes_credito
FOR EACH ROW BEGIN SET NEW.updated_by = CURRENT_USER(); IF NEW.is_deleted=1 AND OLD.is_deleted=0 THEN SET NEW.deleted_at=NOW(); IF NEW.deleted_by IS NULL THEN SET NEW.deleted_by=CURRENT_USER(); END IF; END IF; END$$

CREATE TRIGGER trg_generico_bi_sg BEFORE INSERT ON solicitudes_garantes
FOR EACH ROW BEGIN IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF; END$$
CREATE TRIGGER trg_generico_bu_sg BEFORE UPDATE ON solicitudes_garantes
FOR EACH ROW BEGIN SET NEW.updated_by = CURRENT_USER(); IF NEW.is_deleted=1 AND OLD.is_deleted=0 THEN SET NEW.deleted_at=NOW(); IF NEW.deleted_by IS NULL THEN SET NEW.deleted_by=CURRENT_USER(); END IF; END IF; END$$

CREATE TRIGGER trg_generico_bi_cre BEFORE INSERT ON creditos
FOR EACH ROW BEGIN IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF; END$$
CREATE TRIGGER trg_generico_bu_cre BEFORE UPDATE ON creditos
FOR EACH ROW BEGIN SET NEW.updated_by = CURRENT_USER(); IF NEW.is_deleted=1 AND OLD.is_deleted=0 THEN SET NEW.deleted_at=NOW(); IF NEW.deleted_by IS NULL THEN SET NEW.deleted_by=CURRENT_USER(); END IF; END IF; END$$

CREATE TRIGGER trg_generico_bi_pen BEFORE INSERT ON penalizaciones
FOR EACH ROW BEGIN IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF; END$$
CREATE TRIGGER trg_generico_bu_pen BEFORE UPDATE ON penalizaciones
FOR EACH ROW BEGIN SET NEW.updated_by = CURRENT_USER(); IF NEW.is_deleted=1 AND OLD.is_deleted=0 THEN SET NEW.deleted_at=NOW(); IF NEW.deleted_by IS NULL THEN SET NEW.deleted_by=CURRENT_USER(); END IF; END IF; END$$

CREATE TRIGGER trg_generico_bi_eval BEFORE INSERT ON evaluaciones_seguimiento
FOR EACH ROW BEGIN IF NEW.created_by IS NULL THEN SET NEW.created_by = CURRENT_USER(); END IF; END$$
CREATE TRIGGER trg_generico_bu_eval BEFORE UPDATE ON evaluaciones_seguimiento
FOR EACH ROW BEGIN SET NEW.updated_by = CURRENT_USER(); IF NEW.is_deleted=1 AND OLD.is_deleted=0 THEN SET NEW.deleted_at=NOW(); IF NEW.deleted_by IS NULL THEN SET NEW.deleted_by=CURRENT_USER(); END IF; END IF; END$$

-- Anti-aprobación sin garantes
CREATE TRIGGER trg_sol_no_aprobar_sin_garante
BEFORE UPDATE ON solicitudes_credito
FOR EACH ROW
BEGIN
  DECLARE v_id_aprob INT; DECLARE v_cnt INT;
  SELECT id INTO v_id_aprob FROM dom_estado_solicitud WHERE codigo='Aprobada';
  IF NEW.id_estado = v_id_aprob AND OLD.id_estado <> v_id_aprob THEN
    SELECT COUNT(*) INTO v_cnt
    FROM solicitudes_garantes
    WHERE id_solicitud = OLD.id_solicitud AND is_deleted=0;
    IF v_cnt < 1 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='No se puede aprobar una solicitud sin garantes';
    END IF;
  END IF;
END$$

-- Anti-solape en historico_tasas
CREATE TRIGGER trg_hist_no_solape
BEFORE INSERT ON historico_tasas
FOR EACH ROW
BEGIN
  IF NEW.vigente_desde IS NOT NULL THEN
    IF EXISTS (
      SELECT 1 FROM historico_tasas h
      WHERE h.id_producto = NEW.id_producto
        AND h.is_deleted=0
        AND (
          (h.vigente_desde IS NULL AND h.vigente_hasta IS NULL) OR
          (NEW.vigente_hasta IS NULL AND (h.vigente_hasta IS NULL OR h.vigente_hasta >= NEW.vigente_desde)) OR
          (NEW.vigente_hasta IS NOT NULL AND h.vigente_desde IS NOT NULL AND h.vigente_hasta IS NOT NULL
             AND NOT (NEW.vigente_hasta < h.vigente_desde OR NEW.vigente_desde > h.vigente_hasta))
        )
    ) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Rango de vigencia de tasa solapado';
    END IF;
  END IF;
END$$

DELIMITER ;

-- =========================
-- 5.b) TRIGGERS DE AUDITORÍA CENTRALIZADA
-- =========================
DELIMITER $$

DROP TRIGGER IF EXISTS aud_clientes_ins $$
DROP TRIGGER IF EXISTS aud_clientes_upd $$
DROP TRIGGER IF EXISTS aud_clientes_del $$
DROP TRIGGER IF EXISTS aud_pagos_ins $$
DROP TRIGGER IF EXISTS aud_pagos_upd $$
DROP TRIGGER IF EXISTS aud_pagos_del $$
DROP TRIGGER IF EXISTS aud_creditos_ins $$
DROP TRIGGER IF EXISTS aud_creditos_upd $$
DROP TRIGGER IF EXISTS aud_creditos_del $$

CREATE TRIGGER aud_clientes_ins
AFTER INSERT ON clientes
FOR EACH ROW
BEGIN
  INSERT INTO auditoria_eventos(tabla, pk_nombre, pk_valor, operacion, usuario, datos_despues)
  VALUES ('clientes','id_cliente', NEW.id_cliente, 'INSERT', CURRENT_USER(),
          JSON_OBJECT('id_cliente', NEW.id_cliente,'nombre', NEW.nombre,'apellido', NEW.apellido,'dni', NEW.dni,'id_estado', NEW.id_estado,'created_at', NEW.created_at));
END$$

CREATE TRIGGER aud_clientes_upd
AFTER UPDATE ON clientes
FOR EACH ROW
BEGIN
  INSERT INTO auditoria_eventos(tabla, pk_nombre, pk_valor, operacion, usuario, datos_antes, datos_despues)
  VALUES ('clientes','id_cliente', NEW.id_cliente, 'UPDATE', CURRENT_USER(),
          JSON_OBJECT('nombre', OLD.nombre,'apellido', OLD.apellido,'dni', OLD.dni,'id_estado', OLD.id_estado),
          JSON_OBJECT('nombre', NEW.nombre,'apellido', NEW.apellido,'dni', NEW.dni,'id_estado', NEW.id_estado));
END$$

CREATE TRIGGER aud_clientes_del
AFTER DELETE ON clientes
FOR EACH ROW
BEGIN
  INSERT INTO auditoria_eventos(tabla, pk_nombre, pk_valor, operacion, usuario, datos_antes)
  VALUES ('clientes','id_cliente', OLD.id_cliente, 'DELETE', CURRENT_USER(),
          JSON_OBJECT('nombre', OLD.nombre,'apellido', OLD.apellido,'dni', OLD.dni,'id_estado', OLD.id_estado));
END$$

CREATE TRIGGER aud_pagos_ins
AFTER INSERT ON pagos
FOR EACH ROW
BEGIN
  INSERT INTO auditoria_eventos(tabla, pk_nombre, pk_valor, operacion, usuario, datos_despues)
  VALUES ('pagos','id_pago', NEW.id_pago, 'INSERT', CURRENT_USER(),
          JSON_OBJECT('id_pago', NEW.id_pago,'id_cuota', NEW.id_cuota,'monto_pagado', NEW.monto_pagado,'id_metodo', NEW.id_metodo,'dias_demora', NEW.dias_demora,'numero_comprobante', NEW.numero_comprobante));
END$$

CREATE TRIGGER aud_pagos_upd
AFTER UPDATE ON pagos
FOR EACH ROW
BEGIN
  INSERT INTO auditoria_eventos(tabla, pk_nombre, pk_valor, operacion, usuario, datos_antes, datos_despues)
  VALUES ('pagos','id_pago', NEW.id_pago, 'UPDATE', CURRENT_USER(),
          JSON_OBJECT('monto_pagado', OLD.monto_pagado,'id_metodo', OLD.id_metodo,'dias_demora', OLD.dias_demora),
          JSON_OBJECT('monto_pagado', NEW.monto_pagado,'id_metodo', NEW.id_metodo,'dias_demora', NEW.dias_demora));
END$$

CREATE TRIGGER aud_pagos_del
AFTER DELETE ON pagos
FOR EACH ROW
BEGIN
  INSERT INTO auditoria_eventos(tabla, pk_nombre, pk_valor, operacion, usuario, datos_antes)
  VALUES ('pagos','id_pago', OLD.id_pago, 'DELETE', CURRENT_USER(),
          JSON_OBJECT('id_cuota', OLD.id_cuota,'monto_pagado', OLD.monto_pagado,'id_metodo', OLD.id_metodo));
END$$

CREATE TRIGGER aud_creditos_ins
AFTER INSERT ON creditos
FOR EACH ROW
BEGIN
  INSERT INTO auditoria_eventos(tabla, pk_nombre, pk_valor, operacion, usuario, datos_despues)
  VALUES ('creditos','id_credito', NEW.id_credito, 'INSERT', CURRENT_USER(),
          JSON_OBJECT('id_cliente', NEW.id_cliente,'id_producto', NEW.id_producto,'monto_otorgado', NEW.monto_otorgado,'tasa_interes', NEW.tasa_interes,'plazo_meses', NEW.plazo_meses,'id_estado', NEW.id_estado));
END$$

CREATE TRIGGER aud_creditos_upd
AFTER UPDATE ON creditos
FOR EACH ROW
BEGIN
  INSERT INTO auditoria_eventos(tabla, pk_nombre, pk_valor, operacion, usuario, datos_antes, datos_despues)
  VALUES ('creditos','id_credito', NEW.id_credito, 'UPDATE', CURRENT_USER(),
          JSON_OBJECT('monto_otorgado', OLD.monto_otorgado,'tasa_interes', OLD.tasa_interes,'plazo_meses', OLD.plazo_meses,'id_estado', OLD.id_estado),
          JSON_OBJECT('monto_otorgado', NEW.monto_otorgado,'tasa_interes', NEW.tasa_interes,'plazo_meses', NEW.plazo_meses,'id_estado', NEW.id_estado));
END$$

CREATE TRIGGER aud_creditos_del
AFTER DELETE ON creditos
FOR EACH ROW
BEGIN
  INSERT INTO auditoria_eventos(tabla, pk_nombre, pk_valor, operacion, usuario, datos_antes)
  VALUES ('creditos','id_credito', OLD.id_credito, 'DELETE', CURRENT_USER(),
          JSON_OBJECT('id_cliente', OLD.id_cliente,'id_producto', OLD.id_producto,'monto_otorgado', OLD.monto_otorgado,'id_estado', OLD.id_estado));
END$$

DELIMITER ;

-- =========================
-- 6) Backfill de vigencias (por si entran filas sin vigencia)
-- =========================
SET @old_sql_safe_updates := @@SQL_SAFE_UPDATES;
SET SQL_SAFE_UPDATES = 0;

WITH ord AS (
  SELECT
    id_historico,
    id_producto,
    DATE(fecha_cambio) AS d_desde,
    LEAD(DATE(fecha_cambio)) OVER (PARTITION BY id_producto ORDER BY fecha_cambio) AS prox
  FROM historico_tasas
  WHERE is_deleted = 0
)
UPDATE historico_tasas AS h
JOIN ord AS o  ON o.id_historico = h.id_historico
SET
  h.vigente_desde = COALESCE(h.vigente_desde, o.d_desde),
  h.vigente_hasta = COALESCE(
    h.vigente_hasta,
    CASE WHEN o.prox IS NULL THEN NULL ELSE DATE_SUB(o.prox, INTERVAL 1 DAY) END
  )
WHERE (h.vigente_desde IS NULL OR h.vigente_hasta IS NULL)
  AND h.is_deleted = 0;

SET SQL_SAFE_UPDATES = @old_sql_safe_updates;

-- =========================
-- 7) USUARIOS Y PERMISOS (mínimo 3)
-- =========================
CREATE USER IF NOT EXISTS 'admin_creditos'@'localhost' IDENTIFIED BY 'Admin2024$Secure';
GRANT ALL PRIVILEGES ON gestion_creditos.* TO 'admin_creditos'@'localhost';
GRANT CREATE USER ON *.* TO 'admin_creditos'@'localhost';

CREATE USER IF NOT EXISTS 'analista_credito'@'localhost' IDENTIFIED BY 'Analista2024$Pass';
GRANT SELECT ON gestion_creditos.* TO 'analista_credito'@'localhost';
GRANT UPDATE (puntaje_riesgo, id_analista, id_estado, fecha_evaluacion, observaciones)
  ON gestion_creditos.solicitudes_credito TO 'analista_credito'@'localhost';
GRANT EXECUTE ON PROCEDURE gestion_creditos.sp_aprobar_solicitud   TO 'analista_credito'@'localhost';
GRANT EXECUTE ON PROCEDURE gestion_creditos.sp_refinanciar_credito TO 'analista_credito'@'localhost';
GRANT EXECUTE ON PROCEDURE gestion_creditos.sp_asignar_evaluacion  TO 'analista_credito'@'localhost';

CREATE USER IF NOT EXISTS 'gestor_cobranza'@'localhost' IDENTIFIED BY 'Cobranza2024$Key';
GRANT SELECT ON gestion_creditos.clientes TO 'gestor_cobranza'@'localhost';
GRANT SELECT ON gestion_creditos.creditos TO 'gestor_cobranza'@'localhost';
GRANT SELECT, UPDATE ON gestion_creditos.cuotas TO 'gestor_cobranza'@'localhost';
GRANT SELECT, INSERT ON gestion_creditos.pagos TO 'gestor_cobranza'@'localhost';
GRANT SELECT, INSERT ON gestion_creditos.penalizaciones TO 'gestor_cobranza'@'localhost';
GRANT EXECUTE ON PROCEDURE gestion_creditos.sp_registrar_pago TO 'gestor_cobranza'@'localhost';

FLUSH PRIVILEGES;
SET sql_notes = 1;
