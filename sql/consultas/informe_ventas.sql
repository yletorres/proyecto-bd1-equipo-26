-- =============================================================================
-- Cátedra: Bases de Datos I - Lic. en Sistemas de Información (FaCENA - UNNE)
-- Proyecto: Venus Spa - Etapa IV (Consultas y Casos de Uso)
-- Archivo: informe_ventas.sql
-- Reportes agregados: productos más vendidos y clientes inactivos
-- Motor: Microsoft SQL Server (Transact-SQL)
-- =============================================================================

USE Venus_Spa;
GO

---------------------------------------------------------------------------------
-- 2 Reportes Agregados -
---------------------------------------------------------------------------------

---------------------------------------------------------------
--Reporte Agregado de Productos más vendidos
--Ranking general de productos con más unidades vendidas
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
--Reporte de los clientes que no tienen turnos hace más de 6 meses
--(incluye a los clientes que nunca sacaron un turno)
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
    MAX(t.fecha_turno) IS NULL
    OR MAX(t.fecha_turno) < DATEADD(MONTH, -6, GETDATE())
ORDER BY ultimo_turno;
GO
