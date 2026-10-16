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

---------------------------------------------------------------
--Reporte Agregado de los 3 Productos más vendidos del mes
--Top 3 de productos con más unidades vendidas en el mes actual
--(en caso de empate en el tercer puesto se muestran todos los empatados)
--Realizada por el dueño
---------------------------------------------------------------
SELECT TOP 3 WITH TIES
    p.id_producto,
    p.nombre_producto,
    SUM(c.cantidad) AS unidades_vendidas,
    SUM(c.cantidad * c.precio) AS total_recaudado
FROM producto p
JOIN contiene c ON c.id_producto = p.id_producto
JOIN venta v ON v.id_venta = c.id_venta
WHERE MONTH(v.fecha_venta) = MONTH(GETDATE())
  AND YEAR(v.fecha_venta)  = YEAR(GETDATE())
GROUP BY
    p.id_producto,
    p.nombre_producto
ORDER BY
    unidades_vendidas DESC;
GO

---------------------------------------------------------------
--Reporte Agregado de Clientes Inactivos
--Reporte de los clientes que no tienen turnos de hace mas de 6 meses
--Realizada por el dueño
---------------------------------------------------------------
SELECT
    c.dni_cliente,
    p.nombre_completo,
    MAX(t.fecha_turno) AS ultimo_turno
FROM cliente AS c
JOIN persona AS p
    ON c.dni_cliente = p.dni_persona
LEFT JOIN turno AS t
    ON c.dni_cliente = t.dni_cliente
GROUP BY
    c.dni_cliente,
    p.nombre_completo
HAVING
    MAX(t.fecha_turno) < DATEADD(MONTH, -6, GETDATE());
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

-- -----------------------------------------------------------------------------
-- 3.2 Cumpleañeros del mes
-- La recepcionista necesita identificar a los clientes que cumplen
-- años durante el mes actual y que hayan realizado compras.
-- Esto permite ofrecerles descuentos como estrategia de fidelización.
-- Se relacionan tres tablas y se utiliza HAVING para filtrar
-- a los clientes que realizaron al menos una compra.
-- -----------------------------------------------------------------------------

SELECT
    persona.nombre_completo AS cliente,
    persona.telefono_persona AS telefono,
    cliente.fecha_nacimiento AS fecha_nacimiento,
    COUNT(venta.id_venta) AS cantidad_compras,
    MAX(venta.fecha_venta) AS ultima_compra
FROM persona
JOIN cliente
    ON persona.dni_persona = cliente.dni_cliente
LEFT JOIN venta
    ON venta.dni_cliente = cliente.dni_cliente
WHERE MONTH(cliente.fecha_nacimiento) = MONTH(GETDATE())
GROUP BY
    persona.dni_persona,
    persona.nombre_completo,
    persona.telefono_persona,
    cliente.fecha_nacimiento
HAVING COUNT(venta.id_venta) >= 1
ORDER BY
    DAY(cliente.fecha_nacimiento);
GO
