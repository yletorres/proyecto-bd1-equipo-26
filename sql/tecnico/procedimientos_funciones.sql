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
           s.denominacion    AS servicio,
           t.precio_historico,
           p.nombre_completo AS profesional
    FROM turno t
    INNER JOIN servicio s         ON s.id_servicio = t.id_servicio
    INNER JOIN se_asigna_turno sa ON sa.id_turno = t.id_turno
    INNER JOIN persona p          ON p.dni_persona = sa.dni_profesional
    WHERE t.dni_cliente = @dni_cliente
);
GO

-- =============================================================================
-- PARTE 2: DEMOSTRACIÓN DE USO
-- Se toman datos existentes de la base poblada. Requiere al menos 2 camillas,
-- 1 cliente, 1 servicio y 1 profesional cargados.
-- Ejecutar esta parte completa de una sola vez (comparte variables).
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

-- Limpieza opcional del turno de prueba (descomentar para dejar la base como estaba)
-- DELETE FROM se_asigna_turno WHERE id_turno = @id_turno;
-- DELETE FROM turno WHERE id_turno = @id_turno;
GO