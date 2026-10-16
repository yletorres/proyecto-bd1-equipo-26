-- =============================================================================
-- Cátedra: Bases de Datos I - Lic. en Sistemas de Información (FaCENA - UNNE)
-- Proyecto: Venus Spa - Etapa IV (Consultas y Casos de Uso)
-- Archivo: consultas_venus_spa.sql
-- Motor: Microsoft SQL Server (Transact-SQL)
-- =============================================================================
 
USE Venus_Spa;
GO
 
-- =============================================================================
-- EJEMPLO 1: FACTURA / COMPROBANTE DE VENTA
-- Se consulta la venta con id_venta = 1 (cambiar el número para ver otras).
-- =============================================================================
 
-- -----------------------------------------------------------------------------
-- 1.1 Factura - Encabezado
-- Datos generales de la venta: número, fecha, cliente y método de pago.
-- (El modelo no registra vendedor: según la RN.08 la venta solo se asocia
-- al cliente y a los productos que contiene.)
-- -----------------------------------------------------------------------------
SELECT
    v.id_venta           AS nro_factura,
    v.fecha_venta        AS fecha,
    p.nombre_completo    AS cliente,
    v.metodo_pago_venta  AS metodo_pago
FROM venta v
JOIN cliente cl ON cl.dni_cliente = v.dni_cliente
JOIN persona p  ON p.dni_persona  = cl.dni_cliente
WHERE v.id_venta = 1;
GO
 
-- -----------------------------------------------------------------------------
-- 1.2 Factura - Detalle
-- Productos vendidos, cantidades, precios y subtotal por renglón.
-- Se usa el precio de "contiene" (precio histórico, RN.05) y no el vigente.
-- -----------------------------------------------------------------------------
SELECT
    pr.nombre_producto     AS producto,
    c.cantidad,
    c.precio               AS precio_unitario,
    c.cantidad * c.precio  AS subtotal
FROM contiene c
JOIN producto pr ON pr.id_producto = c.id_producto
WHERE c.id_venta = 1;
GO
 
-- -----------------------------------------------------------------------------
-- 1.3 Factura - Total acumulado de la venta
-- -----------------------------------------------------------------------------
SELECT
    c.id_venta,
    SUM(c.cantidad * c.precio) AS total_venta
FROM contiene c
WHERE c.id_venta = 1
GROUP BY c.id_venta;
GO
 
---------------------------------------------------------------------------------
-- 2 Reportes Agregados -
---------------------------------------------------------------------------------


---------------------------------------------------------------
--Reporte Agregado de Productos más vendidos
--Productos que mas se venden más en el mes
--Realizada por el dueño
---------------------------------------------------------------
SELECT
    p.id_producto,
    p.nombre_producto,
    SUM(c.cantidad) AS unidades_vendidas,
    SUM(c.cantidad * c.precio) AS total_recaudado
FROM producto p
JOIN contiene c ON c.id_producto = p.id_producto
JOIN venta v ON v.id_venta = c.id_venta
GROUP BY
    p.id_producto,
    p.nombre_producto
ORDER BY
    unidades_vendidas DESC;
GO
-- =============================================================================
-- 3. CONSULTA DE NEGOCIO AVANZADA
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 3.1 Profesional del mes
-- El dueño necesita identificar al profesional con más turnos
-- realizados en septiembre de 2026 para reconocer su trabajo.
-- Se relacionan cuatro tablas y se utiliza una subconsulta
-- con HAVING para obtener al profesional con más turnos.
-- En caso de empate, se muestran todos los profesionales
-- -----------------------------------------------------------------------------

SELECT
    persona.nombre_completo AS profesional,
    COUNT(*) AS turnos_realizados
FROM persona
JOIN profesional
    ON profesional.dni_profesional = persona.dni_persona
JOIN se_asigna_turno
    ON se_asigna_turno.dni_profesional = profesional.dni_profesional
JOIN turno
    ON turno.id_turno = se_asigna_turno.id_turno
WHERE turno.estado = 'realizado'
    AND turno.fecha_turno >= '2026-09-01'
    AND turno.fecha_turno < '2026-10-01'
GROUP BY
    persona.dni_persona,
    persona.nombre_completo
HAVING COUNT(*) = (
    SELECT TOP (1)
        COUNT(*)
    FROM se_asigna_turno
    JOIN turno
        ON turno.id_turno = se_asigna_turno.id_turno
    WHERE turno.estado = 'realizado'
        AND turno.fecha_turno >= '2026-09-01'
        AND turno.fecha_turno < '2026-10-01'
    GROUP BY se_asigna_turno.dni_profesional
    ORDER BY COUNT(*) DESC
)
ORDER BY
    persona.nombre_completo;
GO
