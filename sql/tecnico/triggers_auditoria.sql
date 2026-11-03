-- =============================================================================
-- Cátedra: Bases de Datos I - Lic. en Sistemas de Información (FaCENA - UNNE)
-- Proyecto: Venus Spa - Etapa V (Implementación de temas técnicos)
-- Tema 3: Triggers de auditoría (AFTER INSERT/UPDATE/DELETE y tabla de auditoría)
-- Archivo: triggers_auditoria.sql
-- Motor: Microsoft SQL Server (Transact-SQL)
-- =============================================================================

USE Venus_Spa;
GO

-- =============================================================================
-- PARTE 1: CREACIÓN DE LA TABLA DE AUDITORÍA
-- La tabla de auditoría centraliza el registro histórico de operaciones críticas.
-- Almacena quién realizó el cambio, cuándo ocurrió, la operación (INSERT/UPDATE/DELETE),
-- la tabla afectada, el identificador del registro y los valores anterior y nuevo.
-- =============================================================================

IF OBJECT_ID('dbo.auditoria', 'U') IS NOT NULL
    DROP TABLE dbo.auditoria;
GO

CREATE TABLE dbo.auditoria (
    id_auditoria      BIGINT IDENTITY(1,1) NOT NULL,
    fecha_hora        DATETIME             NOT NULL CONSTRAINT df_auditoria_fecha DEFAULT GETDATE(),
    usuario           VARCHAR(100)         NOT NULL CONSTRAINT df_auditoria_usuario DEFAULT SUSER_SNAME(),
    terminal          VARCHAR(100)         NOT NULL CONSTRAINT df_auditoria_terminal DEFAULT HOST_NAME(),
    tabla_auditada    VARCHAR(50)          NOT NULL,
    operacion         VARCHAR(10)          NOT NULL,
    id_registro       VARCHAR(100)         NOT NULL,
    columna_afectada  VARCHAR(50)          NULL,
    valor_anterior    VARCHAR(MAX)         NULL,
    valor_nuevo       VARCHAR(MAX)         NULL,
    detalle           VARCHAR(250)         NULL,

    CONSTRAINT pk_auditoria
        PRIMARY KEY (id_auditoria),

    CONSTRAINT ck_auditoria_operacion
        CHECK (operacion IN ('INSERT', 'UPDATE', 'DELETE'))
);
GO

-- =============================================================================
-- PARTE 2: IMPLEMENTACIÓN DE TRIGGERS DE AUDITORÍA
-- Todos los triggers son posteriores (AFTER) y manejan operaciones sobre conjuntos
-- de datos (multi-fila) utilizando las tablas virtuales 'inserted' y 'deleted'.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 2.1 TRIGGER: trg_auditoria_producto
-- Audita inserciones, modificaciones críticas (precio_vigente y stock_disponible)
-- y eliminaciones sobre el catálogo de productos de reventa.
-- Reglas de negocio vinculadas: RN.04 (stock) y RN.05 (precios de catálogo).
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_auditoria_producto', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_auditoria_producto;
GO

CREATE TRIGGER dbo.trg_auditoria_producto
ON dbo.producto
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Caso 1: UPDATE (existen registros en 'inserted' y en 'deleted')
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        -- 1.A Cambio en precio_vigente
        IF UPDATE(precio_vigente)
        BEGIN
            INSERT INTO dbo.auditoria (
                tabla_auditada, operacion, id_registro, columna_afectada,
                valor_anterior, valor_nuevo, detalle
            )
            SELECT
                'producto',
                'UPDATE',
                CAST(i.id_producto AS VARCHAR(100)),
                'precio_vigente',
                CAST(d.precio_vigente AS VARCHAR(50)),
                CAST(i.precio_vigente AS VARCHAR(50)),
                'Modificación de precio de lista: ' + i.nombre_producto
            FROM inserted i
            INNER JOIN deleted d ON i.id_producto = d.id_producto
            WHERE i.precio_vigente <> d.precio_vigente;
        END;

        -- 1.B Ajuste en stock_disponible
        IF UPDATE(stock_disponible)
        BEGIN
            INSERT INTO dbo.auditoria (
                tabla_auditada, operacion, id_registro, columna_afectada,
                valor_anterior, valor_nuevo, detalle
            )
            SELECT
                'producto',
                'UPDATE',
                CAST(i.id_producto AS VARCHAR(100)),
                'stock_disponible',
                CAST(d.stock_disponible AS VARCHAR(50)),
                CAST(i.stock_disponible AS VARCHAR(50)),
                'Ajuste manual de existencias: ' + i.nombre_producto
            FROM inserted i
            INNER JOIN deleted d ON i.id_producto = d.id_producto
            WHERE i.stock_disponible <> d.stock_disponible;
        END;
    END
    -- Caso 2: INSERT (solo existen registros en 'inserted')
    ELSE IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO dbo.auditoria (
            tabla_auditada, operacion, id_registro, columna_afectada,
            valor_anterior, valor_nuevo, detalle
        )
        SELECT
            'producto',
            'INSERT',
            CAST(i.id_producto AS VARCHAR(100)),
            'TODAS',
            NULL,
            'Nombre: ' + i.nombre_producto +
            ' | Precio: $' + CAST(i.precio_vigente AS VARCHAR(50)) +
            ' | Stock: ' + CAST(i.stock_disponible AS VARCHAR(50)),
            'Alta de nuevo producto en catálogo'
        FROM inserted i;
    END
    -- Caso 3: DELETE (solo existen registros en 'deleted')
    ELSE IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO dbo.auditoria (
            tabla_auditada, operacion, id_registro, columna_afectada,
            valor_anterior, valor_nuevo, detalle
        )
        SELECT
            'producto',
            'DELETE',
            CAST(d.id_producto AS VARCHAR(100)),
            'TODAS',
            'Nombre: ' + d.nombre_producto +
            ' | Último Precio: $' + CAST(d.precio_vigente AS VARCHAR(50)) +
            ' | Último Stock: ' + CAST(d.stock_disponible AS VARCHAR(50)),
            NULL,
            'Baja física de producto del catálogo'
        FROM deleted d;
    END;
