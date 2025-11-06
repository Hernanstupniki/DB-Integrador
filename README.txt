# Gestión de Créditos y Cobranzas – MySQL 8 ⚙️💳

![MySQL](https://img.shields.io/badge/MySQL-8.x-00758F?logo=mysql\&logoColor=white)
![Estado](https://img.shields.io/badge/Estado-Listo%20para%20entregar-brightgreen)
![Licencia](https://img.shields.io/badge/Uso-Académico-blue)

Repositorio con el **script SQL completo** para un **Sistema de Gestión de Créditos y Cobranzas**. Cumple todas las consignas académicas: **tablas normalizadas**, **índices**, **triggers**, **SP/funciones**, **usuarios** y **permisos**; más un **seed masivo** para pruebas.

---

## 📚 Tabla de contenidos

* [¿Qué resuelve?](#-qué-resuelve)
* [Modelo de datos](#-modelo-de-datos)
* [Índices](#-índices)
* [Triggers](#-triggers)
* [Procedimientos y funciones](#-procedimientos-y-funciones)
* [Usuarios y permisos](#-usuarios-y-permisos)
* [Ejecución](#️-ejecución)
* [Pruebas rápidas](#-pruebas-rápidas)
* [Seed masivo](#-seed-masivo)
* [Ajustes y troubleshooting](#-ajustes-y-troubleshooting)
* [Compatibilidad](#-compatibilidad)
* [Licencia](#-licencia)

---

## 🚀 ¿Qué resuelve?

Cubre el **ciclo completo de créditos**:

1. **Captación y solicitud** (cliente, producto, sucursal, gestor).
2. **Evaluación** (analista, puntaje, decisión).
3. **Otorgamiento** (tasa/plazo/fecha y estado del crédito).
4. **Amortización** (plan **francés** de cuotas).
5. **Cobro** (pagos, **mora** y **penalizaciones** automáticas).
6. **Seguimiento** (evaluaciones periódicas).
7. **Marketing** (campañas y productos objetivo).
8. **Histórico de tasas** (políticas con **vigencia** + auditoría).

> **Reglas clave integradas**: aprobación exige garante; límites por producto; solo Analistas aprueban; estados de **cuotas** y **créditos** se actualizan automáticamente.

---

## 🧩 Modelo de datos

Tablas principales:

* **provincias**, **sucursales** (soporte geográfico/organizacional)
* **empleados** (roles: `Atencion_Cliente`, `Analista_Credito`, `Gerente`, `Cobranza`, `Administrador`)
* **clientes** (con normalización virtual `provincia_norm`, `ciudad_norm`)
* **productos_financieros**
* **historico_tasas** (vigencias; auditado)
* **garantes**, **solicitudes_credito**, **solicitudes_garantes**
* **creditos**, **cuotas**, **pagos**, **penalizaciones**
* **evaluaciones_seguimiento**
* **campanias_promocionales**, **campanias_productos**
* **auditoria_tasas**

**Reglas embebidas**:

* Aprobación **requiere garante**.
* Validación de **monto/plazo** contra el producto.
* Cambios de **estado** por triggers (cuotas/créditos).
* Auditoría de tasas.

---

## 🧲 Índices

> **≥5 índices** (con impacto indicado)

* `solicitudes_credito(id_producto, fecha_solicitud, estado)` → reportes por producto/mes/estado.
* `creditos(id_cliente, estado, fecha_inicio)` → panel cliente y **aging**.
* `cuotas(estado, fecha_vencimiento)` → cobranzas (vencidas/hoy/semana).
* `empleados(id_sucursal, cargo, estado)` → staffing por sucursal.
* `clientes(provincia_norm, estado)` → segmentación regional.

**Impacto**: ↓ latencia en consultas operativas y reportes.

---

## 🧨 Triggers

> **≥5 triggers** para automatización/auditoría

1. `trg_clientes_bi` · `trg_clientes_bu` → normalización de provincia/ciudad.
2. `trg_pago_calcular_demora` (BEFORE INSERT) → calcula **días_demora**.
3. `trg_pago_actualiza_cuota` (AFTER INSERT) → actualiza **estado de cuota**.
4. `trg_cuota_actualiza_credito` (AFTER UPDATE) → actualiza **estado de crédito**.
5. `trg_hist_insert` · `trg_hist_update` → **audita** tasas en `auditoria_tasas`.
6. `trg_cliente_campania` → incrementa **clientes_captados** en campañas.

---

## 🧮 Procedimientos y funciones

**Funciones**

* `fn_calcular_mora(monto, dias, tasa_diaria)` → penalización por mora (redondeada).
* `fn_tasa_vigente(id_producto, fecha)` → retorna tasa vigente por **rango de vigencia**.

**Procedimientos**

* `sp_generar_cuotas(id_credito)` → plan francés (transacción + control errores).
* `sp_aprobar_solicitud(id_solicitud, monto, tasa, id_analista, puntaje)` → valida reglas y crea crédito + cuotas.
* `sp_registrar_pago(id_cuota, monto, metodo, nro_comp, tasa_mora_diaria)` → inserta pago, genera **penalización** y refresca estados.
* `sp_asignar_evaluacion(id_solicitud, id_analista, puntaje, decision, obs)` → cambia estado solicitud.
* `sp_refinanciar_credito(id_credito_original, nuevo_monto, nuevo_plazo, nueva_tasa)` → orig. **Refinanciado** y crea nuevo crédito.

> Todos manejan **transacciones** y `SIGNAL SQLSTATE '45000'` en errores.

---

## 🔐 Usuarios y permisos (principio de menor privilegio)

* **`admin_creditos`** → administración total del esquema.
* **`analista_credito`** → `SELECT` global + `EXECUTE` de SP de análisis/aprobación + `UPDATE` columnas específicas en solicitudes.
* **`gestor_cobranza`** → lectura en clientes/créditos, `UPDATE` en cuotas, `INSERT` en pagos/penalizaciones, `EXECUTE` en `sp_registrar_pago`.

---

## ▶️️ Ejecución

```sql
-- 1) Esquema completo (DDL, índices, triggers, SP/funciones, usuarios)
SOURCE esquema_01.sql;

-- 2) Seed masivo (datos realistas)
SOURCE seed_02.sql;
```

Verificar motor (opcional):

```sql
SHOW VARIABLES LIKE 'default_storage_engine';
```

---

## 🧪 Pruebas rápidas

Tasa vigente:

```sql
SELECT fn_tasa_vigente(1, CURDATE());
```

Aprobar solicitud:

```sql
CALL sp_aprobar_solicitud(1, 300000, 72.000, 1, 720);
SELECT * FROM creditos WHERE id_solicitud=1;
SELECT * FROM cuotas WHERE id_credito = LAST_INSERT_ID();
```

Pago con mora (0.05% diario = 0.0005):

```sql
CALL sp_registrar_pago(<id_cuota>, 50000, 'Transferencia', 'CMP-0001', 0.0005);
```

Refinanciación:

```sql
CALL sp_refinanciar_credito(<id_credito_original>, 250000, 18, 74.000);
```

---

## 🧰 Seed masivo

**`seed_02.sql`** carga datos **grandes y coherentes** (≈60+ por tabla) y gatilla toda la lógica:

* Genera secuencias 1..5000 **sin CTE** (compatibilidad pura).
* Encadena **vigencias** en `historico_tasas`.
* Crea **créditos** solo para solicitudes **Aprobadas** (usa `fn_tasa_vigente`).
* Genera **cuotas** con `sp_generar_cuotas`.
* Simula **pagos** (al día, con mora, parciales) y crea **penalizaciones**.
* Evita errores típicos (PK compuesta, trigger 1442, fechas 2038) con:

  * **Permutación coprima** para N:M,
  * **Tablas temporales** en pagos,
  * **Clamp** de fechas a `2037-12-31`.

**Volúmenes orientativos**:

* provincias 60 · sucursales 80 · empleados 300
* clientes 500 · productos 60 · histórico tasas 180
* solicitudes 600 · garantes 300 · N:M ≥ 600
* cuotas: por SP · pagos/penalizaciones: automáticos
* evaluaciones 200 · campañas 60 · campañas_productos 180
* auditoría: completa

---

## 🛠️ Ajustes y troubleshooting

**Ajustes rápidos**

* Volúmenes → cambia `WHERE n <= ...` en cada bloque.
* Proporciones (aprobadas/rechazadas) → en `solicitudes_credito`.
* Mora diaria → parámetro de `sp_registrar_pago` (ej. `0.0005`).

**Snippets útiles**

```sql
-- ¿Solicitudes aprobadas sin crédito?
SELECT COUNT(*) falta
FROM solicitudes_credito s
LEFT JOIN creditos c ON c.id_solicitud = s.id_solicitud
WHERE s.estado='Aprobada' AND c.id_credito IS NULL;

-- Consistencia crédito ↔ cuotas
SELECT c.id_credito, c.estado, 
       SUM(cu.estado IN ('Pagada','Pagada_Con_Mora')) pagadas,
       SUM(cu.estado = 'Vencida') vencidas,
       COUNT(*) total
FROM creditos c
JOIN cuotas cu ON cu.id_credito=c.id_credito
GROUP BY c.id_credito, c.estado
LIMIT 10;
```

**GRANT por columnas**
Recordá listar **columnas** entre paréntesis en `GRANT`.
Reset rápido:

```sql
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'usuario'@'localhost';
FLUSH PRIVILEGES;
```

Ver grants:

```sql
SHOW GRANTS FOR 'analista_credito'@'localhost';
SHOW GRANTS FOR 'gestor_cobranza'@'localhost';
```

---

## 💻 Compatibilidad

* **MySQL 8.x** (InnoDB por defecto).
* Sin forzar `ENGINE` ni `CHARSET`; usa los del servidor.
* Columnas virtuales para búsquedas limpias (sin duplicar datos).

---

## 📄 Licencia

Uso **académico**. Hecho para prácticas, rendimiento y validación de reglas de negocio en sistemas de **Créditos y Cobranzas**.

---

### ✅ Checklist de entrega

* [x] Tablas con FKs y reglas
* [x] ≥ 5 índices (compuestos incluidos)
* [x] ≥ 5 triggers
* [x] ≥ 5 SP/funciones con manejo de errores
* [x] ≥ 3 usuarios con mínimo privilegio
* [x] Seed masivo reproducible
* [x] Snippets de verificación

> ¿Querés que te empaquete **`esquema_01.sql`** + **`seed_02.sql`** en un **ZIP** con orden de ejecución y un **ERD** (PNG)? Te lo preparo.
