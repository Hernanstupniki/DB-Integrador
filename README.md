# 🔗 Modelo de Datos y Relaciones (explicado)

## Visión general (dominios → core → marketing → auditoría)

```
[DOM catálogos]
  dom_* (estados, tipos, métodos, cargos, etc.)

[GEO]
  provincias(1) ──< ciudades(N)
         └──< sucursales(N)  (via id_provincia, id_ciudad)
         └──< clientes(N)    (via id_provincia, id_ciudad; + columnas texto comp.)

[NEGOCIO CORE]
  clientes(1) ──< solicitudes_credito(N)
  solicitudes_credito(1) ──< solicitudes_garantes(N) >──(1) garantes
  solicitudes_credito(1) ──< creditos(N)
  creditos(1) ──< cuotas(N)
  cuotas(1) ──< pagos(N)
  cuotas(1) ──< penalizaciones(N)

[PRODUCTOS Y TASAS]
  dom_tipo_producto(1) ──< productos_financieros(N) ──< historico_tasas(N)

[RRHH]
  sucursales(1) ──< empleados(N) ──(1) dom_cargo_empleado
  empleados(Analistas) ──< solicitudes_credito (como id_analista)
  empleados(Analistas) ──< evaluaciones_seguimiento

[MARKETING]
  campanias_promocionales
      ├─< campanias_productos >─ productos_financieros    (N:M)
      ├─< campanias_clientes    (N:M con id_cliente, fecha_contacto, canal, resultado)
      └─ clientes(id_campania_ingreso)  (atribución first-convert wins)

[AUDITORÍA]
  auditoria_eventos (INSERT/UPDATE/DELETE de tablas clave)
  auditoria_tasas   (cambios en historico_tasas)
```

---

## Relaciones clave (con cardinalidad y por qué existen)

### 1) Geografía escalable

* **provincias (1) ──< ciudades (N)**
  Una provincia tiene muchas ciudades. FK: `ciudades.id_provincia`.
* **provincias/ciudades ──< sucursales**
  Cada sucursal se ubica en una ciudad/provincia. FKs: `sucursales.id_provincia`, `sucursales.id_ciudad`.
  **Compatibilidad**: además guardamos `sucursales.ciudad` (texto) para seeds/históricos.
* **provincias/ciudades ──< clientes**
  Similar a sucursales, con FKs **y** columnas texto (`provincia`, `ciudad`) + columnas `GENERATED` normalizadas (`provincia_norm`, `ciudad_norm`) para búsquedas legacy.

> **Beneficio:** podés migrar de texto → FK **sin romper** datos antiguos. Además permite enriquecer (mapas, clusters, BI geográfico).

---

### 2) Proceso de crédito (pipeline completo)

1. **clientes (1) ──< solicitudes_credito (N)**
   Un cliente puede realizar múltiples solicitudes.
   `solicitudes_credito` referencia:

   * `id_sucursal`: dónde se gestionó.
   * `id_empleado_gestor`: quién la tomó.
   * `id_analista` (opcional hasta evaluar).
   * `id_estado` (Pendiente, En_Revision, Aprobada, Rechazada – **dom_estado_solicitud**).
   * **Reglas**: el trigger `trg_sol_no_aprobar_sin_garante` impide aprobar si no hay garantes.

2. **solicitudes_credito (1) ──< solicitudes_garantes (N) >── (1) garantes**
   Relación **N:M** entre solicitudes y garantes materializada como `solicitudes_garantes`.

   * Se puede exigir ≥1 garante para aprobar (validado por trigger y SPs).

3. **solicitudes_credito (Aprobada) ──< creditos**
   Un crédito nace de una solicitud aprobada.

   * Guarda `monto_otorgado`, `tasa_interes`, `plazo_meses`, fechas y **estado** (Activo, En_Mora, Pagado, Refinanciado – **dom_estado_credito**).

4. **creditos (1) ──< cuotas (N)**
   Cada crédito se amortiza en N cuotas (generadas por `sp_generar_cuotas`).

   * Cada cuota tiene `monto_cuota`, descomposición capital/interés, `saldo_pendiente`, `monto_pagado` y **estado** (Pendiente, Vencida, Pagada, Pagada_Con_Mora – **dom_estado_cuota**).
   * El trigger `trg_cuota_actualiza_credito` recalcula el **estado del crédito** según sus cuotas.