END;
GO

-- -----------------------------------------------------------------------------
-- 2.2 TRIGGER: trg_auditoria_servicio
-- Audita modificaciones de precio_unitario y eliminaciones de tratamientos/servicios.
-- Regla de negocio vinculada: RN.05.1 y catálogo de servicios.
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_auditoria_servicio', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_auditoria_servicio;
GO

CREATE TRIGGER dbo.trg_auditoria_servicio
ON dbo.servicio
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Caso 1: UPDATE
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        IF UPDATE(precio_unitario)
        BEGIN
            INSERT INTO dbo.auditoria (
                tabla_auditada, operacion, id_registro, columna_afectada,
                valor_anterior, valor_nuevo, detalle
            )
            SELECT
                'servicio',
                'UPDATE',
                CAST(i.id_servicio AS VARCHAR(100)),
                'precio_unitario',
                CAST(d.precio_unitario AS VARCHAR(50)),
                CAST(i.precio_unitario AS VARCHAR(50)),
                'Actualización de arancel de servicio: ' + i.denominacion
            FROM inserted i
            INNER JOIN deleted d ON i.id_servicio = d.id_servicio
            WHERE i.precio_unitario <> d.precio_unitario;
        END;
    END
    -- Caso 2: INSERT
    ELSE IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO dbo.auditoria (
            tabla_auditada, operacion, id_registro, columna_afectada,
            valor_anterior, valor_nuevo, detalle
        )
        SELECT
            'servicio',
            'INSERT',
            CAST(i.id_servicio AS VARCHAR(100)),
            'TODAS',
            NULL,
            'Denominación: ' + i.denominacion + ' | Precio: $' + CAST(i.precio_unitario AS VARCHAR(50)),
            'Incorporación de nuevo tratamiento/servicio'
        FROM inserted i;
    END
    -- Caso 3: DELETE
    ELSE IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO dbo.auditoria (
            tabla_auditada, operacion, id_registro, columna_afectada,
            valor_anterior, valor_nuevo, detalle
        )
        SELECT
            'servicio',
            'DELETE',
            CAST(d.id_servicio AS VARCHAR(100)),
            'TODAS',
            'Denominación: ' + d.denominacion + ' | Precio: $' + CAST(d.precio_unitario AS VARCHAR(50)),
            NULL,
            'Baja de servicio del catálogo'
        FROM deleted d;
    END;
END;
GO

-- -----------------------------------------------------------------------------
-- 2.3 TRIGGER: trg_auditoria_turno_precio
-- Audita modificaciones sobre 'precio_historico' en turnos.
-- RN.05.1: el precio se congela al registrar el turno. Si alguien modifica el
-- precio histórico, queda registrado en auditoría.
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_auditoria_turno_precio', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_auditoria_turno_precio;
GO

