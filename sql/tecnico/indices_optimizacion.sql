
-- =============================================================================
-- Cátedra: Bases de Datos I - Lic. en Sistemas de Información (FaCENA - UNNE)
-- Proyecto: Venus Spa - Etapa V
-- Tema 5: Optimización de consultas mediante índices
-- Archivo: indices_optimizacion.sql
-- Motor: Microsoft SQL Server (Transact-SQL)
-- =============================================================================

USE Venus_Spa;
GO

-- =============================================================================
-- 1. CREACIÓN DE TABLA PARA PRUEBAS DE RENDIMIENTO
-- Se utiliza una tabla independiente para no modificar las ventas originales.
-- Se crea sin índices para comparar posteriormente el rendimiento.
-- =============================================================================

IF OBJECT_ID('dbo.venta_prueba_indices', 'U') IS NULL
BEGIN
    CREATE TABLE venta_prueba_indices (
        id_venta BIGINT IDENTITY(1,1) NOT NULL,
        fecha_venta DATE NOT NULL,
        importe DECIMAL(12,2) NOT NULL
    );
END;
GO

-- Verificar que la tabla se haya creado
SELECT COUNT(*) AS total_registros
FROM venta_prueba_indices;
GO

-- =============================================================================
-- 2. CARGA MASIVA DE DATOS
-- Se generan 1.000.000 de ventas ficticias para medir el rendimiento.
-- Se utiliza CROSS JOIN para combinar valores y crear los registros.
-- La tabla original venta no se modifica.
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM venta_prueba_indices)
BEGIN

    ;WITH digitos AS (
        SELECT numero
        FROM (VALUES (0),(1),(2),(3),(4),(5),
                     (6),(7),(8),(9)) AS valores(numero)
    )

    INSERT INTO venta_prueba_indices (fecha_venta, importe)
    SELECT
        DATEADD(DAY,
            unidades.numero +
            decenas.numero * 10 +
            centenas.numero * 100,
            '2025-01-01'
        ),

        CAST(
            1000 +
            miles.numero * 100 +
            decenas_mil.numero * 10 +
            centenas_mil.numero
            AS DECIMAL(12,2)
        )

    FROM digitos AS unidades
    CROSS JOIN digitos AS decenas
    CROSS JOIN digitos AS centenas
    CROSS JOIN digitos AS miles
    CROSS JOIN digitos AS decenas_mil
    CROSS JOIN digitos AS centenas_mil;

END;
GO

-- =============================================================================
-- 3. VERIFICAR LA CARGA
-- =============================================================================

SELECT COUNT_BIG(*) AS total_registros
FROM venta_prueba_indices;
GO

-- =============================================================================
-- 4. CONSULTA SIN ÍNDICE
-- Se consultan las ventas de una semana de septiembre de 2025.
-- Se miden las lecturas y los tiempos de ejecución.
-- =============================================================================

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT
    COUNT_BIG(*) AS cantidad_ventas,
    SUM(importe) AS total_recaudado
FROM venta_prueba_indices
WHERE fecha_venta >= '2025-09-01'
    AND fecha_venta < '2025-09-08';

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- =============================================================================
-- 5. CREACIÓN DE ÍNDICE AGRUPADO (CLUSTERED)
-- Se crea un índice sobre fecha_venta para optimizar
-- las búsquedas de ventas por período.
-- =============================================================================

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'idx_venta_prueba_fecha'
      AND object_id = OBJECT_ID('dbo.venta_prueba_indices')
)
BEGIN
    CREATE CLUSTERED INDEX idx_venta_prueba_fecha
    ON dbo.venta_prueba_indices (fecha_venta);
END;
GO

-- =============================================================================
-- 6. VERIFICAR LA CREACIÓN DEL ÍNDICE
-- =============================================================================

SELECT
    name AS nombre_indice,
    type_desc AS tipo_indice
FROM sys.indexes
WHERE object_id = OBJECT_ID('dbo.venta_prueba_indices')
    AND name = 'idx_venta_prueba_fecha';
GO

-- =============================================================================
-- 7. CONSULTA CON ÍNDICE CLUSTERED
-- Se repite la misma búsqueda para comparar el rendimiento.
-- =============================================================================

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT
    COUNT_BIG(*) AS cantidad_ventas,
    SUM(importe) AS total_recaudado
FROM venta_prueba_indices
WHERE fecha_venta >= '2025-09-01'
    AND fecha_venta < '2025-09-08';

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO


-- =============================================================================
-- 8. ELIMINACIÓN DEL ÍNDICE CLUSTERED
-- Se elimina el índice anterior para probar una segunda alternativa.
-- =============================================================================

IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'idx_venta_prueba_fecha'
      AND object_id = OBJECT_ID('dbo.venta_prueba_indices')
)
BEGIN
    DROP INDEX idx_venta_prueba_fecha
    ON dbo.venta_prueba_indices;
END;
GO

-- Verificar que el índice fue eliminado
SELECT name, type_desc
FROM sys.indexes
WHERE object_id = OBJECT_ID('dbo.venta_prueba_indices')
  AND name = 'idx_venta_prueba_fecha';
GO

-- =============================================================================
-- 9. CREACIÓN DEL SEGUNDO ÍNDICE CLUSTERED
-- Se crea un índice compuesto por fecha_venta e importe.
-- Permite comparar su rendimiento con el primer índice.
-- =============================================================================

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'idx_venta_prueba_fecha_importe'
      AND object_id = OBJECT_ID('dbo.venta_prueba_indices')
)
BEGIN
    CREATE CLUSTERED INDEX idx_venta_prueba_fecha_importe
    ON dbo.venta_prueba_indices (fecha_venta, importe);
END;
GO

-- =============================================================================
-- 10. VERIFICAR LA CREACIÓN DEL SEGUNDO ÍNDICE
-- =============================================================================

SELECT
    name AS nombre_indice,
    type_desc AS tipo_indice
FROM sys.indexes
WHERE object_id = OBJECT_ID('dbo.venta_prueba_indices')
  AND name = 'idx_venta_prueba_fecha_importe';
GO

-- =============================================================================
-- 11. CONSULTA CON ÍNDICE CLUSTERED COMPUESTO
-- Se repite la búsqueda utilizando el índice sobre
-- fecha_venta e importe para comparar el rendimiento.
-- =============================================================================

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT
    COUNT_BIG(*) AS cantidad_ventas,
    SUM(importe) AS total_recaudado
FROM venta_prueba_indices
WHERE fecha_venta >= '2025-09-01'
    AND fecha_venta < '2025-09-08';

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
