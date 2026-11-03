-- =============================================================================
-- Cátedra: Bases de Datos I - Lic. en Sistemas de Información (FaCENA - UNNE)
-- Proyecto: Venus Spa - Etapa V (Implementación de temas técnicos)
-- Tema: Procedimientos y funciones almacenadas
-- Archivo: procedimientos_funciones.sql
-- Motor: Microsoft SQL Server (Transact-SQL)
-- =============================================================================

USE Venus_Spa;
GO

-- =============================================================================
-- PARTE 1: IMPLEMENTACIÓN
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1.1 PROCEDIMIENTO: usp_RegistrarTurno
-- Registra un turno validando las reglas de negocio y asigna un profesional.
--   RN.02.1: una camilla no puede tener dos turnos en la misma fecha y franja.
--   RN.03:   un cliente no puede tener dos turnos en la misma fecha y franja.
--   RN.05.1: el precio del servicio se copia al turno (precio histórico).
--   RN.07:   el turno se vincula a un servicio existente.
--   RN.07.1: el turno tiene al menos un profesional asignado.
-- Devuelve el id del turno generado mediante el parámetro OUTPUT.
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.usp_RegistrarTurno', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_RegistrarTurno;
GO

CREATE PROCEDURE dbo.usp_RegistrarTurno
    @dni_cliente     INT,
    @id_camilla      INT,
    @id_servicio     INT,
    @dni_profesional INT,
    @fecha_turno     DATE,
    @franja_horaria  TIME(0),
    @metodo_pago     VARCHAR(50),
    @id_turno        INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @precio DECIMAL(10,2);

    -- RN.07 / RN.05.1: el servicio debe existir; se toma su precio vigente
    SELECT @precio = precio_unitario
    FROM servicio
    WHERE id_servicio = @id_servicio;

    IF @precio IS NULL
    BEGIN
        RAISERROR('El servicio indicado no existe.', 16, 1);
        RETURN;
    END;

    -- RN.02.1: la camilla no puede tener otro turno en esa fecha y franja
    IF EXISTS (SELECT 1
               FROM turno
               WHERE fecha_turno = @fecha_turno
                 AND franja_horaria = @franja_horaria
                 AND id_camilla = @id_camilla)
    BEGIN
        RAISERROR('La camilla ya tiene un turno en esa fecha y franja horaria.', 16, 1);
        RETURN;
    END;

    -- RN.03: el cliente no puede tener otro turno en esa fecha y franja
    IF EXISTS (SELECT 1
               FROM turno
               WHERE fecha_turno = @fecha_turno
                 AND franja_horaria = @franja_horaria
                 AND dni_cliente = @dni_cliente)
    BEGIN
        RAISERROR('El cliente ya tiene un turno en esa fecha y franja horaria.', 16, 1);
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRAN;

        INSERT INTO turno (fecha_turno, franja_horaria, estado, metodo_pago_turno,
                           precio_historico, dni_cliente, id_camilla, id_servicio)
        VALUES (@fecha_turno, @franja_horaria, 'pendiente', @metodo_pago,
                @precio, @dni_cliente, @id_camilla, @id_servicio);

        SET @id_turno = SCOPE_IDENTITY();

        -- RN.07.1: todo turno tiene al menos un profesional asignado
        INSERT INTO se_asigna_turno (dni_profesional, id_turno)
        VALUES (@dni_profesional, @id_turno);

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        DECLARE @mensaje NVARCHAR(2048) = ERROR_MESSAGE();
        RAISERROR(@mensaje, 16, 1);
    END CATCH;
END;
GO

-- -----------------------------------------------------------------------------
-- 1.2 FUNCIÓN ESCALAR: fn_TotalVenta
-- Devuelve el importe total de una venta (suma de cantidad * precio histórico
-- de cada ítem de la tabla contiene). RN.05.
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.fn_TotalVenta', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_TotalVenta;
GO

