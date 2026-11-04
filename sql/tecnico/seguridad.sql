-- =============================================================================
-- Cátedra: Bases de Datos I - Lic. en Sistemas de Información (FaCENA - UNNE)
-- Proyecto: Venus Spa - Etapa V (Implementación de temas técnicos)
-- Tema: Segurodad
-- Archivo: seguridad.sql
-- Motor: Microsoft SQL Server (Transact-SQL)
-- =============================================================================

USE Venus_Spa;
GO

-- =============================================================================
--1.1 Verificacion de Autenticacion con servidor
-- =============================================================================
SELECT
    SERVERPROPERTY('IsIntegratedSecurityOnly')
    AS autenticacion_solo_windows;
--Significado 0 modo mixto 1 modo windows

-- =============================================================================
--1.2 Creacion de los LOGINs 
-- Se crean los dos logins, para los usuarios de solo lectura y de administrador
-- =============================================================================
--LOGINs
IF NOT EXISTS (
    SELECT 1 FROM sys.server_principals
    WHERE name = 'login_admin_spa'
)
BEGIN
    CREATE LOGIN login_admin_spa
    WITH PASSWORD = 'Admin_Spa_2026!';
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.server_principals
    WHERE name = 'login_lectura_spa'
)
BEGIN
    CREATE LOGIN login_lectura_spa
    WITH PASSWORD = 'Lectura_Spa_2026!';
END;
GO

-- ============================================================================
--                      Permisos a nivel de Usuario
-- ============================================================================

-- =============================================================================
--  2. Creacion de Los Usuarios
--  Se crean dos usuarios, usuario_admin y usuario_lectura
-- ============================================================================
--USERs
IF NOT EXISTS (
    SELECT 1 FROM sys.database_principals
    WHERE name = 'usuario_admin'
)
BEGIN
    CREATE USER usuario_admin FOR LOGIN login_admin_spa;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.database_principals
    WHERE name = 'usuario_lectura'
)
BEGIN
    CREATE USER usuario_lectura FOR LOGIN login_lectura_spa;
END;
GO

--Verificacion si se crearon los usuarios correctamente
SELECT name, type_desc
FROM sys.database_principals
WHERE name IN ('usuario_admin', 'usuario_lectura')

-- =============================================================================
--  3. Asignacion de roles para los usuarios creados
--  Se asignan los roles db_owner y db_datareader para
--  el usuario lectura y usuario admin respectivamente
-- =============================================================================
-- Administrador
ALTER ROLE db_owner
ADD MEMBER usuario_admin;
GO

-- Usuario de solo lectura
ALTER ROLE db_datareader
ADD MEMBER usuario_lectura;
GO

-- =============================================================================
--  4. Asignacion de permiso para solo lectura
--  Se le asigna al usuario de solo lectura el procedimiento
--  dbo.usp_RegistrarTurno
-- =============================================================================
--Comprobacion de que existe el metodo solicitado
SELECT name, type_desc
FROM sys.objects
WHERE name = 'usp_RegistrarTurno';

-- Permitir ejecutar el procedimiento de registro
GRANT EXECUTE ON dbo.usp_RegistrarTurno
TO usuario_lectura;
GO

-- =============================================================================
-- 5. PRUEBAS DE PERMISOS Y RESTRICCIONES DE ACCESO
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 5.1 Verificar el acceso del administrador
-- -----------------------------------------------------------------------------
EXECUTE AS USER = 'usuario_admin';

SELECT USER_NAME() AS usuario_actual;

SELECT *
FROM turno;

REVERT;
GO

-- -----------------------------------------------------------------------------
-- 5.2 Verificar el acceso del usuario de solo lectura
-- -----------------------------------------------------------------------------
EXECUTE AS USER = 'usuario_lectura';

SELECT USER_NAME() AS usuario_actual;

SELECT *
FROM turno;

REVERT;
GO

-- -----------------------------------------------------------------------------
-- 5.3 Verificar que el usuario de lectura NO pueda insertar directamente
-- -----------------------------------------------------------------------------
DECLARE @contexto_cambiado BIT = 0;

