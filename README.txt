# Gestión de Créditos y Cobranzas – MySQL 8

Repositorio con el **script SQL completo** para un **Sistema de Gestión de Créditos y Cobranzas**. Cumple con las consignas:

* **Tablas** normalizadas con **FK**, restricciones y reglas de negocio.
* **≥5 índices** (incluye compuestos) y notas de **impacto en performance**.
* **≥5 triggers** para automatización/auditoría.
* **≥5 procedimientos/funciones** con parámetros y **control de errores**.
* **≥3 usuarios** con **permisos mínimos necesarios** (principio de menor privilegio).

---

## 📦 ¿Qué resuelve?

Modela el ciclo completo:

1. **Captación y solicitud** (cliente, producto, sucursal, gestor).
2. **Evaluación crediticia** (analista, puntaje, decisión).
3. **Otorgamiento** (crédito activo con tasa/plazo).
4. **Amortización** (plan de **cuotas** sistema francés).
5. **Cobro** (pagos, cálculo de **mora** y **penalizaciones** automáticas).
6. **Seguimiento** (evaluaciones periódicas).
7. **Marketing** (campañas, productos objetivo, clientes captados).
8. **Histórico de tasas** (políticas con **vigencia** y auditoría).

---

## 🧩 Estructura (resumen de tablas)

* **provincias**, **sucursales**: Soporte geográfico y organización.
* **empleados**: Roles: `Atencion_Cliente`, `Analista_Credito`, `Gerente`, `Cobranza`, `Administrador`.
* **clientes**: Datos personales + normalización virtual (`provincia_norm`, `ciudad_norm`) para buscar sin ruido.
* **productos_financieros**: Límites, tasas base y requisitos por producto.
* **historico_tasas**: Histórico con **vigencias** (`vigente_desde/hasta`) y auditoría.
* **garantes**: Personas que respaldan solicitudes.
* **solicitudes_credito**: Origen de la operación; **debe** tener al menos un garante para aprobar.
* **solicitudes_garantes**: N:M entre solicitudes y garantes.
* **creditos**: Crédito otorgado (tasa/plazo/fecha/estado), vínculo a refinanciaciones.
* **cuotas**: Plan francés (monto, capital, interés, saldo, estado, pagos acumulados).
* **pagos**: Registros con **días de demora** y método.
* **penalizaciones**: Multas por mora (calculadas).
* **evaluaciones_seguimiento**: Monitoreo de riesgo/endeudamiento.
* **campanias_promocionales**, **campanias_productos**: Marketing y relación N:M.
* **auditoria_tasas**: Bitácora de cambios en histórico de tasas.

> Reglas clave embebidas:
>
> * **Aprobación exige garante** (validado en `sp_aprobar_solicitud`).
> * Validación de **límites** del producto (monto/plazo).
> * Solo **Analistas** pueden aprobar (`cargo='Analista_Credito'`).
> * Estados de **cuotas** y **créditos** se actualizan automáticamente por pagos.

---

## ⚙️ Índices (≥5) y su impacto

* `solicitudes_credito(id_producto, fecha_solicitud, estado)` → reportes por producto/mes/estado.
* `creditos(id_cliente, estado, fecha_inicio)` (compuesto) → panel del cliente y aging de cartera.
* `cuotas(estado, fecha_vencimiento)` → cobranzas (vencidas/hoy/semana).
* `empleados(id_sucursal, cargo, estado)` → staffing por sucursal.
* `clientes(provincia_norm, estado)` → segmentación regional.

**Impacto esperado**: ↓ latencia en consultas de gestión (backoffice y reportes), especialmente en listados por filtros típicos.

---

## 🧲 Triggers (≥5)

1. `trg_clientes_bi` / 2) `trg_clientes_bu` (BEFORE INSERT/UPDATE)

   * **Normaliza** provincia/ciudad para búsquedas limpias.

2. `trg_pago_calcular_demora` (BEFORE INSERT ON pagos)

   * Calcula **días de demora** antes de grabar.

3. `trg_pago_actualiza_cuota` (AFTER INSERT ON pagos)

   * Setea **estado** de la cuota: `Pagada`, `Pagada_Con_Mora`, `Vencida`, `Pendiente`.

4. `trg_cuota_actualiza_credito` (AFTER UPDATE ON cuotas)

   * Ajusta **estado del crédito**: `Pagado`, `En_Mora`, `Activo`.

