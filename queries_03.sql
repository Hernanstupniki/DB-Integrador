-- Sistema de Gestion de Creditos y Cobranzas
-- Consultas realizadas de Base de Datos: gestion_creditos


USE gestion_creditos;

-- Variables de dominio (solo consultas y sps; no en vistas)
SET @id_cuo_pend   = (SELECT id FROM estado_cuota     WHERE codigo='Pendiente');
SET @id_cuo_pag    = (SELECT id FROM estado_cuota     WHERE codigo='Pagada');
SET @id_cuo_venc   = (SELECT id FROM estado_cuota     WHERE codigo='Vencida');
SET @id_cuo_pagmor = (SELECT id FROM estado_cuota     WHERE codigo='Pagada_Con_Mora');

SET @id_cre_act = (SELECT id FROM estado_credito WHERE codigo='Activo');
SET @id_cre_mor = (SELECT id FROM estado_credito WHERE codigo='En_Mora');
SET @id_cre_pag = (SELECT id FROM estado_credito WHERE codigo='Pagado');

SET @id_sol_pend = (SELECT id FROM estado_solicitud WHERE codigo='Pendiente');
SET @id_sol_enrev= (SELECT id FROM estado_solicitud WHERE codigo='En_Revision');
SET @id_sol_aprb = (SELECT id FROM estado_solicitud WHERE codigo='Aprobada');
SET @id_sol_rech = (SELECT id FROM estado_solicitud WHERE codigo='Rechazada');

SET @id_cargo_an = (SELECT id FROM cargo_empleado WHERE codigo='Analista_Credito');
SET @id_met_trf  = (SELECT id FROM metodo_pago    WHERE codigo='Transferencia');


-- CONSULTAS (1–21)

-- Q1. Cartera por tipo de producto y estado del credito
SELECT
  tp.codigo AS tipo_producto,
  ec.codigo AS estado_credito,
  COUNT(*)                         AS cant_creditos,
  ROUND(SUM(c.monto_otorgado), 2)  AS monto_total
FROM creditos c
JOIN productos_financieros pf ON pf.id_producto = c.id_producto AND pf.borrado_logico=0
JOIN tipo_producto  tp        ON tp.id = pf.id_tipo
JOIN estado_credito ec        ON ec.id = c.id_estado
WHERE c.borrado_logico = 0
GROUP BY tp.codigo, ec.codigo
ORDER BY tp.codigo,
         FIELD(ec.codigo,'Activo','En_Mora','Refinanciado','Pagado','Cancelado');

-- Q2. Mora promedio (en dias) por sucursal (solo vencidas o pagadas con mora)
SELECT
  s.id_sucursal,
  s.nombre AS sucursal,
  ROUND(AVG(GREATEST(0, DATEDIFF(CURDATE(), cu.fecha_vencimiento))), 2) AS mora_promedio_dias
FROM sucursales s
JOIN solicitudes_credito sc ON sc.id_sucursal = s.id_sucursal AND sc.borrado_logico=0
JOIN creditos c            ON c.id_solicitud = sc.id_solicitud AND c.borrado_logico=0
JOIN cuotas cu             ON cu.id_credito  = c.id_credito   AND cu.borrado_logico=0
WHERE s.borrado_logico = 0
  AND cu.id_estado IN (@id_cuo_venc, @id_cuo_pagmor)
GROUP BY s.id_sucursal, s.nombre
ORDER BY mora_promedio_dias DESC;

-- Q3. Deuda vigente por cliente – Top 50 (sin LIMIT, con subconsulta para ranking)
WITH deuda AS (
  SELECT
    cl.id_cliente,
    CONCAT(cl.nombre,' ',cl.apellido) AS cliente,
    ROUND(SUM(
      CASE WHEN cu.id_estado IN (@id_cuo_pend,@id_cuo_venc)
           THEN (cu.monto_cuota - COALESCE(cu.monto_pagado,0)) ELSE 0 END
    ), 2) AS deuda_vigente
  FROM clientes cl
  JOIN creditos cr ON cr.id_cliente = cl.id_cliente AND cr.borrado_logico=0
  JOIN cuotas cu   ON cu.id_credito = cr.id_credito AND cu.borrado_logico=0
  WHERE cl.borrado_logico = 0
  GROUP BY cl.id_cliente, cliente
  HAVING deuda_vigente > 0
)
SELECT d1.*
FROM deuda d1
WHERE (
  SELECT COUNT(*)
  FROM deuda d2
  WHERE d2.deuda_vigente > d1.deuda_vigente
     OR (d2.deuda_vigente = d1.deuda_vigente AND d2.id_cliente < d1.id_cliente)
) < 50
ORDER BY d1.deuda_vigente DESC, d1.id_cliente;