BEGIN TRY

    -- Cambiamos al usuario de solo lectura
    EXECUTE AS USER = 'usuario_lectura';
    SET @contexto_cambiado = 1;

    -- Intentamos insertar directamente en turno
    INSERT INTO turno (
    fecha_turno,
    franja_horaria,
    estado,
    metodo_pago_turno,
    precio_historico,
    dni_cliente,
    id_camilla,
    id_servicio
    )
    VALUES (
    '2026-11-04',
    '08:00:00',
    'pendiente',
    'efectivo',
    15000.00,
    40123456,
    1,
    1
    );

    PRINT 'ERROR: El usuario pudo insertar directamente en turno.';

END TRY

BEGIN CATCH

    SELECT
        ERROR_NUMBER() AS numero_error,
        ERROR_MESSAGE() AS mensaje_error;

END CATCH;

-- Volvemos al usuario original, incluso si hubo un error
IF @contexto_cambiado = 1
BEGIN
    REVERT;
END;

GO
-- -----------------------------------------------------------------------------
-- 5.4 Verificar que el usuario admin pueda insertar datos
-- -----------------------------------------------------------------------------
EXECUTE AS USER = 'usuario_admin';

SELECT USER_NAME() AS usuario_actual;

INSERT INTO turno (
    fecha_turno,
    franja_horaria,
    estado,
    metodo_pago_turno,
    precio_historico,
    dni_cliente,
    id_camilla,
    id_servicio
)
VALUES (
    '2026-11-05',
    '08:00:00',
    'pendiente',
    'efectivo',
    15000.00,
    40123456,
    1,
    1
);

REVERT;
GO

--Verificacion de que se cargo exitosamente
SELECT *
FROM turno
WHERE fecha_turno = '2026-11-05'
  AND franja_horaria = '08:00:00';

-- -----------------------------------------------------------------------------
-- 5.5 Inserición por medio de procedimiento
-- registra un turno en modo usuario lectura por medio
-- del procedimiento correspondiente
-- -----------------------------------------------------------------------------
DECLARE @nuevo_id INT;

EXECUTE AS USER = 'usuario_lectura';

BEGIN TRY

    EXEC dbo.usp_RegistrarTurno
        @dni_cliente = 21295128,
        @id_camilla = 1,
        @id_servicio = 3,
        @dni_profesional = 28456123,
        @fecha_turno = '2026-11-10',
        @franja_horaria = '08:00',
        @metodo_pago = 'efectivo',
        @id_turno = @nuevo_id OUTPUT;

    REVERT;

    SELECT
        'Procedimiento ejecutado correctamente' AS resultado,
        @nuevo_id AS id_turno_generado;

END TRY
BEGIN CATCH

    REVERT;

    SELECT
        ERROR_NUMBER() AS numero_error,
        ERROR_MESSAGE() AS mensaje_error;

END CATCH;
GO

--Verificacion de inserción exitosa
SELECT *
FROM turno
WHERE fecha_turno = '2026-11-10'
  AND franja_horaria = '08:00';

SELECT *
FROM se_asigna_turno
WHERE id_turno = (
    SELECT id_turno
    FROM turno
    WHERE fecha_turno = '2026-11-10'
      AND franja_horaria = '08:00'
);

-- -----------------------------------------------------------------------------
-- 5.6 Revocar el permiso de ejecucion al usuario de solo lectura
-- Se le quita a usuario_lectura el permiso sobre dbo.usp_RegistrarTurno
-- y se comprueba que ya no puede ejecutarlo
-- -----------------------------------------------------------------------------
REVOKE EXECUTE ON dbo.usp_RegistrarTurno
FROM usuario_lectura;
GO

-- Comprobacion: el procedimiento ya no debe poder ejecutarse
DECLARE @nuevo_id INT;
DECLARE @contexto_cambiado BIT = 0;

