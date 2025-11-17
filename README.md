Va todo en uno, bien ordenado, con las entidades débiles marcadas y el textito final para el informe.

---

## 🧠 Reglas generales para dibujar el DER (esquema_01)

* Notación **Chen**:

  * Entidades → **rectángulos**.
  * Entidades débiles → **rectángulo doble**.
  * Relaciones → **rombos** (dobles si son identificadoras de entidad débil).
  * Atributos → **óvalos** (PK **subrayada**).
* Entidades en **singular**: Cliente, Crédito, Cuota…
* **NO dibujar FKs como atributos**: van como relaciones.
* Podés **ocultar** en el DER:

  * borrado_logico, fecha_alta, fecha_modificacion, usuario_*, etc. (son técnicos).

---

## 🔴 Entidades FUERTES vs DÉBILES

### ✅ Entidades FUERTES (rectángulo simple)

Se dibujan como entidades normales:

* **GEO / ORGANIZACIÓN**

  * Provincia

    * id_provincia (PK), nombre
  * Ciudad

    * id_ciudad (PK), nombre
  * Sucursal

    * id_sucursal (PK), nombre, direccion, telefono, email, fecha_apertura
  * Empleado

    * id_empleado (PK), nombre, apellido, dni, email, telefono, fecha_ingreso, salario
  * CargoEmpleado (dom_cargo_empleado)

    * id, codigo, nombre
  * EstadoEmpleado (dom_estado_empleado)

    * id, codigo, nombre
  * EstadoSucursal (dom_estado_sucursal)

    * id, codigo, nombre

* **CLIENTE & GARANTE**

  * Cliente

    * id_cliente (PK), nombre, apellido, dni, fecha_nacimiento, email, telefono, direccion, ingresos_declarados

    > Los campos texto de ciudad/provincia podés omitirlos (se representan por relaciones con Provincia/Ciudad).
  * Garante

    * id_garante (PK), nombre, apellido, dni, email, telefono, direccion, ingresos_declarados, relacion_cliente
  * SituacionLaboral (dom_situacion_laboral)

    * id, codigo, nombre
  * EstadoCliente (dom_estado_cliente)

    * id, codigo, nombre

* **PRODUCTO & TASAS**

  * ProductoFinanciero

    * id_producto (PK), nombre, descripcion, tasa_base, monto_minimo, monto_maximo, plazo_minimo_meses, plazo_maximo_meses, requisitos
  * TipoProducto (dom_tipo_producto)

    * id, codigo, nombre
  * EstadoProducto (dom_estado_producto)

    * id, codigo, nombre
  * HistoricoTasas

    * id_historico (PK), tasa_anterior, tasa_nueva, fecha_cambio, motivo, usuario_responsable, vigente_desde, vigente_hasta

* **CAMPAÑAS**

  * CampañaPromocional

    * id_campania (PK), nombre, descripcion, tasa_promocional, fecha_inicio, fecha_fin, descuento_porcentaje, presupuesto, inversion_realizada, clientes_captados
  * EstadoCampania (dom_estado_campania)

    * id, codigo, nombre

* **CICLO DE CRÉDITO**

  * SolicitudCredito

    * id_solicitud (PK), monto_solicitado, plazo_meses, destino_credito, fecha_solicitud, puntaje_riesgo, observaciones, fecha_evaluacion
  * Credito

    * id_credito (PK), monto_otorgado, tasa_interes, plazo_meses, fecha_inicio, fecha_finalizacion
  * Cuota

    * id_cuota (PK), numero_cuota, fecha_vencimiento, monto_cuota, monto_capital, monto_interes, saldo_pendiente, monto_pagado
  * Pago

    * id_pago (PK), fecha_pago, monto_pagado, dias_demora, numero_comprobante, observaciones
  * Penalizacion

    * id_penalizacion (PK), dias_mora, monto_penalizacion, tasa_mora, fecha_aplicacion
  * EstadoSolicitud (dom_estado_solicitud)
  * EstadoCredito (dom_estado_credito)
  * EstadoCuota (dom_estado_cuota)
  * MetodoPago (dom_metodo_pago)
  * EstadoPenalizacion (dom_estado_penalizacion)

