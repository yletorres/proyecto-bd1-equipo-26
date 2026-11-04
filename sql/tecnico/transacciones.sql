-- =============================================================================
-- Cátedra: Bases de Datos I - Lic. en Sistemas de Información (FaCENA - UNNE)
-- Proyecto: Venus Spa - Etapa V (Implementación de temas técnicos)
-- Tema 2: Manejo de transacciones (BEGIN TRANSACTION / COMMIT / ROLLBACK)
-- Archivo: transacciones.sql
-- Motor: Microsoft SQL Server (Transact-SQL)
-- Requiere: ejecutar antes el DDL y el DML (usa un cliente existente).
-- =============================================================================

USE Venus_Spa;
GO

-- =============================================================================
-- PARTE 1: IMPLEMENTACIÓN
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1.1 PROCEDIMIENTO: usp_RegistrarVenta
-- Registra una venta de uno a tres productos dentro de una única transacción:
-- cabecera de la venta, ítems y descuento de stock se confirman juntos (COMMIT)
-- o se deshacen juntos (ROLLBACK).
--   RN.04: al vender se descuenta el stock y no se puede vender más de lo
--          disponible (si no alcanza, se hace ROLLBACK de toda la venta).
--   RN.05: el precio vigente del catálogo se copia al ítem (precio histórico).
--   Toda venta tiene al menos un ítem: el primer producto es obligatorio y el
--   segundo y el tercero son opcionales (valor por defecto NULL).
-- Un RAISERROR de severidad 16 dentro del TRY transfiere el control al CATCH,
-- donde se ejecuta el ROLLBACK y se informa el motivo del error.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE usp_RegistrarVenta
    @DNI_cliente INT,
    @Metodo_Pago_Venta VARCHAR(50),
    @id_producto1 INT, @cantidad1 INT,                 -- ítem obligatorio
    @id_producto2 INT = NULL, @cantidad2 INT = NULL,   -- ítem opcional
    @id_producto3 INT = NULL, @cantidad3 INT = NULL    -- ítem opcional
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Stock INT;
    DECLARE @Precio DECIMAL(10, 2);
    DECLARE @id_venta_generada INT;
    DECLARE @Mensaje NVARCHAR(2048);

    BEGIN TRY
        -- Control transaccional: inicio de la unidad de trabajo
        BEGIN TRANSACTION;

        -- Cabecera de la venta (total en 0, se va sumando por ítem)
        INSERT INTO Venta (FechaVenta, Metodo_Pago_Venta, total_venta, DNI_cliente)
        VALUES (CAST(GETDATE() AS DATE), @Metodo_Pago_Venta, 0, @DNI_cliente);

        -- Se guarda el id de la venta recién creada
        SET @id_venta_generada = SCOPE_IDENTITY();

        -- ÍTEM 1 (obligatorio)
        SET @Stock = NULL;   -- se reinicia para no arrastrar el valor de otro ítem
        SELECT @Stock = stock_disponible, @Precio = precio_vigente
        FROM Producto WHERE id_producto = @id_producto1;

        -- RN.04: no se vende más de lo disponible (el RAISERROR salta al CATCH)
        IF @cantidad1 IS NULL OR @cantidad1 <= 0 OR @Stock IS NULL OR @Stock < @cantidad1
            RAISERROR('Error: Stock insuficiente, cantidad inválida o producto inexistente (ítem 1).', 16, 1);

        -- RN.05: se copia el precio vigente como precio histórico
        INSERT INTO Contiene (id_venta, id_producto, cantidad, precio)
        VALUES (@id_venta_generada, @id_producto1, @cantidad1, @Precio);

        -- RN.04: se descuenta el stock
        UPDATE Producto SET stock_disponible = stock_disponible - @cantidad1
        WHERE id_producto = @id_producto1;

        UPDATE Venta SET total_venta = total_venta + (@Precio * @cantidad1)
        WHERE id_venta = @id_venta_generada;

        -- ÍTEM 2 (opcional)
        IF @id_producto2 IS NOT NULL
        BEGIN
            SET @Stock = NULL;
            SELECT @Stock = stock_disponible, @Precio = precio_vigente
            FROM Producto WHERE id_producto = @id_producto2;

            IF @cantidad2 IS NULL OR @cantidad2 <= 0 OR @Stock IS NULL OR @Stock < @cantidad2
                RAISERROR('Error: Stock insuficiente, cantidad inválida o producto inexistente (ítem 2).', 16, 1);

            INSERT INTO Contiene (id_venta, id_producto, cantidad, precio)
            VALUES (@id_venta_generada, @id_producto2, @cantidad2, @Precio);

            UPDATE Producto SET stock_disponible = stock_disponible - @cantidad2
            WHERE id_producto = @id_producto2;

            UPDATE Venta SET total_venta = total_venta + (@Precio * @cantidad2)
            WHERE id_venta = @id_venta_generada;
        END

        -- ÍTEM 3 (opcional)
        IF @id_producto3 IS NOT NULL
        BEGIN
            SET @Stock = NULL;
            SELECT @Stock = stock_disponible, @Precio = precio_vigente
            FROM Producto WHERE id_producto = @id_producto3;

            IF @cantidad3 IS NULL OR @cantidad3 <= 0 OR @Stock IS NULL OR @Stock < @cantidad3
                RAISERROR('Error: Stock insuficiente, cantidad inválida o producto inexistente (ítem 3).', 16, 1);

            INSERT INTO Contiene (id_venta, id_producto, cantidad, precio)
            VALUES (@id_venta_generada, @id_producto3, @cantidad3, @Precio);

            UPDATE Producto SET stock_disponible = stock_disponible - @cantidad3
            WHERE id_producto = @id_producto3;

            UPDATE Venta SET total_venta = total_venta + (@Precio * @cantidad3)
            WHERE id_venta = @id_venta_generada;
        END

        -- Todo salió bien: se confirman definitivamente los cambios
        COMMIT TRANSACTION;
        PRINT 'Venta registrada con éxito.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;   -- deshace cabecera, ítems y descuentos de stock

        SET @Mensaje = ERROR_MESSAGE();
        RAISERROR(@Mensaje, 16, 1);
    END CATCH