BEGIN TRY

    EXECUTE AS USER = 'usuario_lectura';
    SET @contexto_cambiado = 1;

    EXEC dbo.usp_RegistrarTurno
        @dni_cliente = 21295128,
        @id_camilla = 1,
        @id_servicio = 3,
        @dni_profesional = 28456123,
        @fecha_turno = '2026-11-17',
        @franja_horaria = '08:00',
        @metodo_pago = 'efectivo',
        @id_turno = @nuevo_id OUTPUT;

    PRINT 'ERROR: El usuario pudo ejecutar el procedimiento tras el REVOKE.';

END TRY
BEGIN CATCH

    SELECT
        ERROR_NUMBER() AS numero_error,
        ERROR_MESSAGE() AS mensaje_error;

END CATCH;

IF @contexto_cambiado = 1
BEGIN
    REVERT;
END;
GO

-- ============================================================================
--                      Permisos a nivel de Roles DBMS
-- ============================================================================

-- ============================================================================
--  1.Creacion de Login
--  Crea los logins recepcionista, dueño y administracion
-- ============================================================================
--Se considera que el usuario_admin se va a reutilizar
USE master;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.server_principals
    WHERE name = 'login_dueno'
)
BEGIN
    CREATE LOGIN login_dueno
    WITH PASSWORD = 'Dueno_2026!';
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.server_principals
    WHERE name = 'login_recepcionista'
)
BEGIN
    CREATE LOGIN login_recepcionista
    WITH PASSWORD = 'Recepcion_2026!';
END;
GO

USE Venus_Spa;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.database_principals
    WHERE name = 'usuario_dueno'
)
BEGIN
    CREATE USER usuario_dueno
    FOR LOGIN login_dueno;
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.database_principals
    WHERE name = 'usuario_recepcionista'
)
BEGIN
    CREATE USER usuario_recepcionista
    FOR LOGIN login_recepcionista;
END;
GO
-- ============================================================================
--  2.Creacion de Roles
--  Crea los roles recepcionista, dueño y administracion
-- ============================================================================
USE Venus_Spa;
GO

-- Crear roles
IF NOT EXISTS (
    SELECT 1 FROM sys.database_principals
    WHERE name = 'rol_recepcionista'
)
BEGIN
    CREATE ROLE rol_recepcionista;
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.database_principals
    WHERE name = 'rol_dueno'
)
BEGIN
    CREATE ROLE rol_dueno;
END;

IF NOT EXISTS (
    SELECT 1 FROM sys.database_principals
    WHERE name = 'rol_administracion'
)
BEGIN
    CREATE ROLE rol_administracion;
END;
GO

-- ============================================================================
--  2.1 Configuracion Rol Recepcionista
--  Se le permite usar el procedimiento de registrar turnos
--  Pero no puedo realizar INSERTS ni DELETE directamente
-- ============================================================================
-- Puede ejecutar el procedimiento
GRANT EXECUTE ON dbo.usp_RegistrarTurno
TO rol_recepcionista;

-- No puede insertar directamente
DENY INSERT ON dbo.turno
TO rol_recepcionista;

-- No puede eliminar directamente
DENY DELETE ON dbo.turno
TO rol_recepcionista;
GO

-- ============================================================================
--  2.2 Configuracion Rol Dueño
--  Se le permite el SELECT para realizar informes
-- ============================================================================
-- Puede consultar los turnos para sus informes
GRANT SELECT ON dbo.turno
TO rol_dueno;
GO

-- ============================================================================
--  2.3 Configuracion Rol Administracion
--  Se le permite todo lo requerido para administrar la base de datos
-- ============================================================================
-- Permisos de lectura, inserción, modificación y eliminación
GRANT SELECT, INSERT, UPDATE, DELETE
ON SCHEMA::dbo
TO rol_administracion;
GO

-- Permiso para ejecutar procedimientos almacenados
GRANT EXECUTE
ON SCHEMA::dbo
TO rol_administracion;
GO

-- ============================================================================
--  2.4 Asociación de roles con sus usuarios
--  configura a los usuarios su determinado rol
-- ============================================================================
ALTER ROLE rol_dueno
ADD MEMBER usuario_dueno;

ALTER ROLE rol_recepcionista
ADD MEMBER usuario_recepcionista;
GO

--Se elimina el rol de db.owder ya que concedia permisos superiores
ALTER ROLE db_owner
DROP MEMBER usuario_admin;
GO

