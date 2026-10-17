-- =============================================================================
-- Cátedra: Bases de Datos I - Lic. en Sistemas de Información (FaCENA - UNNE)
-- Proyecto: Venus Spa - Etapa IV (Consultas y Casos de Uso)
-- Archivo: consulta_avanzada.sql
-- Consultas avanzadas y casos de uso
-- Motor: Microsoft SQL Server (Transact-SQL)
-- =============================================================================

USE Venus_Spa;
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

-- -----------------------------------------------------------------------------
-- 3.3 Clientes frecuentes
-- El dueño quiere ver a los clientes que más vienen al spa (al menos 4 turnos
-- realizados y más de $60.000 gastados) para darles un descuento por fidelidad.
-- Se relacionan las tablas persona, cliente y turno.
-- Se agrupa por cliente y se usa HAVING para filtrar por cantidad y gasto.
-- -----------------------------------------------------------------------------

SELECT
    p.dni_persona            AS dni,
    p.nombre_completo        AS cliente,
    p.telefono_persona       AS telefono,
    COUNT(t.id_turno)        AS turnos_realizados,
    SUM(t.precio_historico)  AS total_gastado,
    MAX(t.fecha_turno)       AS ultimo_turno
FROM persona p
JOIN cliente c
    ON c.dni_cliente = p.dni_persona
JOIN turno t
    ON t.dni_cliente = c.dni_cliente
WHERE t.estado = 'realizado'
GROUP BY
    p.dni_persona,
    p.nombre_completo,
    p.telefono_persona
HAVING COUNT(t.id_turno) >= 4
    AND SUM(t.precio_historico) >= 60000.00
ORDER BY
    total_gastado DESC;
GO

-- -----------------------------------------------------------------------------
-- 3.4 Servicio con mayor recaudación
-- El dueño quiere identificar el servicio que más dinero generó con turnos
-- realizados, para planificar la compra de insumos y disponibilidad de camillas.
-- Se relacionan las tablas servicio, turno y camilla.
-- Se agrupa por servicio y se usa una subconsulta con HAVING para traer el
-- servicio con más ingresos (y contempla empates si los hubiera).
-- -----------------------------------------------------------------------------

SELECT
    s.id_servicio,
    s.denominacion           AS servicio,
    COUNT(t.id_turno)        AS turnos_realizados,
    SUM(t.precio_historico)  AS total_recaudado
FROM servicio s
JOIN turno t
    ON s.id_servicio = t.id_servicio
JOIN camilla c
    ON c.id_camilla = t.id_camilla
WHERE t.estado = 'realizado'
GROUP BY
    s.id_servicio,
    s.denominacion
HAVING SUM(t.precio_historico) = (
    SELECT TOP (1)
        SUM(t2.precio_historico)
    FROM turno t2
    WHERE t2.estado = 'realizado'
    GROUP BY t2.id_servicio
    ORDER BY SUM(t2.precio_historico) DESC
)
ORDER BY
    total_recaudado DESC;
GO

-- ============================================================================
-- CASO DE USO 4: Detección de Camillas Libres
-- Camillas libres para asignación de turnos
-- La recepcionista necesita identificar las camillas físicas que se
-- encuentran disponibles en una fecha y franja horaria específicas.
-- Esto permite asignar nuevos turnos evitando la superposición de recursos.
-- Se relacionan dos tablas (camilla y turno) y se utiliza una subconsulta 
-- anidada con NOT IN para filtrar las camillas ocupadas en dicho horario.
-- ============================================================================
DECLARE @fecha_consulta DATE = '2026-10-20';
DECLARE @franja_consulta TIME(0) = '10:00:00';

SELECT 
    c.id_camilla,
    c.nombre AS nombre_camilla_disponible
FROM camilla c
WHERE c.id_camilla NOT IN (
    SELECT t.id_camilla
    FROM turno t
    WHERE t.fecha_turno = @fecha_consulta
      AND t.franja_horaria = @franja_consulta
      AND t.estado IN ('pendiente', 'confirmado', 'realizado')
);
GO

-- ----------------------------------------------------------------------------
-- CASO DE USO 4.1: Precio con 10% de descuento para los 3 productos menos vendidos
-- Promoción para productos de baja rotación
-- El área de administración necesita identificar los 3 productos con menor
-- cantidad de unidades vendidas dentro de un período de tiempo determinado
-- y ver cuál sería su precio con un 10% de descuento como estrategia de
-- rotación de stock. La consulta solo muestra los precios, no modifica datos.
-- Se relacionan tres tablas (producto, contiene y venta) mediante LEFT JOIN
-- e ISNULL para incluir productos sin ventas, agrupadas con GROUP BY.
-- Solo se suman las unidades de las ventas que caen dentro del período (CASE).
-- En caso de empate, se ordena por nombre para que el resultado sea siempre el mismo.
-- ----------------------------------------------------------------------------
DECLARE @fecha_inicio DATE = '2026-09-01';
DECLARE @fecha_fin DATE = '2026-09-30';

SELECT TOP 3
    p.id_producto,
    p.nombre_producto,
    p.precio_vigente AS precio_original,
    CAST(p.precio_vigente * 0.90 AS DECIMAL(10,2)) AS precio_con_descuento,
    ISNULL(SUM(CASE WHEN v.id_venta IS NOT NULL THEN c.cantidad END), 0) AS unidades_vendidas
FROM producto p
LEFT JOIN contiene c ON p.id_producto = c.id_producto
LEFT JOIN venta v ON c.id_venta = v.id_venta AND v.fecha_venta BETWEEN @fecha_inicio AND @fecha_fin
GROUP BY p.id_producto, p.nombre_producto, p.precio_vigente
ORDER BY unidades_vendidas ASC, p.nombre_producto;
GO