CREATE TRIGGER dbo.trg_auditoria_turno_precio
ON dbo.turno
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(precio_historico)
    BEGIN
        INSERT INTO dbo.auditoria (
            tabla_auditada, operacion, id_registro, columna_afectada,
            valor_anterior, valor_nuevo, detalle
        )
        SELECT
            'turno',
            'UPDATE',
            CAST(i.id_turno AS VARCHAR(100)),
            'precio_historico',
            CAST(d.precio_historico AS VARCHAR(50)),
            CAST(i.precio_historico AS VARCHAR(50)),
            'Alteración del precio histórico del turno del cliente DNI: ' + CAST(i.dni_cliente AS VARCHAR(20))
        FROM inserted i
        INNER JOIN deleted d ON i.id_turno = d.id_turno
        WHERE i.precio_historico <> d.precio_historico;
    END;
END;
GO

-- -----------------------------------------------------------------------------
-- 2.4 TRIGGER: trg_auditoria_contiene_precio
-- Audita modificaciones sobre 'precio' en el detalle de ventas (tabla contiene).
-- RN.05: cada ítem guarda el precio histórico cobrado. Si alguien lo cambia
-- después de la venta, queda registrado en auditoría.
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.trg_auditoria_contiene_precio', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_auditoria_contiene_precio;
GO

CREATE TRIGGER dbo.trg_auditoria_contiene_precio
ON dbo.contiene
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(precio)
    BEGIN
        INSERT INTO dbo.auditoria (
            tabla_auditada, operacion, id_registro, columna_afectada,
            valor_anterior, valor_nuevo, detalle
        )
        SELECT
            'contiene',
            'UPDATE',
            'Venta: ' + CAST(i.id_venta AS VARCHAR(20)) + ' | Prod: ' + CAST(i.id_producto AS VARCHAR(20)),
            'precio',
            CAST(d.precio AS VARCHAR(50)),
            CAST(i.precio AS VARCHAR(50)),
            'Modificación de precio histórico de ítem en comprobante de venta'
        FROM inserted i
        INNER JOIN deleted d ON i.id_venta = d.id_venta AND i.id_producto = d.id_producto
        WHERE i.precio <> d.precio;
    END;
END;
GO

-- =============================================================================
-- PARTE 3: DEMOSTRACIÓN DE USO Y PRUEBAS SECUENCIALES
-- Las pruebas son repetibles: limpian registros de prueba previos para permitir
-- múltiples ejecuciones limpias sin acumular inconsistencias.
-- Ejecutar en bloque para visualizar la auditoría paso a paso.
-- =============================================================================

-- Limpieza preventiva de pruebas anteriores
DELETE FROM dbo.auditoria;
DELETE FROM dbo.producto WHERE nombre_producto LIKE 'Producto Test Auditoria%';
GO

-- -----------------------------------------------------------------------------
-- PRUEBA 1: INSERT de un nuevo producto en catálogo
-- -----------------------------------------------------------------------------
PRINT '=== PRUEBA 1: INSERT en tabla producto ===';

INSERT INTO dbo.producto (nombre_producto, precio_vigente, stock_disponible)
VALUES ('Producto Test Auditoria A', 15000.00, 20);

SELECT TOP 1 *
FROM dbo.auditoria
WHERE tabla_auditada = 'producto' AND operacion = 'INSERT'
ORDER BY id_auditoria DESC;
GO

-- -----------------------------------------------------------------------------
-- PRUEBA 2: UPDATE de precio_vigente y stock_disponible en producto
-- -----------------------------------------------------------------------------
PRINT '=== PRUEBA 2: UPDATE de precio y stock en producto ===';

UPDATE dbo.producto
SET precio_vigente = 18500.00,
    stock_disponible = 15
WHERE nombre_producto = 'Producto Test Auditoria A';

SELECT TOP 2 *
FROM dbo.auditoria
WHERE tabla_auditada = 'producto' AND operacion = 'UPDATE'
ORDER BY id_auditoria DESC;
GO

-- -----------------------------------------------------------------------------
-- PRUEBA 3: UPDATE multi-fila (operación por conjuntos)
-- Demuestra que el trigger maneja múltiples registros afectados en una sola sentencia.
-- -----------------------------------------------------------------------------
PRINT '=== PRUEBA 3: UPDATE multi-fila en producto ===';

INSERT INTO dbo.producto (nombre_producto, precio_vigente, stock_disponible)
VALUES ('Producto Test Auditoria B', 9000.00, 10);

-- Actualización masiva de ambos productos de prueba (+10% precio)
UPDATE dbo.producto
SET precio_vigente = precio_vigente * 1.10
WHERE nombre_producto LIKE 'Producto Test Auditoria%';

SELECT *
FROM dbo.auditoria
WHERE tabla_auditada = 'producto'
  AND detalle LIKE '%Producto Test Auditoria%'
ORDER BY id_auditoria DESC;
GO