* **EVALUACIÓN**

  * EvaluacionSeguimiento

    * id_evaluacion (PK), fecha_evaluacion, nivel_endeudamiento, puntaje_actualizado, observaciones, recomendaciones
  * CompPago (dom_comp_pago)

    * id, codigo, nombre

* **(Opcional) Auditoría**

  * AuditoriaTasas

    * id_aud, tasa, vigente_desde, vigente_hasta, operacion, audit_ts…
  * AuditoriaEventos

    * id_audit, tabla, pk_nombre, pk_valor, operacion, usuario, evento_ts, datos_antes, datos_despues…

---

### ⚠ Entidades DÉBILES (rectángulo doble)

Dibujalas con **doble rectángulo** y PK **compuesta solo por FKs** (parciales):

1. **CampañaProducto** (`campanias_productos`) – N:M entre Campaña y Producto

   * (PK parcial) id_campania
   * (PK parcial) id_producto

2. **CampañaCliente** (`campanias_clientes`) – N:M entre Campaña y Cliente

   * (PK parcial) id_campania
   * (PK parcial) id_cliente
   * (PK parcial) fecha_contacto
   * canal
   * resultado

3. **SolicitudGarante** (`solicitudes_garantes`) – N:M entre Solicitud y Garante

   * (PK parcial) id_solicitud
   * (PK parcial) id_garante
   * fecha_vinculacion

Las tres van con **rectángulo doble** y conectadas con **rombos identificadores (dobles)** a sus entidades fuertes.

---

## 1️⃣ Bloque GEO (arriba izquierda)

### Entidades (fuertes)

* Provincia (id_provincia, nombre)
* Ciudad (id_ciudad, nombre)
* Sucursal (id_sucursal, nombre, direccion, telefono, email, fecha_apertura)
* Empleado (id_empleado, nombre, apellido, dni, email, telefono, fecha_ingreso, salario)
* CargoEmpleado, EstadoEmpleado, EstadoSucursal (dominios)

### Relaciones

* **Provincia —(tiene)→ Ciudad**

  * 1 Provincia — N Ciudades (ciudades.id_provincia)

* **Provincia —(tiene)→ Sucursal**

  * 1 Provincia — N Sucursales (sucursales.id_provincia)

* **Ciudad —(tiene)→ Sucursal**

  * 0..1 Ciudad — N Sucursales (sucursales.id_ciudad puede ser NULL)

* **Sucursal —(emplea a)→ Empleado**

  * 1 Sucursal — N Empleados (empleados.id_sucursal)

* **CargoEmpleado —(clasifica)→ Empleado**

  * 1 Cargo — N Empleados

* **EstadoEmpleado —(clasifica)→ Empleado**

  * 1 EstadoEmpleado — N Empleados

* **EstadoSucursal —(clasifica)→ Sucursal**

  * 1 EstadoSucursal — N Sucursales

---

## 2️⃣ Bloque CLIENTE & GARANTE (centro izquierda)

### Entidades

* Cliente (fuerte)
* Garante (fuerte)
* SituacionLaboral (dom)
* EstadoCliente (dom)

### Relaciones

* **Provincia —(tiene)→ Cliente**

  * 1 Provincia — N Clientes (clientes.id_provincia)

* **Ciudad —(tiene)→ Cliente**

  * 0..1 Ciudad — N Clientes (clientes.id_ciudad)

* **SituacionLaboral —(tiene)→ Cliente**

  * 0..1 SituacionLaboral — N Clientes (clientes.id_situacion_laboral)

* **EstadoCliente —(clasifica)→ Cliente**

  * 1 EstadoCliente — N Clientes

*(Garante por ahora solo se usa en la relación N:M de abajo).*

---

## 3️⃣ Bloque PRODUCTO & TASAS (arriba centro)

### Entidades

* ProductoFinanciero (fuerte)
* TipoProducto (dom)
* EstadoProducto (dom)
* HistoricoTasas (fuerte)

### Relaciones

* **TipoProducto —(clasifica)→ ProductoFinanciero**

  * 1 Tipo — N Productos