-- Q4. Campañas: captacion y creditos generados
SELECT
  cp.id_campania,
  cp.nombre,
  COUNT(DISTINCT cl.id_cliente)       AS clientes_captados,    -- <- ahora se calcula
  COUNT(DISTINCT cr.id_credito)       AS creditos_generados
FROM campanias_promocionales cp
LEFT JOIN clientes  cl 
       ON cl.id_campania_ingreso = cp.id_campania 
      AND cl.borrado_logico = 0
LEFT JOIN creditos  cr 
       ON cr.id_cliente = cl.id_cliente 
      AND cr.borrado_logico = 0
WHERE cp.borrado_logico = 0
GROUP BY cp.id_campania, cp.nombre
ORDER BY creditos_generados DESC, clientes_captados DESC;

-- Q5. Top 5 deudores por sucursal (ranking por particion)
WITH deuda AS (
  SELECT
    s.id_sucursal,
    cl.id_cliente,
    CONCAT(cl.nombre,' ',cl.apellido) AS cliente,
    ROUND(SUM(CASE WHEN cu.id_estado IN (@id_cuo_pend,@id_cuo_venc)
              THEN (cu.monto_cuota - COALESCE(cu.monto_pagado,0)) ELSE 0 END), 2) AS deuda
  FROM sucursales s
  JOIN solicitudes_credito sc ON sc.id_sucursal = s.id_sucursal AND sc.borrado_logico = 0
  JOIN creditos cr            ON cr.id_solicitud = sc.id_solicitud AND cr.borrado_logico = 0
  JOIN clientes cl            ON cl.id_cliente   = sc.id_cliente   AND cl.borrado_logico = 0
  JOIN cuotas cu              ON cu.id_credito   = cr.id_credito   AND cu.borrado_logico = 0
  WHERE s.borrado_logico = 0
  GROUP BY s.id_sucursal, cl.id_cliente, cliente
)
SELECT *
FROM (
  SELECT d.*,
         DENSE_RANK() OVER (PARTITION BY id_sucursal ORDER BY deuda DESC) AS rk
  FROM deuda d
) x
WHERE rk <= 5
ORDER BY id_sucursal, rk;

-- Q6. Top 10 productos por total otorgado (sin LIMIT, con subconsulta)
WITH tot AS (
  SELECT
    pf.id_producto, pf.nombre,
    ROUND(SUM(c.monto_otorgado), 2) AS total_otorgado
  FROM productos_financieros pf
  JOIN creditos c ON c.id_producto = pf.id_producto AND c.borrado_logico=0
  WHERE pf.borrado_logico = 0
  GROUP BY pf.id_producto, pf.nombre
)
SELECT t1.*
FROM tot t1
WHERE (
  SELECT COUNT(*)
  FROM tot t2
  WHERE t2.total_otorgado > t1.total_otorgado
     OR (t2.total_otorgado = t1.total_otorgado AND t2.id_producto < t1.id_producto)
) < 10
ORDER BY t1.total_otorgado DESC, t1.id_producto;


-- Q7
SELECT
  e.id_empleado AS id_analista,
  CONCAT(e.nombre,' ',e.apellido) AS analista,
  SUM(CASE WHEN sc.id_estado = @id_sol_pend THEN 1 ELSE 0 END)  AS pend,
  SUM(CASE WHEN sc.id_estado = @id_sol_enrev THEN 1 ELSE 0 END) AS rev,
  SUM(CASE WHEN sc.id_estado = @id_sol_aprb THEN 1 ELSE 0 END)  AS apr,
  SUM(CASE WHEN sc.id_estado = @id_sol_rech THEN 1 ELSE 0 END)  AS rec
FROM empleados e
JOIN cargo_empleado ce 
    ON ce.id = e.id_cargo 
   AND ce.codigo = 'Analista_Credito'
LEFT JOIN solicitudes_credito sc 
    ON sc.id_analista = e.id_empleado 
   AND sc.borrado_logico = 0
WHERE e.borrado_logico = 0
GROUP BY e.id_empleado, analista
ORDER BY apr DESC, rec DESC;


-- Q8. Penalizaciones cobradas por mes (ultimos 12 meses)
SELECT
  DATE_FORMAT(p.fecha_aplicacion, '%Y-%m') AS yymm,
  ROUND(SUM(p.monto_penalizacion), 2) AS penalizacion_mes
FROM penalizaciones p
WHERE p.borrado_logico = 0
  AND p.fecha_aplicacion >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY yymm
ORDER BY yymm DESC;

-- Q9. Cuotas que vencen en los proximos 15 dias
SELECT
  cu.id_cuota, cu.fecha_vencimiento, ecu.codigo AS estado_cuota,
  cr.id_credito, cl.id_cliente, CONCAT(cl.nombre,' ',cl.apellido) AS cliente