5. `trg_hist_insert` / 7) `trg_hist_update` (AFTER INSERT/UPDATE ON historico_tasas)

   * **Auditoría** de tasas en `auditoria_tasas`.

6. `trg_cliente_campania` (AFTER INSERT ON clientes)

   * Suma contador de **clientes_captados** en campaña.

---

## 🧮 Procedimientos & Funciones (≥5)

### Funciones

* **`fn_calcular_mora(monto, dias, tasa_diaria)`**
  Retorna penalización simple por mora (redondeada).
* **`fn_tasa_vigente(id_producto, fecha)`**
  Busca **tasa vigente** a una fecha por **rango de vigencia** o último cambio previo.

### Procedimientos

* **`sp_generar_cuotas(id_credito)`**
  Crea plan **francés** completo (control de errores + transacción).
* **`sp_aprobar_solicitud(id_solicitud, monto, tasa, id_analista, puntaje)`**
  Valida **garantes**, **límites** del producto y **rol** del aprobador. Crea crédito + genera cuotas.
* **`sp_registrar_pago(id_cuota, monto, metodo, nro_comp, tasa_mora_diaria)`**
  Inserta pago, acumula pagado, crea **penalización** si corresponde y refresca estados de cuota/crédito.
* **`sp_asignar_evaluacion(id_solicitud, id_analista, puntaje, decision, obs)`**
  Cambia estado de solicitud (`Aprobada|Rechazada|En_Revision`) con datos de evaluación.
* **`sp_refinanciar_credito(id_credito_original, nuevo_monto, nuevo_plazo, nueva_tasa)`**
  Marca original como **Refinanciado**, crea **nuevo crédito** vinculado y genera cuotas.

> Todos los SP manejan **transacciones** y **SIGNAL** con `SQLSTATE '45000'` ante errores de negocio o SQL.

---

## 🔐 Usuarios y permisos (≥3)

* **`admin_creditos`**

  * `ALL PRIVILEGES` sobre el esquema + `CREATE USER`.
  * Uso: administración total.

* **`analista_credito`**

  * `SELECT` global.
  * `UPDATE` solo de **columnas** en `solicitudes_credito` (puntaje, analista, estado, fecha_evaluación, observaciones).
  * `EXECUTE` sobre `sp_aprobar_solicitud`, `sp_refinanciar_credito`, `sp_asignar_evaluacion`.
  * Uso: evaluación y aprobación con mínimo privilegio.

* **`gestor_cobranza`**

  * `SELECT` en `clientes`, `creditos`.
  * `SELECT, UPDATE` en `cuotas`.
  * `SELECT, INSERT` en `pagos`, `penalizaciones`.
  * `EXECUTE` en `sp_registrar_pago`.
  * Uso: cobranzas y gestión de mora.

> **Principio de menor privilegio**: cada rol solo puede ejecutar lo necesario para su función.

---

## ▶️ Cómo ejecutar

1. Abrí una consola MySQL o **phpMyAdmin**, y corré el **script completo** del repo.
2. Verificá motor por defecto (opcional):

   ```sql
   SHOW VARIABLES LIKE 'default_storage_engine';
   ```
3. (Opcional) **Seed** de prueba (clientes, empleado, producto, solicitud, garante) y flujo: aprobación → cuotas → pago → refinanciación.
   Tenés un bloque de **seed** en las issues/wikis del repo si querés data rápida.

---

## 🧪 Pruebas rápidas (snippets)

* **Tasa vigente** (si cargaste histórico con vigencias):

```sql
SELECT fn_tasa_vigente(1, CURDATE());
```

* **Aprobar solicitud** (requiere `solicitudes_garantes`):

```sql
CALL sp_aprobar_solicitud(1, 300000, 72.000, 1, 720);
SELECT * FROM creditos WHERE id_solicitud=1;
SELECT * FROM cuotas WHERE id_credito = LAST_INSERT_ID();
```

* **Registrar pago con mora** (0.05% diario = 0.0005):

```sql
CALL sp_registrar_pago(<id_cuota>, 50000, 'Transferencia', 'CMP-0001', 0.0005);
```

* **Refinanciar**:

```sql
CALL sp_refinanciar_credito(<id_credito_original>, 250000, 18, 74.000);
```