* **EstadoProducto —(clasifica)→ ProductoFinanciero**

  * 1 Estado — N Productos

* **ProductoFinanciero —(tiene)→ HistoricoTasas**

  * 1 Producto — N Históricos

---

## 4️⃣ Bloque CAMPAÑAS (arriba derecha / derecha centro)

### Entidades

* CampañaPromocional (fuerte)
* EstadoCampania (dom)
* **CampañaProducto** (débil, N:M)
* **CampañaCliente** (débil, N:M)

### Relaciones

* **EstadoCampania —(clasifica)→ CampañaPromocional**

  * 1 Estado — N Campañas

* **CampañaPromocional —◇◇→ CampañaProducto ←◇◇— ProductoFinanciero**

  * Ambas relaciones **identificadoras** (doble rombo)
  * 1 Campaña — N CampañaProducto
  * 1 Producto — N CampañaProducto

* **CampañaPromocional —◇◇→ CampañaCliente ←◇◇— Cliente**

  * N:M con entidad débil CampañaCliente
  * 1 Campaña — N CampañaCliente
  * 1 Cliente — N CampañaCliente

  Atributos en CampañaCliente:

  * (PK parciales) id_campania, id_cliente, fecha_contacto
  * canal, resultado

* **CampañaPromocional —(origen_de)→ Cliente** (id_campania_ingreso)

  * 0..1 Campaña — N Clientes
  * Dibujo: rombo “origina” entre CampañaPromocional y Cliente.

---

## 5️⃣ Bloque SOLICITUD → CRÉDITO → CUOTA → PAGO/PENALIZACIÓN (línea central)

Pone esto en el centro de la hoja.

### Entidades

* SolicitudCredito
* Credito
* Cuota
* Pago
* Penalizacion
* EstadoSolicitud (dom)
* EstadoCredito (dom)
* EstadoCuota (dom)
* MetodoPago (dom)
* EstadoPenalizacion (dom)

### Relaciones

1. **Cliente —(solicita)→ SolicitudCredito**

   * 1 Cliente — N Solicitudes

2. **Sucursal —(recibe)→ SolicitudCredito**

   * 1 Sucursal — N Solicitudes

3. **Empleado —(gestiona)→ SolicitudCredito**

   * 1 Empleado — N Solicitudes como gestor (id_empleado_gestor)

4. **Empleado —(analiza)→ SolicitudCredito**

   * 0..1 Empleado — N Solicitudes como analista (id_analista)

5. **ProductoFinanciero —(es_solicitado_en)→ SolicitudCredito**

   * 1 Producto — N Solicitudes

6. **EstadoSolicitud —(clasifica)→ SolicitudCredito**

   * 1 Estado — N Solicitudes

7. **SolicitudCredito —(genera)→ Credito**

   * 1 Solicitud — 0..1 Crédito (conceptual: 1→1)

8. **Cliente —(posee)→ Credito**

   * 1 Cliente — N Créditos

9. **ProductoFinanciero —(se_otorga_en)→ Credito**

   * 1 Producto — N Créditos

10. **EstadoCredito —(clasifica)→ Credito**

    * 1 Estado — N Créditos

11. **Credito —(se_divide_en)→ Cuota**

    * 1 Crédito — N Cuotas

12. **EstadoCuota —(clasifica)→ Cuota**

    * 1 Estado — N Cuotas

13. **Cuota —(recibe)→ Pago**

    * 1 Cuota — N Pagos

14. **MetodoPago —(se_utiliza_en)→ Pago**

    * 1 Método — N Pagos

15. **Cuota —(genera)→ Penalizacion**

    * 1 Cuota — N Penalizaciones

16. **EstadoPenalizacion —(clasifica)→ Penalizacion**

    * 1 Estado — N Penalizaciones

17. **Credito —(es_refinanciado_por)→ Credito** (autorelación)

    * 1 Crédito original — 0..N Créditos nuevos
    * Dibujo: rombo “refinancia” entre Crédito y Crédito.

---

## 6️⃣ Bloque SOLICITUD–GARANTES (abajo centro) – ENTIDAD DÉBIL