CREATE FUNCTION dbo.fn_TotalVenta (@id_venta INT)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @total DECIMAL(12,2);

    SELECT @total = SUM(cantidad * precio)
    FROM contiene
    WHERE id_venta = @id_venta;

    RETURN ISNULL(@total, 0);
END;
GO

-- -----------------------------------------------------------------------------
-- 1.3 FUNCIÓN DE TABLA EN LÍNEA: fn_TurnosPorCliente
-- Devuelve los turnos de un cliente con su servicio y profesional.
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.fn_TurnosPorCliente', 'IF') IS NOT NULL
    DROP FUNCTION dbo.fn_TurnosPorCliente;
GO

 CREATE FUNCTION dbo.fn_TurnosPorCliente (@dni_cliente INT)
 RETURNS TABLE
 AS
 RETURN
 (
    SELECT t.id_turno,
       t.fecha_turno,
       t.franja_horaria,
       t.estado,
       s.denominacion                    AS servicio,
       t.precio_historico,
       STRING_AGG(p.nombre_completo, ', ') AS profesionales
    FROM turno t
    INNER JOIN servicio s         ON s.id_servicio = t.id_servicio
    INNER JOIN se_asigna_turno sa ON sa.id_turno = t.id_turno
    INNER JOIN persona p          ON p.dni_persona = sa.dni_profesional
    WHERE t.dni_cliente = @dni_cliente
    GROUP BY t.id_turno, t.fecha_turno, t.franja_horaria, t.estado,
             s.denominacion, t.precio_historico
);
GO

-- CREATE FUNCTION dbo.fn_TurnosPorCliente (@dni_cliente INT)
-- RETURNS TABLE
-- AS
-- RETURN
-- (
--    SELECT t.id_turno,
--           t.fecha_turno,
--           t.franja_horaria,
--           t.estado,
--           s.denominacion    AS servicio,
--           t.precio_historico,
--           p.nombre_completo AS profesional
--    FROM turno t
--    INNER JOIN servicio s         ON s.id_servicio = t.id_servicio
--    INNER JOIN se_asigna_turno sa ON sa.id_turno = t.id_turno
--    INNER JOIN persona p          ON p.dni_persona = sa.dni_profesional
--    WHERE t.dni_cliente = @dni_cliente
-- );
-- GO
-- VERSION ANTERIOR: mostraba una fila con datos repetidos por profesional

-- =============================================================================
-- PARTE 2: DEMOSTRACIÓN DE USO
-- Se toman datos existentes de la base poblada. Requiere al menos 2 camillas,
-- 1 cliente, 1 servicio y 1 profesional cargados.
-- Ejecutar esta parte completa de una sola vez (comparte variables).
-- Se puede ejecutar varias veces: al inicio borra el turno de prueba anterior.
-- =============================================================================
 
DECLARE @dni_cliente     INT = (SELECT TOP 1 dni_cliente FROM cliente ORDER BY dni_cliente);
DECLARE @id_camilla      INT = (SELECT TOP 1 id_camilla FROM camilla ORDER BY id_camilla);
DECLARE @id_camilla_otra INT = (SELECT TOP 1 id_camilla FROM camilla
                                WHERE id_camilla <> @id_camilla ORDER BY id_camilla);
DECLARE @id_servicio     INT = (SELECT TOP 1 id_servicio FROM servicio ORDER BY id_servicio);
DECLARE @dni_profesional INT = (SELECT TOP 1 dni_profesional FROM profesional ORDER BY dni_profesional);
DECLARE @fecha           DATE = '2027-01-15';   -- fecha sin turnos cargados
DECLARE @franja          TIME(0) = '09:00:00';
DECLARE @id_turno        INT;
 
-- Limpieza previa: borra el turno de prueba de una ejecución anterior (si existe)
-- para poder correr esta parte todas las veces que haga falta.
DELETE FROM se_asigna_turno
WHERE id_turno IN (SELECT id_turno FROM turno
                   WHERE fecha_turno = @fecha AND dni_cliente = @dni_cliente);
 