FROM cuotas cu
JOIN estado_cuota ecu ON ecu.id=cu.id_estado
JOIN creditos cr ON cr.id_credito = cu.id_credito AND cr.borrado_logico=0
JOIN clientes cl ON cl.id_cliente = cr.id_cliente AND cl.borrado_logico=0
WHERE cu.borrado_logico = 0
  AND cu.fecha_vencimiento BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 15 DAY)
ORDER BY cu.fecha_vencimiento, cliente;

-- Q10. Tasa vigente vs tasa base (delta)
SELECT
  pf.id_producto, pf.nombre,
  pf.tasa_base AS tasa_base_anual,
  fn_tasa_vigente(pf.id_producto, CURDATE()) AS tasa_vigente_hoy,
  ROUND(fn_tasa_vigente(pf.id_producto, CURDATE()) - pf.tasa_base, 3) AS delta
FROM productos_financieros pf
WHERE pf.borrado_logico = 0
ORDER BY ABS(delta) DESC;

-- Q11. Tiempo promedio de evaluacion por estado
SELECT
  es.codigo AS estado_solicitud,
  ROUND(AVG(DATEDIFF(COALESCE(sc.fecha_evaluacion, NOW()), sc.fecha_solicitud)), 2) AS dias_promedio
FROM solicitudes_credito sc
JOIN estado_solicitud es ON es.id=sc.id_estado
WHERE sc.borrado_logico = 0
GROUP BY es.codigo
ORDER BY dias_promedio DESC;

-- Q12. Avance proporcional (%) por credito – Top 150 (sin LIMIT)
WITH avance AS (
  SELECT
    c.id_credito,
    SUM(LEAST(COALESCE(cu.monto_pagado,0), cu.monto_cuota)) AS pagado_cap,
    SUM(cu.monto_cuota) AS deuda_plan
  FROM creditos c
  JOIN cuotas cu ON cu.id_credito = c.id_credito AND cu.borrado_logico=0
  WHERE c.borrado_logico = 0
  GROUP BY c.id_credito
),
calc AS (
  SELECT id_credito,
         ROUND(100 * pagado_cap / NULLIF(deuda_plan,0), 2) AS avance_pct
  FROM avance
)
SELECT c1.*
FROM calc c1
WHERE (
  SELECT COUNT(*)
  FROM calc c2
  WHERE c2.avance_pct > c1.avance_pct
     OR (c2.avance_pct = c1.avance_pct AND c2.id_credito < c1.id_credito)
) < 150
ORDER BY c1.avance_pct DESC, c1.id_credito;

-- Q13. Clientes morosos: deuda acumulada
SELECT
  cl.id_cliente,
  CONCAT(cl.nombre,' ',cl.apellido) AS cliente,
  ec.codigo AS estado_cliente,
  ROUND(SUM(CASE WHEN cu.id_estado IN (@id_cuo_pend,@id_cuo_venc)
            THEN (cu.monto_cuota - COALESCE(cu.monto_pagado,0)) ELSE 0 END), 2) AS deuda
FROM clientes cl
JOIN estado_cliente ec ON ec.id=cl.id_estado
JOIN creditos cr ON cr.id_cliente = cl.id_cliente AND cr.borrado_logico = 0
JOIN cuotas cu   ON cu.id_credito = cr.id_credito AND cu.borrado_logico = 0
WHERE cl.borrado_logico = 0
  AND ec.codigo = 'Moroso'
GROUP BY cl.id_cliente, cliente, ec.codigo
ORDER BY deuda DESC;

-- Q14. Eficacia de campañas (ratio creditos / captados)
SELECT
  cp.id_campania, cp.nombre,
  cp.clientes_captados AS captados,
  COUNT(DISTINCT cr.id_credito) AS creditos,
  ROUND(100 * COUNT(DISTINCT cr.id_credito) / NULLIF(cp.clientes_captados,0), 2) AS ratio_pct
FROM campanias_promocionales cp
LEFT JOIN clientes cl ON cl.id_campania_ingreso = cp.id_campania AND cl.borrado_logico = 0
LEFT JOIN creditos cr ON cr.id_cliente = cl.id_cliente AND cr.borrado_logico = 0
WHERE cp.borrado_logico = 0
GROUP BY cp.id_campania, cp.nombre, cp.clientes_captados
ORDER BY ratio_pct DESC;