---

## 🛡️ Reglas de negocio implementadas

* La **aprobación** solo procede si:

  * La solicitud está `Pendiente`/`En_Revision`.
  * Tiene **≥1 garante**.
  * El **analista** tiene cargo `Analista_Credito`.
  * **Monto** y **plazo** dentro de límites del producto.
* Estados **automáticos**:

  * **Cuota**: `Pagada`, `Pagada_Con_Mora`, `Vencida`, `Pendiente`.
  * **Crédito**: `Pagado` cuando todas las cuotas pagadas; `En_Mora` si hay vencidas.
* **Auditoría** de tasas con vigencias y bitácora de cambios.

---

## 🧰 Compatibilidad y notas

* Probado en **MySQL 8.x**.
* El script **no fuerza** `ENGINE` ni `CHARACTER SET/COLLATE`; MySQL usa **InnoDB por defecto**.
* Las columnas **virtuales** (`provincia_norm`, `ciudad_norm`) ayudan a búsquedas consistentes sin duplicar datos.
* El bloque **backfill de vigencias** en `historico_tasas` solo actualiza si ya existen filas (mostraría “0 rows affected” si aún no hay datos).

---

## 🧪 Troubleshooting

* **GRANT por columnas**: asegurate de escribir **columnas** entre paréntesis, no el nombre de la tabla.
* Si un `GRANT` falló antes, podés limpiar y re-aplicar:

  ```sql
  REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'usuario'@'localhost';
  FLUSH PRIVILEGES;
  ```
* Ver **grants**:

  ```sql
  SHOW GRANTS FOR 'analista_credito'@'localhost';
  SHOW GRANTS FOR 'gestor_cobranza'@'localhost';
  ```

---
`seed_02.sql` (Datos masivos)

**Proyecto:** Sistema de Gestión de Créditos y Cobranzas
**Compatibilidad:** MySQL 8.x
**Relacionado con:** `esquema_01.sql` (DDL completo)

---

## ¿Qué hace este seed?

`seed_02.sql` carga **datos masivos y realistas** en todas las tablas del esquema creado por `esquema_01.sql`, cumpliendo el requisito de **≥ 60 registros por tabla** (en la mayoría, mucho más). Además, dispara y valida la **lógica de negocio** implementada por **índices**, **triggers**, **procedimientos** y **funciones** definidas en el esquema.

### Resumen de volúmenes (orientativo)

* `provincias`: 60
* `sucursales`: 80
* `empleados`: 300
* `campanias_promocionales`: 60
* `clientes`: 500
* `productos_financieros`: 60
* `historico_tasas`: 180 (3 por producto, con vigencias encadenadas)
* `garantes`: 300
* `solicitudes_credito`: 600
* `solicitudes_garantes`: ≥ 600 (1 o 2 garantes por solicitud)
* `creditos`: ≈ solicitudes **Aprobadas**
* `cuotas`: generadas por **SP** (plan francés) para *todos* los créditos
* `pagos`: múltiples casos (al día, con mora, parciales)
* `penalizaciones`: generadas automáticamente cuando hay mora
* `evaluaciones_seguimiento`: 200
* `campanias_productos`: 180
* `auditoria_tasas`: auditoría por triggers al insertar/actualizar histórico

---

## Dependencias y orden de ejecución

1. Ejecutar **`esquema_01.sql`** primero (crea BD, tablas, índices, funciones, procedimientos, triggers y usuarios).
2. Luego, ejecutar **`seed_02.sql`**.

> Si re-ejecutás el seed, él mismo limpia las tablas en orden seguro (respeta FKs) y vuelve a poblar todo.

---

## Cómo funciona internamente

### 1) Generación masiva y reproducible

* Crea una tabla auxiliar `helper_seq` con una **secuencia 1..5000 sin CTEs** (compatible y rápida).
* A partir de esa secuencia, genera datos **deterministas** y **consistentes** con `MOD`, offsets, y permutaciones coprimas para distribuir entidades (clientes ↔ sucursales ↔ empleados ↔ productos) evitando duplicados en claves compuestas.

### 2) Carga por tabla (y reglas de negocio)

* **Provincias / Sucursales / Empleados / Campañas / Clientes / Productos**:
  Datos sintéticos variados (fechas, montos, estados). En `clientes` se normalizan `provincia`/`ciudad` por los **triggers** `trg_clientes_bi` y `trg_clientes_bu` (trim/espacios), y se usan columnas virtuales `*_norm` para los índices de búsqueda.