END;
GO

-- -----------------------------------------------------------------------------
-- 1.2 PROCEDIMIENTO: usp_CancelarVenta
-- Ampliación conforme a la Guía de la ETAPA V: "cancelar una venta devolviendo
-- el stock". Todo en una transacción: se suma el stock, se borran los ítems y
-- se borra la cabecera. Si algo falla (por ejemplo, la venta no existe) se hace
-- ROLLBACK y no queda nada a medias.
--   RN.04: se devuelve al stock la cantidad de cada ítem vendido.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE usp_CancelarVenta
    @id_venta INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Mensaje NVARCHAR(2048);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- La venta debe existir (si no existe, salta al CATCH)
        IF NOT EXISTS (SELECT 1 FROM Venta WHERE id_venta = @id_venta)
            RAISERROR('Error: La venta indicada no existe.', 16, 1);

        -- Se devuelve al stock la cantidad de cada ítem vendido
        UPDATE p
        SET p.stock_disponible = p.stock_disponible + c.cantidad
        FROM Producto p
        INNER JOIN Contiene c ON c.id_producto = p.id_producto
        WHERE c.id_venta = @id_venta;

        -- Se eliminan los ítems y luego la cabecera
        DELETE FROM Contiene WHERE id_venta = @id_venta;
        DELETE FROM Venta WHERE id_venta = @id_venta;

        COMMIT TRANSACTION;
        PRINT 'Venta cancelada y stock devuelto.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @Mensaje = ERROR_MESSAGE();
        RAISERROR(@Mensaje, 16, 1);
    END CATCH
END;
GO

-- =============================================================================
-- PARTE 2: DEMOSTRACIÓN DE USO
-- Autocontenida: usa un cliente existente de la base poblada y crea dos
-- productos de prueba propios (A con stock 10 y B con stock 5), que se borran
-- al final. No hace falta completar ningún dato.
-- Ejecutar esta parte completa de una sola vez (comparte variables).
-- Es repetible: al inicio borra los productos de prueba de una ejecución
-- anterior y al final deja la base como estaba.
-- Los resultados de los SELECT se ven en la pestaña "Resultados" de SSMS y los
-- avisos (PRINT) en la pestaña "Mensajes".
-- =============================================================================

-- Limpieza previa de productos de prueba de una ejecución anterior (si existen)
DELETE FROM Producto WHERE nombre_producto LIKE 'Producto Test Transacciones%';

-- Productos de prueba con stock conocido
INSERT INTO Producto (nombre_producto, precio_vigente, stock_disponible)
VALUES ('Producto Test Transacciones A', 5000.00, 10);

INSERT INTO Producto (nombre_producto, precio_vigente, stock_disponible)
VALUES ('Producto Test Transacciones B', 3000.00, 5);

DECLARE @DNI_cliente  INT = (SELECT TOP 1 DNI_cliente FROM Cliente ORDER BY DNI_cliente);
DECLARE @id_producto1 INT = (SELECT TOP 1 id_producto FROM Producto
                             WHERE nombre_producto = 'Producto Test Transacciones A');
DECLARE @id_producto2 INT = (SELECT TOP 1 id_producto FROM Producto
                             WHERE nombre_producto = 'Producto Test Transacciones B');
