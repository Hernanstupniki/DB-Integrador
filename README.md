# Sistema de Gestión de Créditos y Cobranzas — Guía completa (DB + relaciones + 3 archivos)

## Qué incluye

* **`esquema_01.sql`**: crea toda la base (`gestion_creditos`) con catálogos (DOM), geografía escalable (provincias/ciudades), core de negocio, marketing, penalidades, auditoría centralizada, funciones, SPs y triggers.
* **`seed_02.sql`**: carga **datos demo masivos** (≥60 por tabla objetivo) de forma determinista y consistente con el esquema (incluye helper de secuencias, parches anti-solape de tasas y generación de cuotas/pagos).
* **`queries_03.sql`**: set de **reportes, vistas y transacciones** (incluye “Top” sin `LIMIT` usando subconsultas/ventanas, vistas de trabajo y 3 transacciones típicas).

---

## Visión general del modelo

```text
[DOM catálogos]
  dom_* : estados, tipos, métodos, cargos, etc. (tablas maestras finitas, sin ENUM)
    ├─ dom_estado_sucursal     ├─ dom_estado_empleado   ├─ dom_estado_cliente
    ├─ dom_cargo_empleado      ├─ dom_situacion_laboral ├─ dom_tipo_producto
    ├─ dom_estado_producto     ├─ dom_estado_campania   ├─ dom_estado_solicitud
    ├─ dom_estado_credito      ├─ dom_estado_cuota      ├─ dom_metodo_pago
    ├─ dom_estado_penalizacion └─ dom_comp_pago

[GEO escalable]
  provincias(1) ──< ciudades(N)
     ├─ sucursales(N)   (FK: id_provincia, id_ciudad + columnas texto compat.)
     └─ clientes(N)     (FK: id_provincia, id_ciudad + columnas texto compat.)

[NEGOCIO core]
  clientes(1) ──< solicitudes_credito(N) ──1─> productos_financieros
                   └─< solicitudes_garantes(N) >─┐
  garantes ───────────────────────────────────────┘
  solicitudes_credito(1) ──< creditos(1..N) ──< cuotas(1..N) ──< pagos(0..N)
                                               └─< penalizaciones(0..N)

[Marketing]
  campanias_promocionales
    ├─< campanias_productos (N:M con productos_financieros)
    └─< campanias_clientes  (contactos y “conversiones” por fecha)
  clientes.id_campania_ingreso  ← atribución primera conversión

[Seguimiento]
  evaluaciones_seguimiento (cliente/credito evaluado por analista, comp. pago)

[Auditoría]
  auditoria_eventos (auditoría centralizada INSERT/UPDATE/DELETE)
  auditoria_tasas   (auditoria puntual de histórico de tasas)
```

---

## Relaciones clave (cardinalidades y FKs)

### Catálogos (DOM)

* Todas las tablas de negocio referencian IDs de DOM (p.ej., `creditos.id_estado → dom_estado_credito.id`).
* **Invariantes**: dominios son finitos, con `is_deleted` para baja lógica y `codigo` único.

### Geografía

* `ciudades.id_provincia → provincias.id_provincia` (1:N).
* `sucursales.id_provincia/id_ciudad` y `clientes.id_provincia/id_ciudad` → FKs a maestro geo.
  Además, **columnas texto** `provincia/ciudad` en `clientes` y `ciudad` en `sucursales` para compatibilidad con seeds/imports; se normalizan con columnas *virtuales* `*_norm` e índices.

### Negocio

* `solicitudes_credito`:

  * `id_cliente → clientes`, `id_sucursal → sucursales`, `id_producto → productos_financieros`.
  * `id_empleado_gestor` y (opcional) `id_analista` → `empleados`.
  * `id_estado → dom_estado_solicitud`.
* `solicitudes_garantes`:

  * **N:M** entre solicitudes y garantes. PK compuesta `(id_solicitud, id_garante)`.
* `creditos`:

  * `id_solicitud`, `id_cliente`, `id_producto` (FKs) + `id_estado → dom_estado_credito`.
  * `id_credito_refinanciado` (FK auto-referenciada) para encadenar refinanciaciones.
* `cuotas`:

  * `id_credito` (FK), estado → `dom_estado_cuota`.
  * `uq (id_credito, numero_cuota)` asegura plan único por crédito.