* **Histórico de tasas (`historico_tasas`)**:
  Inserta 3 cambios por producto y **encadena vigencias** (`vigente_desde / vigente_hasta`).
  **Conexión con funciones:** `fn_tasa_vigente(id_producto, fecha)` consulta este histórico para devolver la tasa vigente a una fecha.
  **Conexión con triggers:** `trg_hist_insert` y `trg_hist_update` registran en `auditoria_tasas` cada cambio.

* **Garantes** y **Solicitudes**:
  Asigna **al menos 1 garante por solicitud** (y un segundo garante en ~30%).
  `solicitudes_credito` elige el **gestor** (cargo `Atencion_Cliente`) y el **analista** (cargo `Analista_Credito`) con un reparto uniforme usando `ROW_NUMBER()` en subconsultas derivadas (sin CTEs).

* **Créditos**:
  Se crean **sólo** para solicitudes `Aprobada`.
  La **tasa aplicada** se obtiene con `fn_tasa_vigente`, dejando lista la entrada para generar cuotas.

* **Cuotas**:
  Para **cada crédito**, el seed llama al **procedimiento** `sp_generar_cuotas` (plan francés), dentro de un cursor (`sp_seed_generar_cuotas_all`) que recorre todos los créditos.
  **Control de errores:** `sp_generar_cuotas` maneja transacciones y `SQLEXCEPTION` (ROLLBACK + `SIGNAL`).

* **Pagos** (y **Penalizaciones**):
  Se simulan tres escenarios:

  1. Primera cuota pagada **al día** (50%)
     *Se usa una **tabla temporal** para evitar el error 1442* (ver abajo).
  2. Primera cuota pagada **con mora** (50%)
     Llama a `sp_registrar_pago`, que:

     * Calcula días de demora,
     * Inserta `pagos`,
     * Genera **penalización** con `fn_calcular_mora` si corresponde,
     * Actualiza estado de la cuota.
       **Control de errores:** transacción + `SQLEXCEPTION`.
  3. Segunda cuota pagada **al día** para ~30% de créditos (otra tabla temporal).

  **Conexión con triggers:**

  * `trg_pago_calcular_demora` (BEFORE INSERT en `pagos`) calcula automáticamente `dias_demora`.
  * `trg_pago_actualiza_cuota` (AFTER INSERT en `pagos`) refresca el **estado** de la cuota según pagos/fechas.
  * `trg_cuota_actualiza_credito` (AFTER UPDATE en `cuotas`) recalcula el **estado** del crédito (Pagado / En_Mora / Activo) en función del set de cuotas.

* **Evaluaciones de seguimiento**:
  Inserta 200 evaluaciones asociando cliente–crédito–analista. El **nivel de endeudamiento** se calcula con una razón (deuda/ingresos) y se registran observaciones/recomendaciones variadas.

* **Campañas–Productos** (`campanias_productos`):
  Se generan 180 filas usando una **permutación coprima** y **offset por ciclo** para **evitar duplicados** en la **PK compuesta**. (Soluciona el conflicto típico `Duplicate entry '1-7'`).

### 3) ¿Por qué tablas temporales en pagos?

Para evitar el **Error 1442** (“no se puede actualizar la misma tabla usada en el statement que disparó el trigger”).
El patrón es:

1. Seleccionar las cuotas objetivo a una **tabla temporal**.
2. Hacer `INSERT INTO pagos ... SELECT ... FROM tabla_temporal` (así el trigger puede actualizar `cuotas` sin que sea la misma sentencia que la está leyendo).

### 4) Fechas seguras (límite 2038)

Las columnas `TIMESTAMP` de MySQL tienen límite práctico (year 2038). El seed **“clamp”** las fechas de `historico_tasas.fecha_cambio` a `2037-12-31` para evitar `Incorrect datetime value` en ambientes con zona horaria/restricciones.

---

## Conexión con objetos del esquema

* **Funciones**

  * `fn_tasa_vigente(p_id_producto, p_fecha)` → usada al crear **créditos** para fijar la tasa.
  * `fn_calcular_mora(monto, dias, tasa_diaria)` → usada por `sp_registrar_pago` para **penalizaciones**.