-- Q15. Sucursales con mayor monto vencido – TOP 3 (ya sin LIMIT)
WITH vencido AS (
  SELECT
    s.id_sucursal, s.nombre AS sucursal,
    ROUND(SUM(CASE WHEN cu.id_estado=@id_cuo_venc
              THEN (cu.monto_cuota - COALESCE(cu.monto_pagado,0)) ELSE 0 END),2) AS monto_vencido
  FROM sucursales s
  JOIN solicitudes_credito sc ON sc.id_sucursal = s.id_sucursal AND sc.borrado_logico = 0
  JOIN creditos c             ON c.id_solicitud = sc.id_solicitud AND c.borrado_logico = 0
  JOIN cuotas cu              ON cu.id_credito  = c.id_credito   AND cu.borrado_logico = 0
  WHERE s.borrado_logico = 0
  GROUP BY s.id_sucursal, s.nombre
)
SELECT *
FROM (
  SELECT v.*,
         DENSE_RANK() OVER (ORDER BY v.monto_vencido DESC) AS rk
  FROM vencido v
) t
WHERE rk <= 3
ORDER BY rk;

-- Q16. Cambios de tasa ultimos 12 meses (no solapadas)
WITH mov AS (
  SELECT
    h.id_producto,
    h.vigente_desde,
    h.vigente_hasta,
    h.tasa_nueva,
    LAG(h.tasa_nueva) OVER (PARTITION BY h.id_producto ORDER BY h.vigente_desde) AS tasa_prev
  FROM historico_tasas h
  WHERE h.borrado_logico = 0
    AND h.vigente_desde >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
),
mov_calc AS (
  SELECT
    id_producto,
    MIN(vigente_desde) AS primer_cambio,
    MAX(COALESCE(vigente_hasta, CURDATE())) AS ultimo_fin_vigencia,
    COUNT(*) AS cambios_12m,
    SUM(ABS(tasa_nueva - COALESCE(tasa_prev, tasa_nueva))) AS magnitud_total,
    MAX(vigente_desde) AS fecha_ultimo_cambio
  FROM mov
  GROUP BY id_producto
),
ultimo_delta AS (
  SELECT m.id_producto,
         (m.tasa_nueva - COALESCE(m.tasa_prev, m.tasa_nueva)) AS delta_ultimo
  FROM mov m
  JOIN (SELECT id_producto, MAX(vigente_desde) mx FROM mov GROUP BY id_producto) u
    ON u.id_producto = m.id_producto AND u.mx = m.vigente_desde
)
SELECT
  p.id_producto,
  p.nombre,
  COALESCE(mc.cambios_12m, 0) AS cambios_12m,
  DATE_FORMAT(mc.primer_cambio, '%Y-%m-%d') AS desde,
  DATE_FORMAT(mc.fecha_ultimo_cambio, '%Y-%m-%d') AS hasta,
  p.tasa_base AS tasa_base_anual,
  fn_tasa_vigente(p.id_producto, CURDATE()) AS tasa_vigente_hoy,
  ROUND(fn_tasa_vigente(p.id_producto, CURDATE()) - p.tasa_base, 3) AS delta_vs_base,
  ROUND(COALESCE(ud.delta_ultimo, 0), 3) AS delta_ultimo_cambio,
  ROUND(COALESCE(mc.magnitud_total, 0), 3) AS magnitud_total_cambios
FROM productos_financieros p
LEFT JOIN mov_calc mc     ON mc.id_producto = p.id_producto
LEFT JOIN ultimo_delta ud ON ud.id_producto = p.id_producto
WHERE p.borrado_logico = 0
ORDER BY cambios_12m DESC, p.id_producto;

-- Q17. Ingresos estimados por intereses (mes actual)
SELECT
  DATE_FORMAT(CURDATE(), '%Y-%m') AS periodo,
  ROUND(SUM(cu.monto_interes), 2) AS intereses_mes
FROM cuotas cu
WHERE cu.borrado_logico = 0
  AND YEAR(cu.fecha_vencimiento) = YEAR(CURDATE())
  AND MONTH(cu.fecha_vencimiento) = MONTH(CURDATE());

-- Q18. Distribucion de plazos
SELECT
  c.plazo_meses,
  COUNT(*) AS creditos
FROM creditos c
WHERE c.borrado_logico = 0
GROUP BY c.plazo_meses
ORDER BY c.plazo_meses;

-- Q19. Sucursales con mayor volumen otorgado – Top 15 (sin LIMIT)
WITH tot AS (
  SELECT
    s.id_sucursal, s.nombre,
    ROUND(SUM(c.monto_otorgado),2) AS total_otorgado
  FROM sucursales s
  JOIN solicitudes_credito sc ON sc.id_sucursal = s.id_sucursal AND sc.borrado_logico=0
  JOIN creditos c ON c.id_solicitud = sc.id_solicitud AND c.borrado_logico=0
  WHERE s.borrado_logico = 0
  GROUP BY s.id_sucursal, s.nombre
)
SELECT t1.*
FROM tot t1
WHERE (
  SELECT COUNT(*)
  FROM tot t2
  WHERE t2.total_otorgado > t1.total_otorgado
     OR (t2.total_otorgado = t1.total_otorgado AND t2.id_sucursal < t1.id_sucursal)
) < 15
ORDER BY t1.total_otorgado DESC, t1.id_sucursal;

