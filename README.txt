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

