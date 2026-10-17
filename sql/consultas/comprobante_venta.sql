-- =============================================================================
-- Cátedra: Bases de Datos I - Lic. en Sistemas de Información (FaCENA - UNNE)
-- Proyecto: Venus Spa - Etapa IV (Consultas y Casos de Uso)
-- Archivo: comprobante_venta.sql
-- Comprobante de venta (factura)
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