* `pagos`:

  * `id_cuota` (FK), `id_metodo → dom_metodo_pago`. `numero_comprobante` único.
* `penalizaciones`:

  * `id_cuota` (FK), `id_estado → dom_estado_penalizacion`.
* `productos_financieros`:

  * `id_tipo → dom_tipo_producto`, `id_estado → dom_estado_producto`.
  * `historico_tasas` (1:N) con ventanas de vigencia no solapadas (validado por trigger).
* `evaluaciones_seguimiento`:

  * `id_cliente`, `id_credito` y `id_analista → empleados` + `id_comp_pago → dom_comp_pago`.

### Marketing

* `campanias_promocionales`:

  * Estados → `dom_estado_campania`.
  * `campanias_productos` (N:M con productos).
  * `campanias_clientes` registra **contactos** por fecha/canal/resultado (PK: `id_campania, id_cliente, fecha_contacto`).
* `clientes.id_campania_ingreso`:

  * atribuye “campaña de ingreso” (primer éxito). Se mantiene por SPs/transacciones.

### Auditoría

* `auditoria_eventos`:

  * columnas: `tabla, pk_nombre, pk_valor, operacion, usuario, evento_ts, datos_antes, datos_despues`.
  * Triggers en `clientes`, `pagos`, `creditos` (extensible) llenan esta bitácora.
* `auditoria_tasas`:

  * soporte para cambios en `historico_tasas` (cuando aplique).

---

## Reglas de negocio implementadas

* **Soft-delete** en todas las tablas: `is_deleted` + `deleted_at/by`.
* **Guardia de pagos**: variable de sesión `@__allow_pago_insert` (trigger `trg_pago_calcular_demora`) **impide** inserts directos en `pagos`; obliga a usar `sp_registrar_pago`.
* **Penalización automática**: trigger `trg_pagos_ai_penalizacion` calcula mora con `fn_calcular_mora` (tasa diaria 0.0005) y crea `penalizaciones` cuando corresponda.
* **Evitar sobrepago**: `sp_registrar_pago` verifica que `p_monto` ≤ saldo de la cuota.
* **Estado de cuota/credito**: triggers actualizan `cuotas.id_estado` y resumen en `creditos.id_estado` (Activo, En_Mora, Pagado).
* **Aprobación exige garantes**: trigger `trg_sol_no_aprobar_sin_garante`.
* **Histórico de tasas sin solapamiento**: trigger `trg_hist_no_solape` + **backfill** de vigencias.
* **Generación de cuotas (francés)**: `sp_generar_cuotas`.
* **Aprobación de solicitud**: `sp_aprobar_solicitud` valida cargo del analista, límites del producto, garantes, tasa vigente (fallback `fn_tasa_vigente`) y crea crédito + plan de cuotas.
* **Refinanciación segura**: `sp_refinanciar_credito` (envuelta por `sp_tx_refinanciar_si_mora`).

---

## Índices y performance (destacados)

* Índices compuestos por acceso típico:

  * `solicitudes_credito(id_producto, fecha_solicitud, id_estado)`
  * `creditos(id_cliente, id_estado, fecha_inicio)`
  * `cuotas(id_estado, fecha_vencimiento)` y `(id_credito, is_deleted)`
  * `clientes(provincia_norm, id_estado)` y `(id_provincia, id_ciudad)`
  * Marketing: `campanias_clientes(id_campania, id_cliente, fecha_contacto)`
* **Generated columns** para normalización paulatina de `clientes.provincia/ciudad`.

---

## Los 3 archivos (qué hace cada uno)

### 1) `esquema_01.sql`

* Crea **todas** las tablas con FKs, checks e índices.
* Define **funciones** (`fn_calcular_mora`, `fn_tasa_vigente`), **procedures** (aprobar solicitud, generar cuotas, registrar pago, refinanciar, asignar evaluación).
* Registra **triggers** de metadatos y de negocio (guardia de pagos, mora, estados, anti-solape).
* Incluye **usuarios** de ejemplo (`admin_creditos`, `analista_credito`, `gestor_cobranza`) y `GRANT` mínimos.

### 2) `seed_02.sql`