-- -----------------------------------------------------------------------------
-- PRUEBA 4: UPDATE de precio_unitario en servicio
-- -----------------------------------------------------------------------------
PRINT '=== PRUEBA 4: UPDATE de precio_unitario en servicio ===';

DECLARE @id_serv INT = (SELECT TOP 1 id_servicio FROM dbo.servicio ORDER BY id_servicio);
DECLARE @precio_original DECIMAL(10,2) = (SELECT precio_unitario FROM dbo.servicio WHERE id_servicio = @id_serv);

-- Modificamos el precio
UPDATE dbo.servicio
SET precio_unitario = @precio_original + 2000.00
WHERE id_servicio = @id_serv;

SELECT TOP 1 *
FROM dbo.auditoria
WHERE tabla_auditada = 'servicio' AND operacion = 'UPDATE'
ORDER BY id_auditoria DESC;

-- Restauramos el precio original (genera otra entrada de auditoría)
UPDATE dbo.servicio
SET precio_unitario = @precio_original
WHERE id_servicio = @id_serv;
GO

-- -----------------------------------------------------------------------------
-- PRUEBA 5: UPDATE irregular sobre precio_historico en turno (RN.05.1)
-- -----------------------------------------------------------------------------
PRINT '=== PRUEBA 5: UPDATE de precio_historico en turno ===';

DECLARE @id_t INT = (SELECT TOP 1 id_turno FROM dbo.turno ORDER BY id_turno);
DECLARE @precio_t_orig DECIMAL(10,2) = (SELECT precio_historico FROM dbo.turno WHERE id_turno = @id_t);

-- Modificación anómala
UPDATE dbo.turno
SET precio_historico = @precio_t_orig + 5000.00
WHERE id_turno = @id_t;

SELECT TOP 1 *
FROM dbo.auditoria
WHERE tabla_auditada = 'turno' AND operacion = 'UPDATE'
ORDER BY id_auditoria DESC;

-- Restauramos el valor legítimo
UPDATE dbo.turno
SET precio_historico = @precio_t_orig
WHERE id_turno = @id_t;
GO

-- -----------------------------------------------------------------------------
-- PRUEBA 6: UPDATE irregular sobre precio en detalle de venta contiene (RN.05)
-- -----------------------------------------------------------------------------
PRINT '=== PRUEBA 6: UPDATE de precio en contiene (detalle de venta) ===';

DECLARE @id_v INT, @id_p INT, @precio_c_orig DECIMAL(10,2);

SELECT TOP 1 
    @id_v = id_venta,
    @id_p = id_producto,
    @precio_c_orig = precio
FROM dbo.contiene
ORDER BY id_venta, id_producto;

-- Modificación anómala
UPDATE dbo.contiene
SET precio = @precio_c_orig * 0.80
WHERE id_venta = @id_v AND id_producto = @id_p;

SELECT TOP 1 *
FROM dbo.auditoria
WHERE tabla_auditada = 'contiene' AND operacion = 'UPDATE'
ORDER BY id_auditoria DESC;

-- Restauramos el valor legítimo
UPDATE dbo.contiene
SET precio = @precio_c_orig
WHERE id_venta = @id_v AND id_producto = @id_p;
GO

-- -----------------------------------------------------------------------------
-- PRUEBA 7: DELETE de producto de catálogo
-- -----------------------------------------------------------------------------
PRINT '=== PRUEBA 7: DELETE en producto ===';

DELETE FROM dbo.producto
WHERE nombre_producto = 'Producto Test Auditoria B';

SELECT TOP 1 *
FROM dbo.auditoria
WHERE tabla_auditada = 'producto' AND operacion = 'DELETE'
ORDER BY id_auditoria DESC;
GO

-- -----------------------------------------------------------------------------
-- PRUEBA 8: CONSULTA GENERAL DEL LOG DE AUDITORÍA
-- Vista consolidada de todas las acciones registradas en orden cronológico.
-- -----------------------------------------------------------------------------
PRINT '=== PRUEBA 8: ESTADO FINAL DEL LOG DE AUDITORÍA ===';

SELECT 
    id_auditoria,
    CONVERT(VARCHAR(19), fecha_hora, 120) AS fecha_hora,
    usuario,
    terminal,
    operacion,
    tabla_auditada,
    id_registro,
    columna_afectada,
    valor_anterior,
    valor_nuevo,
    detalle
FROM dbo.auditoria
ORDER BY id_auditoria ASC;
GO

-- Limpieza final de registros temporales para mantener la base limpia
DELETE FROM dbo.producto WHERE nombre_producto LIKE 'Producto Test Auditoria%';
GO