DECLARE @id_venta INT;              -- queda NULL hasta que la Prueba 1 registre la venta
DECLARE @stock_inicial INT;
DECLARE @stock_antes INT;
DECLARE @ventas_antes INT;
DECLARE @precio_original DECIMAL(10, 2);

-- Control previo: se necesita al menos un cliente cargado
IF @DNI_cliente IS NULL
BEGIN
    PRINT 'No hay clientes cargados: ejecutar primero el DML. No se ejecutó ninguna prueba.';
    DELETE FROM Producto WHERE nombre_producto LIKE 'Producto Test Transacciones%';
    RETURN;
END;

SET @stock_inicial = (SELECT stock_disponible FROM Producto WHERE id_producto = @id_producto1);

-- Prueba 1: venta exitosa con 2 ítems (COMMIT) - RN.04 y RN.05
PRINT '--- Prueba 1: venta exitosa con 2 ítems (COMMIT) ---';

SELECT id_producto, nombre_producto, stock_disponible AS stock_antes,
       precio_vigente AS precio_catalogo
FROM Producto
WHERE id_producto IN (@id_producto1, @id_producto2);

SET @ventas_antes = (SELECT COUNT(*) FROM Venta);

BEGIN TRY
    EXEC usp_RegistrarVenta
         @DNI_cliente = @DNI_cliente, @Metodo_Pago_Venta = 'efectivo',
         @id_producto1 = @id_producto1, @cantidad1 = 2,
         @id_producto2 = @id_producto2, @cantidad2 = 1;
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS error_prueba_1;
END CATCH;

-- Solo si se registró una venta nueva se guarda su id
IF (SELECT COUNT(*) FROM Venta) > @ventas_antes
    SET @id_venta = (SELECT MAX(id_venta) FROM Venta);

-- RN.04: el stock bajó 2 y 1 unidades
SELECT id_producto, nombre_producto, stock_disponible AS stock_despues
FROM Producto
WHERE id_producto IN (@id_producto1, @id_producto2);

-- RN.05: la venta y sus ítems quedaron registrados con el precio copiado
SELECT * FROM Venta WHERE id_venta = @id_venta;
SELECT * FROM Contiene WHERE id_venta = @id_venta;

-- Prueba 2: no alcanza el stock (ROLLBACK) - RN.04
PRINT '--- Prueba 2: stock insuficiente (ROLLBACK) ---';

SET @stock_antes = (SELECT stock_disponible FROM Producto WHERE id_producto = @id_producto1);
SET @ventas_antes = (SELECT COUNT(*) FROM Venta);

BEGIN TRY
    EXEC usp_RegistrarVenta
         @DNI_cliente = @DNI_cliente, @Metodo_Pago_Venta = 'efectivo',
         @id_producto1 = @id_producto1, @cantidad1 = 99999;
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS error_prueba_2;
END CATCH;

-- Nada cambió: mismo stock y misma cantidad de ventas
SELECT @stock_antes AS stock_antes,
       (SELECT stock_disponible FROM Producto WHERE id_producto = @id_producto1) AS stock_despues,
       @ventas_antes AS ventas_antes,
       (SELECT COUNT(*) FROM Venta) AS ventas_despues;

-- Prueba 3: falla el segundo ítem (ROLLBACK de la venta completa)
-- El ítem 1 es válido y ya se había insertado y descontado, pero el ítem 2 pide
-- más stock del disponible: el ROLLBACK revierte también el ítem 1 y la cabecera.
PRINT '--- Prueba 3: falla el ítem 2, se revierte toda la venta ---';

SET @stock_antes = (SELECT stock_disponible FROM Producto WHERE id_producto = @id_producto1);
SET @ventas_antes = (SELECT COUNT(*) FROM Venta);

BEGIN TRY
    EXEC usp_RegistrarVenta
         @DNI_cliente = @DNI_cliente, @Metodo_Pago_Venta = 'efectivo',
         @id_producto1 = @id_producto1, @cantidad1 = 1,
         @id_producto2 = @id_producto2, @cantidad2 = 99999;
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS error_prueba_3;
END CATCH;

SELECT @stock_antes AS stock_producto1_antes,
       (SELECT stock_disponible FROM Producto WHERE id_producto = @id_producto1) AS stock_producto1_despues,
       @ventas_antes AS ventas_antes,
       (SELECT COUNT(*) FROM Venta) AS ventas_despues;

-- Prueba 4: precio histórico (RN.05)
-- Se cambia el precio del catálogo y el precio guardado en la venta no se altera.
PRINT '--- Prueba 4: el precio histórico no cambia con el catálogo ---';

SET @precio_original = (SELECT precio_vigente FROM Producto WHERE id_producto = @id_producto1);

UPDATE Producto SET precio_vigente = @precio_original + 1000
WHERE id_producto = @id_producto1;