* Limpia datos respetando FKs (mantiene objetos).
* Genera secuencia `helper_seq` (1..5000) para poblar masivamente.
* Inserta **DOM** (catálogos) y obtiene IDs en variables.
* **Provincias(60)**, **Sucursales(80)**, **Empleados(300)**, **Campañas(60)**,
  **Clientes(500)** (con mezcla de estados, situaciones, atribuciones),
  **Productos(60)** + **historico_tasas** (3 por producto + parche de vigencias),
  **Garantes(300)**, **Solicitudes(600)** + vínculo de **Garantes**,
  **Créditos** (todas las aprobadas) → **Cuotas** (vía SP),
  **Pagos** (mix: parciales, completos, con/ sin mora) → penalizaciones automáticas,
  **Evaluaciones**, **Campaña–Producto**, **Campaña–Cliente** (~2000 contactos).
* Recalcula estados de cuotas/créditos y contadores de campañas.

### 3) `queries_03.sql`

* **Reportes (Q1–Q30)**: cartera, mora por sucursal, deuda por cliente, top por producto, productividad de analistas, penalizaciones, próximos vencimientos, tasas, tiempos de evaluación, avance de créditos, morosos, eficacia/ROAS/atribución de campañas, cohortes, correlaciones, etc.

  * “Top X” **sin** `LIMIT` cuando corresponde: usa **ventanas** (`DENSE_RANK`) o **subconsultas** de ranking (para cumplir la devolución del profe).
* **Vistas**:

  * `vw_cartera_cobranza`, `vw_solicitudes_analista`, `vw_creditos_avance`,
    `vw_kpi_campanias`, `vw_atribucion_ultimo_toque`.
* **Transacciones (T1–T3)**:

  * `sp_tx_pagar_primeras_cuotas(p_id_cliente)` (usa guardia/validación).
  * `sp_tx_refinanciar_si_mora(...)` (envoltura segura).
  * `sp_tx_registrar_contacto_campania(...)` (contacto + asignación de ingreso + recálculo captados).

---

## Flujo típico (end-to-end)

1. **Ingreso** de cliente → **Solicitud** (gestor) con **garantes**.
2. **Analista** evalúa y **aprueba** (SP), se crea **Crédito + Cuotas**.
3. Cliente **paga** (SP): se calcula demora; si hay mora ⇒ **Penalización**.
4. **Estados** de cuotas/crédito se recalculan automáticamente.
5. **Marketing** empuja contactos en `campanias_clientes`; si “Convirtió”, se setea `id_campania_ingreso` y se actualiza `clientes_captados`.
6. **Reportes** consumen vistas y consultas de `queries_03.sql`.

---

## Normalización y escalabilidad

* **BCNF/3FN** en core; DOM evita `ENUM`.
* Geografía **escalable** (`provincias/ciudades`) con FKs **y** columnas texto de compatibilidad + columnas normalizadas virtuales para migraciones sin “big bang”.
* **Soft-delete** permite auditoría y recuperabilidad.
* **Índices** alineados a lecturas OLTP/OLAP ligeras; vistas para BI liviano.

---

## Buenas prácticas incorporadas

* “**Top X**” mediante ventanas/subconsultas (no `LIMIT` a secas).
* **Triggers** minimalistas y **SPs** para lógica de negocio; **guard rails** para datos críticos (pagos, tasas).
* **Auditoría centralizada** en JSON (fácil de consultar por rango de fechas/tabla/PK).
* **Reproducibilidad** del seed (funciona en MySQL 8; sin `ENGINE/CHARSET` explícitos).

---

## Cómo ejecutar (orden recomendado)

1. `esquema_01.sql`
2. `seed_02.sql`
3. `queries_03.sql` (vistas/consultas/transacciones)

> Si vas a probar transacciones de pago, hacelo con `CALL sp_tx_pagar_primeras_cuotas(<id_cliente>);` y mirá las vistas/consultas (`vw_cartera_cobranza`, Q9, Q12).

---

## Notas de diseño

* **Atribución de campañas**:

  * `campanias_clientes` guarda **todos** los toques;
  * `clientes.id_campania_ingreso` representa **primer** toque exitoso (mantenido por `sp_tx_registrar_contacto_campania`).
  * `vw_atribucion_ultimo_toque` muestra aparte el “last-touch”.
* **Historico de tasas**: ventanas **no solapadas**; función `fn_tasa_vigente` decide la tasa aplicable por fecha.
* **Estados de cliente** (Activo/Moroso/Bloqueado) conviven con estado de crédito/cuota; los reportes los combinan según necesidad.