### Entidad débil: SolicitudGarante

* (PK parcial) id_solicitud
* (PK parcial) id_garante
* fecha_vinculacion

### Relación N:M (con entidad débil)

* **SolicitudCredito —◇◇→ SolicitudGarante ←◇◇— Garante**

  * 1 Solicitud — N SolicitudGarante
  * 1 Garante — N SolicitudGarante

---

## 7️⃣ Bloque EVALUACIÓN Y COMPORTAMIENTO PAGO (abajo derecha)

### Entidades

* EvaluacionSeguimiento (fuerte)
* CompPago (dom)

### Relaciones

* **Cliente —(es_evaluado_en)→ EvaluacionSeguimiento**

  * 1 Cliente — N Evaluaciones

* **Credito —(se_evalua_en)→ EvaluacionSeguimiento**

  * 1 Crédito — N Evaluaciones

* **Empleado (Analista) —(analiza)→ EvaluacionSeguimiento**

  * 1 Empleado — N Evaluaciones

* **CompPago —(clasifica)→ EvaluacionSeguimiento**

  * 1 CompPago — N Evaluaciones

---

## 8️⃣ Auditoría (opcional en el DER)

Podés:

* No dibujar AuditoriaTasas y AuditoriaEventos, y solo mencionarlas en el informe.
* O ponerlas en un módulo técnico aparte con una nota:

> “Tablas técnicas de auditoría, que registran cambios sobre varias entidades del modelo.”

---

## 9️⃣ Layout sugerido (dónde va cada bloque en la hoja)

* **Arriba izquierda:** Provincia – Ciudad – Sucursal – Empleado + (EstadoSucursal, CargoEmpleado, EstadoEmpleado).
* **Centro izquierda:** Cliente – Garante + (SituacionLaboral, EstadoCliente) + relaciones a Provincia/Ciudad.
* **Arriba centro:** ProductoFinanciero + TipoProducto + EstadoProducto + HistoricoTasas.
* **Arriba derecha / derecha centro:**

  * CampañaPromocional + EstadoCampania (fuertes).
  * Debajo/lateral: **CampañaProducto** y **CampañaCliente** (doble rectángulo, entidades débiles, con rombos dobles hacia Campaña/Producto/Cliente).
* **Centro horizontal:**
  Cliente → SolicitudCredito → Credito → Cuota → Pago / Penalizacion.
* **Abajo centro:**
  **SolicitudGarante** (doble rectángulo) enlazando SolicitudCredito y Garante.
* **Abajo derecha:**
  EvaluacionSeguimiento + CompPago.
* **Muy abajo o al costado:**
  AuditoriaTasas y AuditoriaEventos (si las mostrás).

---

## 📝 Textito para el informe (copiar/pegar)

> El modelo entidad–relación se organizó en módulos funcionales: geo–organizativo (provincias, ciudades, sucursales y empleados), clientes y garantes, productos financieros y su histórico de tasas, ciclo de vida del crédito (solicitudes, créditos, cuotas, pagos y penalizaciones), campañas de marketing y evaluación de comportamiento de pago.
>
> A partir del esquema físico se identificaron tanto entidades fuertes, con identidad propia (por ejemplo, Cliente, Crédito, ProductoFinanciero o CampañaPromocional), como tres entidades débiles: **CampañaProducto**, **CampañaCliente** y **SolicitudGarante**, cuyas claves primarias están compuestas únicamente por claves foráneas hacia entidades fuertes y se representan mediante rectángulos dobles y relaciones identificadoras de tipo N:M.
>
> Además, se incorporaron tablas de dominio (estados, tipos, situaciones laborales, métodos de pago, etc.) modeladas como entidades que “clasifican” a las entidades principales, lo que permite desacoplar la lógica de negocio de los valores de catálogo. Finalmente, las tablas técnicas de auditoría se consideraron parte de la capa de implementación y, en caso de representarse, se agrupan en un módulo separado para no sobrecargar la vista conceptual del DER.

Con esto ya podés dibujar el DER 1:1 con esquema_01 y justificarlo en el informe.