DELETE FROM turno
WHERE fecha_turno = @fecha AND dni_cliente = @dni_cliente;

-- Prueba 1: registro exitoso (se devuelve el id por el parámetro OUTPUT)
PRINT '--- Prueba 1: registro exitoso ---';
EXEC dbo.usp_RegistrarTurno
     @dni_cliente     = @dni_cliente,
     @id_camilla      = @id_camilla,
     @id_servicio     = @id_servicio,
     @dni_profesional = @dni_profesional,
     @fecha_turno     = @fecha,
     @franja_horaria  = @franja,
     @metodo_pago     = 'efectivo',
     @id_turno        = @id_turno OUTPUT;
 
SELECT @id_turno AS id_turno_generado;
 
-- Prueba 2: verificación de lo insertado
PRINT '--- Prueba 2: verificación en turno y se_asigna_turno ---';
SELECT t.id_turno, t.fecha_turno, t.franja_horaria, t.estado,
       t.precio_historico, s.precio_unitario AS precio_actual_servicio
FROM turno t
INNER JOIN servicio s ON s.id_servicio = t.id_servicio
WHERE t.id_turno = @id_turno;
 
SELECT * FROM se_asigna_turno WHERE id_turno = @id_turno;
 
-- Prueba 3: camilla ocupada (RN.02.1) - debe rechazarse
PRINT '--- Prueba 3: camilla ocupada ---';
BEGIN TRY
    EXEC dbo.usp_RegistrarTurno
         @dni_cliente     = @dni_cliente,
         @id_camilla      = @id_camilla,
         @id_servicio     = @id_servicio,
         @dni_profesional = @dni_profesional,
         @fecha_turno     = @fecha,
         @franja_horaria  = @franja,
         @metodo_pago     = 'efectivo',
         @id_turno        = @id_turno OUTPUT;
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS error_prueba_3;
END CATCH;
 
-- Prueba 4: cliente con turno en la misma franja (RN.03) - debe rechazarse
PRINT '--- Prueba 4: cliente con turno en la misma franja ---';
BEGIN TRY
    EXEC dbo.usp_RegistrarTurno
         @dni_cliente     = @dni_cliente,
         @id_camilla      = @id_camilla_otra,
         @id_servicio     = @id_servicio,
         @dni_profesional = @dni_profesional,
         @fecha_turno     = @fecha,
         @franja_horaria  = @franja,
         @metodo_pago     = 'efectivo',
         @id_turno        = @id_turno OUTPUT;
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS error_prueba_4;
END CATCH;
 
-- Prueba 5: función escalar fn_TotalVenta
PRINT '--- Prueba 5: fn_TotalVenta ---';
SELECT TOP 10 v.id_venta, v.fecha_venta, dbo.fn_TotalVenta(v.id_venta) AS total
FROM venta v
ORDER BY v.id_venta;
 
-- Prueba 6: función de tabla fn_TurnosPorCliente
PRINT '--- Prueba 6: fn_TurnosPorCliente ---';
SELECT * FROM dbo.fn_TurnosPorCliente(@dni_cliente) ORDER BY fecha_turno;
GO

-- =============================================================================
-- PARTE 3: AMPLIACIÓN (objetos adicionales)
-- Se agregan objetos sobre las tablas de ventas, productos y turnos.
-- Conforme a los ejemplos dados en la Guía de la ETAPA V.
-- Requiere ejecutar antes la Parte 1 (usa dbo.fn_TotalVenta y dbo.usp_RegistrarTurno).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 3.1 FUNCIÓN ESCALAR: fn_DescuentoCliente
-- Calcula el porcentaje de descuento de un cliente según lo que acumuló entre
-- compras de productos (fn_TotalVenta) y servicios ya realizados.
--   acumulado >= 60.000  -> 10 %
--   acumulado >= 30.000  ->  5 %
--   caso contrario       ->  0 %
-- Los umbrales se ajustaron a los precios de Venus Spa (productos desde
-- $3.200 y servicios desde $12.000).
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.fn_DescuentoCliente', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_DescuentoCliente;
GO