-- Q20. Metodologias de pago mas usadas
SELECT
  mp.codigo AS metodo_pago,
  COUNT(*) AS cant
FROM pagos p
JOIN metodo_pago mp ON mp.id=p.id_metodo
WHERE p.borrado_logico = 0
GROUP BY mp.codigo
ORDER BY cant DESC;



-- CONSULTAS DE MARKETING (22–30)


-- Q21. Conversion por canal (global y 90 dias)
SELECT
  canal,
  COUNT(*)                                 AS contactos,
  SUM(resultado='Convirtio')               AS conversiones,
  ROUND(100*SUM(resultado='Convirtio')/NULLIF(COUNT(*),0),2) AS conv_rate_pct,
  SUM(CASE WHEN fecha_contacto>=DATE_SUB(CURDATE(), INTERVAL 90 DAY) THEN 1 ELSE 0 END) AS contactos_90d,
  SUM(CASE WHEN resultado='Convirtio' AND fecha_contacto>=DATE_SUB(CURDATE(), INTERVAL 90 DAY) THEN 1 ELSE 0 END) AS conv_90d
FROM campanias_clientes
GROUP BY canal
ORDER BY conv_rate_pct DESC, contactos DESC;

-- Q22. Funnel por campaña (contactos → clientes unicos → conversiones)
SELECT
  cp.id_campania,
  cp.nombre,
  COUNT(cc.id_cliente)                            AS contactos,
  COUNT(DISTINCT cc.id_cliente)                   AS clientes_contactados,
  SUM(cc.resultado='Convirtio')                   AS conversiones,
  ROUND(100*SUM(cc.resultado='Convirtio')/NULLIF(COUNT(DISTINCT cc.id_cliente),0),2) AS conv_rate_pct
FROM campanias_promocionales cp
LEFT JOIN campanias_clientes cc ON cc.id_campania=cp.id_campania
WHERE cp.borrado_logico=0
GROUP BY cp.id_campania, cp.nombre
ORDER BY conversiones DESC;

-- Q23. ROAS y CPA por campaña (ingreso proxy = monto_otorgado atribuido)
SELECT
  cp.id_campania,
  cp.nombre,
  cp.inversion_realizada,
  COUNT(DISTINCT cl.id_cliente)                         AS clientes_atribuidos,
  COUNT(DISTINCT cr.id_credito)                         AS creditos_atribuidos,
  ROUND(SUM(COALESCE(cr.monto_otorgado,0)),2)           AS ingreso_atr,
  ROUND( CASE WHEN cp.inversion_realizada>0
        THEN SUM(COALESCE(cr.monto_otorgado,0))/cp.inversion_realizada ELSE NULL END ,3) AS roas,
  ROUND( CASE WHEN (COUNT(DISTINCT cl.id_cliente))>0
        THEN cp.inversion_realizada/COUNT(DISTINCT cl.id_cliente) ELSE NULL END ,2) AS cpa_cli
FROM campanias_promocionales cp
LEFT JOIN clientes cl ON cl.id_campania_ingreso=cp.id_campania AND cl.borrado_logico=0
LEFT JOIN creditos cr ON cr.id_cliente=cl.id_cliente AND cr.borrado_logico=0
WHERE cp.borrado_logico=0
GROUP BY cp.id_campania, cp.nombre, cp.inversion_realizada
ORDER BY roas DESC, ingreso_atr DESC;

-- Q24. Atribucion "ultimo toque" (campanias_clientes)
WITH ult AS (
  SELECT
    id_cliente,
    SUBSTRING_INDEX(
      SUBSTRING_INDEX(GROUP_CONCAT(CONCAT(id_campania,'|',fecha_contacto) ORDER BY fecha_contacto SEPARATOR ','), ',', -1),
      '|', 1
    ) AS id_campania_ult
  FROM campanias_clientes
  WHERE resultado='Convirtio'
  GROUP BY id_cliente
)
SELECT
  cp.id_campania,
  cp.nombre,
  COUNT(DISTINCT u.id_cliente)                         AS clientes_last_touch,
  COUNT(DISTINCT cr.id_credito)                        AS creditos_last_touch,
  ROUND(SUM(COALESCE(cr.monto_otorgado,0)),2)          AS monto_otorgado_last_touch
FROM ult u
JOIN campanias_promocionales cp ON cp.id_campania = u.id_campania_ult
LEFT JOIN creditos cr ON cr.id_cliente = u.id_cliente AND cr.borrado_logico=0
GROUP BY cp.id_campania, cp.nombre
ORDER BY monto_otorgado_last_touch DESC;