SELECT c.id_venta,
       c.precio AS precio_historico_venta,
       p.precio_vigente AS precio_actual_catalogo
FROM Contiene c
INNER JOIN Producto p ON p.id_producto = c.id_producto
WHERE c.id_venta = @id_venta AND c.id_producto = @id_producto1;

-- Se restaura el precio original del catálogo
UPDATE Producto SET precio_vigente = @precio_original
WHERE id_producto = @id_producto1;

-- Prueba 5: ninguna venta quedó sin ítems
-- Las ventas generadas por el procedimiento siempre tienen al menos un ítem.
-- Si aparece alguna fila, corresponde a datos cargados antes por el DML.
PRINT '--- Prueba 5: ventas sin ítems (debe devolver 0 filas) ---';

SELECT v.id_venta
FROM Venta v
LEFT JOIN Contiene c ON c.id_venta = v.id_venta
WHERE c.id_venta IS NULL;

-- Prueba 6: cantidad inválida (ROLLBACK)
-- La cabecera ya se había insertado cuando se detecta la cantidad 0: el ROLLBACK
-- la deshace y no queda una venta sin ítems.
PRINT '--- Prueba 6: cantidad cero (ROLLBACK) ---';

SET @ventas_antes = (SELECT COUNT(*) FROM Venta);

BEGIN TRY
    EXEC usp_RegistrarVenta
         @DNI_cliente = @DNI_cliente, @Metodo_Pago_Venta = 'efectivo',
         @id_producto1 = @id_producto1, @cantidad1 = 0;
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS error_prueba_6;
END CATCH;

SELECT @ventas_antes AS ventas_antes, (SELECT COUNT(*) FROM Venta) AS ventas_despues;

-- Prueba 7: método de pago inválido (ROLLBACK) - RN.06
-- El CHECK de la tabla Venta rechaza el método 'bitcoin' y la transacción se
-- revierte: no se registra la venta ni se toca el stock.
PRINT '--- Prueba 7: método de pago inválido (ROLLBACK) ---';

SET @stock_antes = (SELECT stock_disponible FROM Producto WHERE id_producto = @id_producto1);
SET @ventas_antes = (SELECT COUNT(*) FROM Venta);

BEGIN TRY
    EXEC usp_RegistrarVenta
         @DNI_cliente = @DNI_cliente, @Metodo_Pago_Venta = 'bitcoin',
         @id_producto1 = @id_producto1, @cantidad1 = 1;
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS error_prueba_7;
END CATCH;

SELECT @stock_antes AS stock_antes,
       (SELECT stock_disponible FROM Producto WHERE id_producto = @id_producto1) AS stock_despues,
       @ventas_antes AS ventas_antes,
       (SELECT COUNT(*) FROM Venta) AS ventas_despues;

-- Prueba 8: cancelar una venta devuelve el stock (COMMIT)
-- Cancela la venta creada en la Prueba 1 (si se registró): el stock vuelve al
-- valor inicial y la venta y sus ítems desaparecen.
PRINT '--- Prueba 8: usp_CancelarVenta devuelve el stock ---';

IF @id_venta IS NULL
    PRINT 'La Prueba 1 no registró ninguna venta: se omite la Prueba 8.';
ELSE
BEGIN
    SELECT id_producto, nombre_producto, stock_disponible AS stock_antes_de_cancelar
    FROM Producto
    WHERE id_producto IN (@id_producto1, @id_producto2);

    EXEC usp_CancelarVenta @id_venta = @id_venta;

    SELECT id_producto, nombre_producto, stock_disponible AS stock_despues_de_cancelar
    FROM Producto
    WHERE id_producto IN (@id_producto1, @id_producto2);

    -- El stock del producto A volvió al valor que tenía antes de la Prueba 1
    SELECT @stock_inicial AS stock_inicial_producto1,
           (SELECT stock_disponible FROM Producto WHERE id_producto = @id_producto1) AS stock_final_producto1;

    -- La venta y sus ítems ya no existen (ambos deben dar 0)
    SELECT COUNT(*) AS venta_existe FROM Venta WHERE id_venta = @id_venta;
    SELECT COUNT(*) AS items_existen FROM Contiene WHERE id_venta = @id_venta;
END;

-- Prueba 9: cancelar una venta inexistente (ROLLBACK)
PRINT '--- Prueba 9: venta inexistente (ROLLBACK) ---';

BEGIN TRY
    EXEC usp_CancelarVenta @id_venta = -1;
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS error_prueba_9;
END CATCH;

-- Limpieza final: se borran los productos de prueba (la base queda como estaba)
DELETE FROM Producto WHERE nombre_producto LIKE 'Producto Test Transacciones%';
GO