CREATE FUNCTION dbo.fn_DescuentoCliente (@dni_cliente INT)
RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @en_productos DECIMAL(14,2);
    DECLARE @en_servicios DECIMAL(14,2);

    -- Una función puede llamar a otra: se reutiliza fn_TotalVenta
    SELECT @en_productos = SUM(dbo.fn_TotalVenta(id_venta))
    FROM venta
    WHERE dni_cliente = @dni_cliente;

    -- Solo cuentan los turnos efectivamente realizados
    SELECT @en_servicios = SUM(precio_historico)
    FROM turno
    WHERE dni_cliente = @dni_cliente
      AND estado = 'realizado';

    DECLARE @acumulado DECIMAL(14,2) = ISNULL(@en_productos, 0) + ISNULL(@en_servicios, 0);

    RETURN CASE WHEN @acumulado >= 60000 THEN 10.00
                WHEN @acumulado >= 30000 THEN  5.00
                ELSE 0.00
           END;
END;
GO

-- -----------------------------------------------------------------------------
-- 3.2 PROCEDIMIENTO: usp_CancelarTurno
-- Cambia el estado de un turno a 'cancelado' (RN.09).
-- Solo se pueden cancelar turnos 'pendiente' o 'confirmado'.
-- Es una única sentencia UPDATE, por eso no necesita transacción explícita.
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.usp_CancelarTurno', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_CancelarTurno;
GO

CREATE PROCEDURE dbo.usp_CancelarTurno
    @id_turno INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @estado VARCHAR(20);

    SELECT @estado = estado
    FROM turno
    WHERE id_turno = @id_turno;

    IF @estado IS NULL
    BEGIN
        RAISERROR('El turno indicado no existe.', 16, 1);
        RETURN;
    END;

    IF @estado NOT IN ('pendiente', 'confirmado')
    BEGIN
        RAISERROR('Solo se pueden cancelar turnos pendientes o confirmados.', 16, 1);
        RETURN;
    END;

    UPDATE turno
    SET estado = 'cancelado'
    WHERE id_turno = @id_turno;

    SELECT id_turno, fecha_turno, franja_horaria, estado
    FROM turno
    WHERE id_turno = @id_turno;
END;
GO

-- -----------------------------------------------------------------------------
-- 3.3 FUNCIÓN DE TABLA EN LÍNEA: fn_CamillasLibres
-- Devuelve las camillas sin turno en una fecha y franja determinadas.
-- Sirve para elegir @id_camilla antes de llamar a usp_RegistrarTurno (RN.02.1).
-- Nota: la restricción UNIQUE (fecha, franja, camilla) no mira el estado, por
-- lo que un turno cancelado también ocupa la camilla; la función es coherente
-- con esa restricción.
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.fn_CamillasLibres', 'IF') IS NOT NULL
    DROP FUNCTION dbo.fn_CamillasLibres;
GO

CREATE FUNCTION dbo.fn_CamillasLibres (@fecha DATE, @franja TIME(0))
RETURNS TABLE
AS
RETURN
(
    SELECT c.id_camilla,
           c.nombre
    FROM camilla c
    WHERE NOT EXISTS (SELECT 1
                      FROM turno t
                      WHERE t.id_camilla     = c.id_camilla
                        AND t.fecha_turno    = @fecha
                        AND t.franja_horaria = @franja)
);
GO

-- =============================================================================
-- PARTE 4: DEMOSTRACIÓN DE LA AMPLIACIÓN
-- Ejecutar completa de una sola vez (comparte variables). Es repetible:
-- al final deshace la venta de prueba y devuelve el stock.
-- =============================================================================