-- Q25. Serie mensual de conversiones por canal
SELECT
  DATE_FORMAT(fecha_contacto,'%Y-%m') AS yymm,
  canal,
  SUM(resultado='Convirtio') AS conversiones
FROM campanias_clientes
GROUP BY yymm, canal
ORDER BY yymm DESC, conversiones DESC;

-- Q26. Prospectos para retargeting (≥2 contactos 90d sin conversion) – Top 200
WITH params AS (
  SELECT COALESCE(MAX(fecha_contacto), CURDATE()) base_ref FROM campanias_clientes
),
base AS (
  SELECT
    c.id_cliente,
    COUNT(*)                     AS contactos_90d,
    SUM(c.resultado='Convirtio') AS convs_90d,
    MAX(c.fecha_contacto)        AS ultima_interaccion,
    COUNT(DISTINCT c.canal)      AS canales_distintos
  FROM campanias_clientes c
  CROSS JOIN params p
  WHERE c.borrado_logico = 0
    AND c.fecha_contacto >= DATE_SUB(p.base_ref, INTERVAL 90 DAY)
  GROUP BY c.id_cliente
)
SELECT *
FROM base
ORDER BY convs_90d DESC, contactos_90d DESC;


-- Q27. Tasa de aprobacion por analista
SELECT
  e.id_empleado,
  CONCAT(e.nombre,' ',e.apellido) AS analista,
  COUNT(*) AS total_eval,
  SUM(sc.id_estado=@id_sol_aprb) AS aprobadas,
  ROUND(100*SUM(sc.id_estado=@id_sol_aprb)/NULLIF(COUNT(*),0),2) AS tasa_aprob_pct
FROM empleados e
JOIN cargo_empleado ce ON ce.id=e.id_cargo AND ce.codigo='Analista_Credito'
LEFT JOIN solicitudes_credito sc ON sc.id_analista=e.id_empleado AND sc.borrado_logico=0
WHERE e.borrado_logico=0
GROUP BY e.id_empleado, analista
HAVING total_eval>0
ORDER BY tasa_aprob_pct DESC, aprobadas DESC;

-- Q28. Cohorte por mes de solicitud → tasa de aprobacion
SELECT
  DATE_FORMAT(sc.fecha_solicitud,'%Y-%m') AS cohorte,
  COUNT(*) AS solicitudes,
  SUM(sc.id_estado=@id_sol_aprb) AS aprobadas,
  ROUND(100*SUM(sc.id_estado=@id_sol_aprb)/NULLIF(COUNT(*),0),2) AS tasa_aprob_pct
FROM solicitudes_credito sc
WHERE sc.borrado_logico=0
GROUP BY cohorte
ORDER BY cohorte DESC;

-- Q29. Correlacion simple: inversion vs creditos atribuidos
SELECT
  cp.id_campania,
  cp.nombre,
  cp.inversion_realizada,
  COUNT(DISTINCT cr.id_credito) AS creditos
FROM campanias_promocionales cp
LEFT JOIN clientes cl ON cl.id_campania_ingreso=cp.id_campania AND cl.borrado_logico=0
LEFT JOIN creditos cr ON cr.id_cliente=cl.id_cliente AND cr.borrado_logico=0
GROUP BY cp.id_campania, cp.nombre, cp.inversion_realizada
ORDER BY cp.inversion_realizada DESC;



-- VISTAS (SQL SECURITY INVOKER)

-- V1. Cartera de cobranza
DROP VIEW IF EXISTS vw_cartera_cobranza;
CREATE ALGORITHM=MERGE SQL SECURITY INVOKER VIEW vw_cartera_cobranza AS
SELECT
  cu.id_cuota,
  cu.id_credito,
  cl.id_cliente,
  CONCAT(cl.nombre,' ',cl.apellido) AS cliente,
  cu.fecha_vencimiento,
  cu.monto_cuota,
  COALESCE(cu.monto_pagado,0) AS monto_pagado,
  (cu.monto_cuota - COALESCE(cu.monto_pagado,0)) AS saldo,
  ecu.codigo AS estado_cuota
FROM cuotas cu
JOIN estado_cuota ecu ON ecu.id=cu.id_estado
JOIN creditos cr ON cr.id_credito = cu.id_credito AND cr.borrado_logico=0
JOIN clientes cl ON cl.id_cliente = cr.id_cliente AND cl.borrado_logico=0
WHERE cu.borrado_logico = 0;