ALTER ROLE rol_administracion
ADD MEMBER usuario_admin;
GO

-- ============================================================================
--  3 Prueba de Dueño
-- ============================================================================
EXECUTE AS USER = 'usuario_dueno';

SELECT USER_NAME() AS usuario_actual;

-- Debería funcionar
SELECT * FROM turno;

-- Debería fallar
BEGIN TRY

    INSERT INTO turno (
        fecha_turno,
        franja_horaria,
        estado,
        metodo_pago_turno,
        precio_historico,
        dni_cliente,
        id_camilla,
        id_servicio
    )
    VALUES (
        '2026-11-12',
        '09:00',
        'pendiente',
        'efectivo',
        15000,
        21295128,
        1,
        3
    );

    PRINT 'ERROR: El dueño pudo insertar directamente en turno.';

END TRY
BEGIN CATCH

    SELECT
        ERROR_NUMBER() AS numero_error,
        ERROR_MESSAGE() AS mensaje_error;

END CATCH;

REVERT;
GO
-- ============================================================================
--  4 Prueba de Recepcionista
-- ============================================================================
EXECUTE AS USER = 'usuario_recepcionista';

SELECT USER_NAME() AS usuario_actual;

-- Debería fallar
BEGIN TRY

    INSERT INTO turno (
        fecha_turno,
        franja_horaria,
        estado,
        metodo_pago_turno,
        precio_historico,
        dni_cliente,
        id_camilla,
        id_servicio
    )
    VALUES (
        '2026-11-13',
        '10:00',
        'pendiente',
        'efectivo',
        15000,
        21295128,
        1,
        3
    );

    PRINT 'ERROR: El recepcionista pudo insertar directamente en turno.';

END TRY
BEGIN CATCH

    SELECT
        ERROR_NUMBER() AS numero_error,
        ERROR_MESSAGE() AS mensaje_error;

END CATCH;

REVERT;
GO

-- Debería fallar
DECLARE @contexto_cambiado BIT = 0;

BEGIN TRY

    EXECUTE AS USER = 'usuario_recepcionista';
    SET @contexto_cambiado = 1;

    SELECT USER_NAME() AS usuario_actual;

    SELECT * FROM turno;

    PRINT 'ERROR: El recepcionista pudo leer la tabla turno.';

END TRY
BEGIN CATCH

    SELECT
        ERROR_NUMBER() AS numero_error,
        ERROR_MESSAGE() AS mensaje_error;

END CATCH;

IF @contexto_cambiado = 1
BEGIN
    REVERT;
END;
GO

--Deberia Funcionar
DECLARE @nuevo_id INT;

EXECUTE AS USER = 'usuario_recepcionista';

BEGIN TRY

    EXEC dbo.usp_RegistrarTurno
        @dni_cliente = 21295128,
        @id_camilla = 1,
        @id_servicio = 3,
        @dni_profesional = 28456123,
        @fecha_turno = '2026-11-16',
        @franja_horaria = '08:00',
        @metodo_pago = 'efectivo',
        @id_turno = @nuevo_id OUTPUT;

    REVERT;

    SELECT
        'Procedimiento ejecutado correctamente' AS resultado,
        @nuevo_id AS id_turno_generado;

END TRY
BEGIN CATCH

    REVERT;

    SELECT
        ERROR_NUMBER() AS numero_error,
        ERROR_MESSAGE() AS mensaje_error;

END CATCH;
GO
-- ============================================================================
--  5 Prueba de Administracion
-- ============================================================================
EXECUTE AS USER = 'usuario_admin';

SELECT USER_NAME() AS usuario_actual;

-- Debería funcionar
SELECT * FROM turno;

-- Debería funcionar (si los datos cumplen las restricciones)
INSERT INTO turno (
    fecha_turno,
    franja_horaria,
    estado,
    metodo_pago_turno,
    precio_historico,
    dni_cliente,
    id_camilla,
    id_servicio
)
VALUES (
    '2026-11-15',
    '08:00',
    'pendiente',
    'efectivo',
    15000,
    21295128,
    1,
    3
);

REVERT;
GO