DECLARE @fecha2       DATE    = '2027-01-16';   -- fecha sin turnos cargados
DECLARE @franja2      TIME(0) = '09:00:00';
DECLARE @dni_cli_desc INT     = (SELECT TOP 1 dni_cliente FROM cliente
                                 ORDER BY dbo.fn_DescuentoCliente(dni_cliente) DESC, dni_cliente);
DECLARE @dni_cli_sin  INT     = (SELECT TOP 1 dni_cliente FROM cliente
                                 ORDER BY dbo.fn_DescuentoCliente(dni_cliente) ASC, dni_cliente);
DECLARE @id_producto  INT     = (SELECT TOP 1 id_producto FROM producto
                                 WHERE stock_disponible >= 5 ORDER BY id_producto);
DECLARE @stock_antes  INT     = (SELECT stock_disponible FROM producto WHERE id_producto = @id_producto);
DECLARE @ventas_antes INT     = (SELECT COUNT(*) FROM venta);
DECLARE @id_venta     INT;
DECLARE @descuento    DECIMAL(5,2);
DECLARE @id_turno2    INT;
DECLARE @id_camilla2  INT     = (SELECT TOP 1 id_camilla FROM camilla ORDER BY id_camilla);
DECLARE @id_servicio2 INT     = (SELECT TOP 1 id_servicio FROM servicio ORDER BY id_servicio);
DECLARE @dni_prof2    INT     = (SELECT TOP 1 dni_profesional FROM profesional ORDER BY dni_profesional);

-- Limpieza previa del turno de prueba de una ejecución anterior (si existe)
DELETE FROM se_asigna_turno
WHERE id_turno IN (SELECT id_turno FROM turno WHERE fecha_turno = @fecha2);
DELETE FROM turno WHERE fecha_turno = @fecha2;

-- Prueba 7: fn_DescuentoCliente aplicada a todos los clientes
PRINT '--- Prueba 7: fn_DescuentoCliente (descuento por cliente) ---';
SELECT p.nombre_completo,
       dbo.fn_DescuentoCliente(c.dni_cliente) AS descuento_porcentaje
FROM cliente c
INNER JOIN persona p ON p.dni_persona = c.dni_cliente
ORDER BY descuento_porcentaje DESC, p.nombre_completo;

-- Prueba 8: fn_CamillasLibres antes y después de registrar un turno
PRINT '--- Prueba 8: fn_CamillasLibres ---';
SELECT COUNT(*) AS camillas_libres_antes
FROM dbo.fn_CamillasLibres(@fecha2, @franja2);

EXEC dbo.usp_RegistrarTurno
     @dni_cliente     = @dni_cli_sin,
     @id_camilla      = @id_camilla2,
     @id_servicio     = @id_servicio2,
     @dni_profesional = @dni_prof2,
     @fecha_turno     = @fecha2,
     @franja_horaria  = @franja2,
     @metodo_pago     = 'efectivo',
     @id_turno        = @id_turno2 OUTPUT;

SELECT COUNT(*) AS camillas_libres_despues
FROM dbo.fn_CamillasLibres(@fecha2, @franja2);

-- Prueba 9: usp_CancelarTurno
PRINT '--- Prueba 9: usp_CancelarTurno ---';
EXEC dbo.usp_CancelarTurno @id_turno = @id_turno2;   -- pasa a 'cancelado'

PRINT '--- Prueba 9b: cancelar un turno ya cancelado (debe rechazarse) ---';
BEGIN TRY
    EXEC dbo.usp_CancelarTurno @id_turno = @id_turno2;
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS error_prueba_9b;
END CATCH;

-- Limpieza final: deja la base como estaba antes de la demostración
DELETE FROM se_asigna_turno WHERE id_turno = @id_turno2;
DELETE FROM turno           WHERE id_turno = @id_turno2;
DELETE FROM venta           WHERE id_venta = @id_venta;   -- contiene se borra en cascada
UPDATE producto SET stock_disponible = @stock_antes WHERE id_producto = @id_producto;
GO