-- V2. Bandeja de solicitudes para analista
DROP VIEW IF EXISTS vw_solicitudes_analista;
CREATE ALGORITHM=MERGE SQL SECURITY INVOKER VIEW vw_solicitudes_analista AS
SELECT
  sc.id_solicitud,
  sc.id_cliente,
  CONCAT(cl.nombre,' ',cl.apellido) AS cliente,
  sc.id_producto,
  pf.nombre AS producto,
  sc.monto_solicitado,
  sc.plazo_meses,
  es.codigo AS estado_solicitud,
  sc.puntaje_riesgo,
  sc.id_analista,
  sc.fecha_solicitud,
  sc.fecha_evaluacion
FROM solicitudes_credito sc
JOIN clientes cl ON cl.id_cliente = sc.id_cliente AND cl.borrado_logico=0
JOIN productos_financieros pf ON pf.id_producto = sc.id_producto AND pf.borrado_logico=0
JOIN estado_solicitud es ON es.id=sc.id_estado
WHERE sc.borrado_logico = 0;

-- V3. Avance por credito
DROP VIEW IF EXISTS vw_creditos_avance;
CREATE ALGORITHM=MERGE SQL SECURITY INVOKER VIEW vw_creditos_avance AS
SELECT
  c.id_credito,
  c.id_cliente,
  CONCAT(cl.nombre,' ',cl.apellido) AS cliente,
  c.id_producto,
  pf.nombre AS producto,
  ec.codigo AS estado_credito,
  SUM(CASE WHEN COALESCE(cu.monto_pagado,0) >= cu.monto_cuota THEN 1 ELSE 0 END) AS cuotas_pagadas,
  COUNT(*) AS cuotas_totales,
  ROUND(100 * SUM(CASE WHEN COALESCE(cu.monto_pagado,0) >= cu.monto_cuota THEN 1 ELSE 0 END) / COUNT(*), 2) AS avance_pct
FROM creditos c
JOIN estado_credito  ec  ON ec.id = c.id_estado
JOIN clientes            cl  ON cl.id_cliente = c.id_cliente  AND cl.borrado_logico = 0
JOIN productos_financieros pf ON pf.id_producto = c.id_producto AND pf.borrado_logico = 0
JOIN cuotas              cu  ON cu.id_credito = c.id_credito  AND cu.borrado_logico = 0
WHERE c.borrado_logico = 0
GROUP BY c.id_credito, c.id_cliente, cliente, c.id_producto, producto, ec.codigo;

-- V4. KPIs de campañas (funnel, ROAS, CPA)
DROP VIEW IF EXISTS vw_kpi_campanias;
CREATE ALGORITHM=MERGE SQL SECURITY INVOKER VIEW vw_kpi_campanias AS
SELECT
  cp.id_campania,
  cp.nombre,
  cp.presupuesto,
  cp.inversion_realizada,
  cp.clientes_captados,
  COALESCE(cstats.contactos,0)            AS contactos,
  COALESCE(cstats.clientes_contactados,0) AS clientes_contactados,
  COALESCE(cstats.conversiones,0)         AS conversiones,
  COALESCE(ast.creditos,0)                AS creditos_atribuidos,
  COALESCE(ast.monto_otorgado,0)          AS monto_otorgado_atr,
  ROUND(100*COALESCE(cstats.conversiones,0)/NULLIF(cstats.clientes_contactados,0),2) AS conv_rate_pct,
  ROUND(CASE WHEN cp.inversion_realizada>0 THEN COALESCE(ast.monto_otorgado,0)/cp.inversion_realizada END,3) AS roas,
  ROUND(CASE WHEN COALESCE(cstats.conversiones,0)>0 THEN cp.inversion_realizada/COALESCE(cstats.conversiones,0) END,2) AS cpa_conv
FROM campanias_promocionales cp
LEFT JOIN (
  SELECT id_campania,
         COUNT(*) AS contactos,
         COUNT(DISTINCT id_cliente) AS clientes_contactados,
         SUM(resultado='Convirtio') AS conversiones
  FROM campanias_clientes
  GROUP BY id_campania
) cstats ON cstats.id_campania=cp.id_campania
LEFT JOIN (
  SELECT cl.id_campania_ingreso AS id_campania,
         COUNT(DISTINCT cr.id_credito) AS creditos,
         SUM(COALESCE(cr.monto_otorgado,0)) AS monto_otorgado
  FROM clientes cl
  LEFT JOIN creditos cr ON cr.id_cliente=cl.id_cliente AND cr.borrado_logico=0
  WHERE cl.id_campania_ingreso IS NOT NULL AND cl.borrado_logico=0
  GROUP BY cl.id_campania_ingreso
) ast ON ast.id_campania=cp.id_campania
WHERE cp.borrado_logico=0;