* **Procedimientos**

  * `sp_generar_cuotas(p_id_credito)` → llamado por el seed para **todos** los créditos.
  * `sp_registrar_pago(p_id_cuota,...)` → llamado por el seed para pagos **con mora** (genera penalización y actualiza estados).
  * (Temporales del seed) `sp_seed_generar_cuotas_all` y `sp_seed_pagar_mora_primera` → sólo existen durante el seed y se **droean** al final.

* **Triggers**

  * `trg_clientes_bi` / `trg_clientes_bu` → normalizan `provincia/ciudad` al insertar/actualizar `clientes`.
  * `trg_hist_insert` / `trg_hist_update` → **auditan** movimientos de tasas.
  * `trg_pago_calcular_demora` → calcula demora antes de insertar `pagos`.
  * `trg_pago_actualiza_cuota` → mantiene `estado` de **cuotas** después de cada pago.
  * `trg_cuota_actualiza_credito` → mantiene `estado` de **créditos** tras cambios en cuotas.

---

## Ejecución

```sql
-- 1) DDL
SOURCE esquema_01.sql;

-- 2) Datos
SOURCE seed_02.sql;
```

Al finalizar, el seed ejecuta un **recuento por tabla** para que verifiques los mínimos.

---

## Ajustes rápidos (parametrización)

* Cambiar **volúmenes**: modificar los `WHERE n <= ...` en cada bloque (`clientes`, `solicitudes`, etc.).
* Cambiar **proporciones**: por ejemplo, variar `%` de solicitudes `Aprobada` en el INSERT de `solicitudes_credito`.
* Cambiar **mora**: ajustar la tasa diaria `0.0005` (0.05% diario) al llamar `sp_registrar_pago`.
* Más pagos: duplicar bloques **a/b/c** con otras cuotas y condiciones (usando SIEMPRE tablas temporales si hay triggers sobre esas tablas).

---

## Errores comunes (y cómo los evitamos aquí)

* **1062 Duplicate entry** en PK compuesta (`campanias_productos`) → resuelto con **permutación coprima + offset por ciclo**.
* **1442** (“table is already used by statement which invoked this trigger”) → **tablas temporales** antes de insertar en `pagos`.
* **1292 Incorrect datetime** por `TIMESTAMP` fuera de rango → **clamp** a `2037-12-31`.
* **CTEs recursivos limitados** → secuencia 1..5000 generada **sin `WITH RECURSIVE`**.

---

## Verificación rápida

Al final del seed se imprime un **SELECT** con el conteo por cada tabla. Además, podés validar reglas de negocio:

```sql
-- ¿Todas las solicitudes Aprobadas tienen crédito?
SELECT COUNT(*) falta
FROM solicitudes_credito s
LEFT JOIN creditos c ON c.id_solicitud = s.id_solicitud
WHERE s.estado='Aprobada' AND c.id_credito IS NULL;

-- ¿Créditos en estado consistente con sus cuotas?
SELECT c.id_credito, c.estado, 
       SUM(cu.estado IN ('Pagada','Pagada_Con_Mora')) pagadas,
       SUM(cu.estado = 'Vencida') vencidas,
       COUNT(*) total
FROM creditos c
JOIN cuotas cu ON cu.id_credito=c.id_credito
GROUP BY c.id_credito, c.estado
LIMIT 10;
```

---

## ¿Por qué no INSERTs “a mano” para todo?

Porque acá hay **miles de registros** con **relaciones** y **reglas** (garantes, analistas, moras, auditorías, etc.). El seed generativo es:

* **Rápido y reproducible**,
* **Consistente** con FKs y estados,
* Fácil de **escalar** (cambiar volúmenes y proporciones),
* Seguro frente a **triggers** (tabla temporal) y **límites de fechas**.

Para catálogos chicos y estáticos (p.ej., métodos de pago si fueran una tabla aparte), **sí** conviene INSERTs explícitos.

---

## Licencia y uso

El seed es de **uso académico** y está pensado para pruebas de rendimiento, reportes y validación de la lógica de negocio del sistema de créditos y cobranzas.

Si querés una variante con **más cuotas pagadas**, **más morosidad** o **perfiles por sucursal**, decime y te dejo un `seed_03.sql` parametrizado.

* Tests automatizados (p.ej., con Docker + `mysql:8`).