5. **cuotas (1) ──< pagos (N)**
   Los pagos **no** se insertan directo (salvo guardia de semillas). Deben pasar por `sp_registrar_pago`:

   * Valida **no sobrepago** (pago ≤ saldo de cuota).
   * Calcula `dias_demora`.
   * Si hay mora, el **AFTER INSERT** en `pagos` crea una **penalización**.

6. **cuotas (1) ──< penalizaciones (N)**
   Se generan automáticamente con `fn_calcular_mora(monto, días, tasa)` y quedan en `dom_estado_penalizacion` Pendiente → Pagada (cuando la cuota pasa a pagada).

> **Flujo completo:** Cliente → Solicitud(+Garantes) → Aprobación → Crédito → Cuotas → Pagos → Penalizaciones (auto) → Estado de Crédito.

---

### 3) Productos y tasas

* **dom_tipo_producto (1) ──< productos_financieros (N)**
  Tipos: Personal, Hipotecario, Empresarial, Leasing, Tarjeta_Corporativa, etc.
* **productos_financieros (1) ──< historico_tasas (N)**
  Cambios de tasa con **ventanas de vigencia**: `vigente_desde`/`vigente_hasta`.
  **Trigger anti-solape**: `trg_hist_no_solape`.
  **Función**: `fn_tasa_vigente(id_producto, fecha)` determina la tasa aplicable en una fecha.

> **Uso:** Al aprobar / refinanciar, si no se pasa una tasa explícita, se toma la **vigente** al día.

---

### 4) RRHH

* **sucursales (1) ──< empleados (N)**
  Con FK a `dom_cargo_empleado` y `dom_estado_empleado`.
  **Analistas** aparecen como `id_analista` en `solicitudes_credito` y en `evaluaciones_seguimiento`.

---

### 5) Marketing y atribución

* **campanias_promocionales**: cabecera con presupuesto, inversión y `id_estado` (**dom_estado_campania**).
* **campanias_productos (N:M)**: qué productos se promocionan en cada campaña.
* **campanias_clientes (N:M con trazas)**:

  * Clave: `(id_campania, id_cliente, fecha_contacto)`
  * Guarda **canal** (Web/Sucursal/Email/WhatsApp), **resultado** (‘Convirtio’ o ‘No’).
  * Permite análisis de **funnel**, **series temporales**, y **atribución**:

    * **Last touch**: vista `vw_atribucion_ultimo_toque`.
    * **First convert wins**: si el primer contacto que convierte no tiene `id_campania_ingreso`, el SP `sp_tx_registrar_contacto_campania` la asigna y recalcula `clientes_captados`.

> **KPIs**: vistas y queries Q22–Q30 (con **ROAS**, **CPA**, cohortes, aprobación por analista, etc.).

---

### 6) Auditoría

* **auditoria_eventos**: captura **INSERT/UPDATE/DELETE** de `clientes`, `pagos`, `creditos` (puede ampliarse a más tablas). Guarda **antes/después** en JSON, usuario y timestamp.
* **auditoria_tasas**: línea fina para trazas de `historico_tasas`.

> **Objetivo:** trazabilidad, debugging y futura integración con **CDC** / Data Lake.

---

## Estados (DOM) y transiciones típicas

* **dom_estado_solicitud**: `Pendiente` → `En_Revision` → `Aprobada`/`Rechazada`

  * **Regla**: no se puede pasar a **Aprobada** si la solicitud **no** tiene garantes (trigger).
* **dom_estado_credito**: `Activo` ⇄ `En_Mora` → `Pagado` / `Refinanciado`

  * Se recalcula por trigger al tocar cuotas.
* **dom_estado_cuota**: `Pendiente` → `Vencida` → `Pagada`/`Pagada_Con_Mora`

  * Depende de `monto_pagado` y `fecha_vencimiento`.
* **dom_estado_penalizacion**: `Pendiente` → `Pagada`

  * Se marca pagada cuando la cuota se paga (trigger `trg_penalizacion_marcar_pagada`).

---

## Ejemplos de recorridos (con consultas tipo)

### A) “¿Cuánto debe cada cliente (vencido+pendiente)?”