-- V5. Atribucion Last Touch
DROP VIEW IF EXISTS vw_atribucion_ultimo_toque;
CREATE ALGORITHM=MERGE SQL SECURITY INVOKER VIEW vw_atribucion_ultimo_toque AS
WITH ult AS (
  SELECT
    id_cliente,
    CAST(SUBSTRING_INDEX(
      SUBSTRING_INDEX(GROUP_CONCAT(CONCAT(id_campania,'|',fecha_contacto) ORDER BY fecha_contacto SEPARATOR ','), ',', -1),
      '|', 1
    ) AS SIGNED) AS id_campania
  FROM campanias_clientes
  WHERE resultado='Convirtio'
  GROUP BY id_cliente
)
SELECT
  cp.id_campania,
  cp.nombre,
  u.id_cliente,
  COUNT(DISTINCT cr.id_credito) AS creditos,
  ROUND(SUM(COALESCE(cr.monto_otorgado,0)),2) AS monto_otorgado
FROM ult u
JOIN campanias_promocionales cp ON cp.id_campania=u.id_campania
LEFT JOIN creditos cr ON cr.id_cliente=u.id_cliente AND cr.borrado_logico=0
GROUP BY cp.id_campania, cp.nombre, u.id_cliente;



-- Permisos
GRANT SELECT ON gestion_creditos.vw_cartera_cobranza        TO 'gc_cobranza'@'localhost';
GRANT SELECT ON gestion_creditos.vw_solicitudes_analista    TO 'gc_analista'@'localhost';
GRANT SELECT ON gestion_creditos.vw_creditos_avance         TO 'gc_admin'@'localhost';
GRANT SELECT ON gestion_creditos.vw_kpi_campanias           TO 'gc_marketing'@'localhost';
GRANT SELECT ON gestion_creditos.vw_atribucion_ultimo_toque TO 'gc_marketing'@'localhost';

FLUSH PRIVILEGES;


-- Transacciones (T1–T2)

-- T1. Refinanciacion segura (envuelve reglas + genera nuevas cuotas)
DROP PROCEDURE IF EXISTS sp_tx_refinanciar_si_mora;
DELIMITER $$
CREATE PROCEDURE sp_tx_refinanciar_si_mora(
  IN p_id_credito INT,
  IN p_nuevo_monto DECIMAL(14,2),
  IN p_nuevo_plazo INT,
  IN p_nueva_tasa DECIMAL(7,3)
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Transaccion revertida por excepcion en refinanciacion';
  END;

  START TRANSACTION;

    IF NOT EXISTS (
        SELECT 1 FROM creditos
        WHERE id_credito = p_id_credito
          AND borrado_logico = 0
          AND id_estado IN (@id_cre_act,@id_cre_mor)
    ) THEN
      ROLLBACK;
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Credito no valido para refinanciacion';
    END IF;

    CALL sp_refinanciar_credito(p_id_credito, p_nuevo_monto, p_nuevo_plazo, p_nueva_tasa);

  COMMIT;
END$$
DELIMITER ;

-- T2. Registrar contacto de campaña (y consolidar conversion)
DROP PROCEDURE IF EXISTS sp_tx_registrar_contacto_campania;
DELIMITER $$
CREATE PROCEDURE sp_tx_registrar_contacto_campania(
  IN p_id_campania INT,
  IN p_id_cliente  INT,
  IN p_canal       VARCHAR(50),
  IN p_resultado   VARCHAR(20),
  IN p_fecha       DATETIME
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT='Error registrando contacto de campaña';
  END;

  START TRANSACTION;

    -- 1) Registrar contacto
    INSERT INTO campanias_clientes(
      id_campania, id_cliente, canal, resultado, fecha_contacto
    )
    VALUES (p_id_campania, p_id_cliente, p_canal, p_resultado, p_fecha);

    -- 2) Si convirtio y el cliente aun no tiene campaña de ingreso → setearla
    IF p_resultado = 'Convirtio'
       AND (SELECT id_campania_ingreso
            FROM clientes
            WHERE id_cliente = p_id_cliente
              AND borrado_logico = 0) IS NULL THEN

      UPDATE clientes
      SET id_campania_ingreso = p_id_campania
      WHERE id_cliente = p_id_cliente
        AND borrado_logico = 0;
    END IF;

    -- 3) Recalcular clientes_captados solo con clientes vivos (borrado_logico = 0)
    UPDATE campanias_promocionales cp
    LEFT JOIN (
      SELECT id_campania_ingreso AS id_campania,
             COUNT(*) AS captados
      FROM clientes
      WHERE id_campania_ingreso IS NOT NULL
        AND borrado_logico = 0
      GROUP BY id_campania_ingreso
    ) x ON x.id_campania = cp.id_campania
    SET cp.clientes_captados = COALESCE(x.captados,0)
    WHERE cp.id_campania = p_id_campania;

  COMMIT;
END$$
DELIMITER ;