```sql
SELECT cl.id_cliente,
       CONCAT(cl.nombre,' ',cl.apellido) AS cliente,
       ROUND(SUM(CASE WHEN cu.id_estado IN (@id_cuo_pend, @id_cuo_venc)
                THEN cu.monto_cuota - COALESCE(cu.monto_pagado,0) ELSE 0 END),2) AS deuda
FROM clientes cl
JOIN creditos cr ON cr.id_cliente = cl.id_cliente AND cr.is_deleted=0
JOIN cuotas   cu ON cu.id_credito = cr.id_credito AND cu.is_deleted=0
WHERE cl.is_deleted=0
GROUP BY cl.id_cliente, cliente;
```

### B) “¿Qué analista aprueba más y en menos tiempo?”

* Tasa de aprobación: **Q28**
* Tiempo de evaluación por estado: **Q11**

### C) “Top de sucursales por vencido (sin `LIMIT`)”

* Usar **subconsulta** con `DENSE_RANK()` (ver **Q15**).

---

## Decisiones de diseño (por qué así)

1. **GEO dual (texto + FK)**
   Permite migración **progresiva** y compatibilidad con datasets viejos. `*_norm` generadas hacen las búsquedas rápidas aun sin FKs.

2. **Catálogos DOM (sin ENUM)**
   Cambiar estados/tipos no requiere DDL; se audita y se versiona.

3. **Pagos protegidos por SP + guardia**
   Evita inconsistencias (sobrepago, falta de penalización, fechas mal calculadas). Solo seeds y SPs pueden insertar.

4. **Triggers como “guard rails”**

   * Anti-solape de tasas (consistencia temporal).
   * Anti-aprobación sin garantes (regla de negocio).
   * Re-cálculo del estado del crédito (integridad derivada).

5. **Vistas KPI “MERGE”**
   Para exponer métricas estables a usuarios con **solo SELECT** (ideal para dashboards o BI ligero).

6. **Top X sin `LIMIT` (consigna académica)**
   Consultas implementadas con **rankings/subconsultas** (ej. Q5, Q15, Q27) para cumplir buenas prácticas pedidas por cátedra.

---

## Rendimiento e índices (razonamiento)

* **Filtros calientes**

  * `cuotas(id_credito,id_estado,fecha_vencimiento)` → cobranza y paneles de mora.
  * `pagos(id_cuota,fecha_pago)` → conciliación y series.
  * `solicitudes_credito(id_producto,fecha_solicitud,id_estado)` → embudo comercial.
  * `clientes(provincia_norm,id_estado)` y `clientes(id_provincia/id_ciudad)` → filtros geo mixtos.
* **Cardinalidades altas**: `campanias_clientes` puede crecer grande; conviene indexar `(id_cliente, fecha_contacto)` y `(id_campania, fecha_contacto)` si las series y last/first touch son muy usados.
* **Histórico de tasas**: `(id_producto, vigente_desde, vigente_hasta)` acelera `fn_tasa_vigente`.

---

## Ciclos de vida (CRUD resumido)

* **Solicitud**: `INSERT` → (evalúa) `UPDATE id_estado` → **Aprobada** crea **Crédito** (SP)
* **Crédito**: `INSERT` (con tasa vigente) → `sp_generar_cuotas` → **Cuotas**
* **Pago**: `sp_registrar_pago` → **Penalización** (auto) → **Actualizar estado cuotas/credito**
* **Refinanciación**: `sp_refinanciar_credito` deja original en “Refinanciado” y crea **nuevo crédito** + **nuevas cuotas**
* **Campañas**: contactos en `campanias_clientes`; cuando “Convirtio” (first-convert) se fija `id_campania_ingreso` y recalculan captados

---

## “Qué mirar” si algo falla

* **Q27 “0 resultados”**: verificá que haya **contactos recientes** (<90 días) y que **ninguno** tenga `resultado='Convirtio'`. Si la demo es muy “exitosa”, baja el umbral a `>=2` (ya lo hace) o extendé la ventana.
* **Tasas**: si `fn_tasa_vigente` devuelve 0, corré el “backfill de vigencias” de `esquema_01.sql` o el **parche** de `seed_02.sql`.
* **Pagos directos**: el trigger bloquea; usá el **SP** o la **guardia** en seeds.

