-- =============================================================================
-- Cátedra: Bases de Datos I - Lic. en Sistemas de Información (FaCENA - UNNE)
-- Proyecto: Venus Spa - Etapa III (Implementación Física)
-- Archivo: crear_bd_venus_spa.sql
-- Motor: Microsoft SQL Server (Transact-SQL)
-- =============================================================================

-- Creación de la base de datos si no existe
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'Venus_Spa')
BEGIN
    CREATE DATABASE Venus_Spa;
END;
GO

USE Venus_Spa;
GO

-- =============================================================================
-- LIMPIEZA PREVIA DE TABLAS
-- =============================================================================

DROP TABLE IF EXISTS contiene;
DROP TABLE IF EXISTS se_asigna_turno;
DROP TABLE IF EXISTS venta;
DROP TABLE IF EXISTS turno;
DROP TABLE IF EXISTS producto;
DROP TABLE IF EXISTS servicio;
DROP TABLE IF EXISTS camilla;
DROP TABLE IF EXISTS cliente;
DROP TABLE IF EXISTS profesional;
DROP TABLE IF EXISTS persona;
GO

-- =============================================================================
-- 1. TABLA: persona
-- =============================================================================

CREATE TABLE persona (
    dni_persona      INT          NOT NULL,
    nombre_completo  VARCHAR(150) NOT NULL,
    telefono_persona VARCHAR(30)  NOT NULL,

    CONSTRAINT pk_persona
        PRIMARY KEY (dni_persona)
);
GO

-- =============================================================================
-- 2. TABLA: profesional
-- =============================================================================

CREATE TABLE profesional (
    dni_profesional INT         NOT NULL,
    fecha_ingreso   DATE        NOT NULL,
    matricula       VARCHAR(50) NULL,

    CONSTRAINT pk_profesional
        PRIMARY KEY (dni_profesional),

    CONSTRAINT fk_profesional_persona
        FOREIGN KEY (dni_profesional)
        REFERENCES persona (dni_persona)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);
GO

-- Matrícula única cuando está informada
CREATE UNIQUE NONCLUSTERED INDEX uq_profesional_matricula
ON profesional(matricula)
WHERE matricula IS NOT NULL;
GO

-- =============================================================================
-- 3. TABLA: cliente
-- =============================================================================

CREATE TABLE cliente (
    dni_cliente        INT          NOT NULL,
    direccion          VARCHAR(200) NOT NULL,
    fecha_nacimiento   DATE         NOT NULL,

    CONSTRAINT pk_cliente
        PRIMARY KEY (dni_cliente),

    CONSTRAINT fk_cliente_persona
        FOREIGN KEY (dni_cliente)
        REFERENCES persona (dni_persona)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);
GO

-- =============================================================================
-- 4. TABLA: camilla
-- =============================================================================

CREATE TABLE camilla (
    id_camilla INT          IDENTITY(1,1) NOT NULL,
    nombre     VARCHAR(100) NOT NULL,

    CONSTRAINT pk_camilla
        PRIMARY KEY (id_camilla)
);
GO

-- =============================================================================
-- 5. TABLA: servicio
-- =============================================================================

CREATE TABLE servicio (
    id_servicio     INT           IDENTITY(1,1) NOT NULL,
    denominacion    VARCHAR(150)  NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,

    CONSTRAINT pk_servicio
        PRIMARY KEY (id_servicio),

    CONSTRAINT ck_servicio_precio
        CHECK (precio_unitario > 0)
);
GO

-- =============================================================================
-- 6. TABLA: turno
-- =============================================================================

CREATE TABLE turno (
    id_turno           INT           IDENTITY(1,1) NOT NULL,
    fecha_turno        DATE          NOT NULL,
    franja_horaria     TIME(0)       NOT NULL,
    estado             VARCHAR(20)   NOT NULL,
    metodo_pago_turno  VARCHAR(50)   NOT NULL,
    precio_historico   DECIMAL(10,2) NOT NULL,
    dni_cliente        INT           NOT NULL,
    id_camilla         INT           NOT NULL,
    id_servicio        INT           NOT NULL,

    CONSTRAINT pk_turno
        PRIMARY KEY (id_turno),

    -- RN.09: Estados válidos
    CONSTRAINT ck_turno_estado
        CHECK (estado IN (
            'pendiente',
            'confirmado',
            'realizado',
            'cancelado'
        )),

    -- RN.11: Franjas horarias válidas
    CONSTRAINT ck_turno_franja_horaria
        CHECK (franja_horaria IN (
            '08:00:00',
            '09:00:00',
            '10:00:00',
            '11:00:00',
            '15:00:00',
            '16:00:00',
            '17:00:00',
            '18:00:00'
        )),

    -- RN.06.1: Métodos de pago válidos
    CONSTRAINT ck_turno_metodo_pago
        CHECK (metodo_pago_turno IN (
            'efectivo',
            'tarjeta de debito',
            'tarjeta de credito',
            'transferencia'
        )),

    -- RN.05.1: Precio histórico mayor a cero
    CONSTRAINT ck_turno_precio_historico
        CHECK (precio_historico > 0),

    -- Integridad referencial
    CONSTRAINT fk_turno_cliente
        FOREIGN KEY (dni_cliente)
        REFERENCES cliente (dni_cliente)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,

    CONSTRAINT fk_turno_camilla
        FOREIGN KEY (id_camilla)
        REFERENCES camilla (id_camilla)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,

    CONSTRAINT fk_turno_servicio
        FOREIGN KEY (id_servicio)
        REFERENCES servicio (id_servicio)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,

    -- RN.03: Un cliente solo puede tener
    -- un turno por fecha y franja horaria
    CONSTRAINT uq_turno_cliente_horario
        UNIQUE (fecha_turno, franja_horaria, dni_cliente),

    -- RN.02.1: Una camilla solo puede tener
    -- un turno por fecha y franja horaria
    CONSTRAINT uq_turno_camilla_horario
        UNIQUE (fecha_turno, franja_horaria, id_camilla)
);
GO

-- =============================================================================
-- 7. TABLA: se_asigna_turno
-- Relación N:M entre profesional y turno
-- =============================================================================

CREATE TABLE se_asigna_turno (
    dni_profesional INT NOT NULL,
    id_turno        INT NOT NULL,

    CONSTRAINT pk_se_asigna_turno
        PRIMARY KEY (dni_profesional, id_turno),

    CONSTRAINT fk_se_asigna_turno_profesional
        FOREIGN KEY (dni_profesional)
        REFERENCES profesional (dni_profesional)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,

    CONSTRAINT fk_se_asigna_turno_turno
        FOREIGN KEY (id_turno)
        REFERENCES turno (id_turno)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);
GO

-- =============================================================================
-- 8. TABLA: venta
-- =============================================================================

CREATE TABLE venta (
    id_venta          INT         IDENTITY(1,1) NOT NULL,
    fecha_venta       DATE        NOT NULL,
    metodo_pago_venta VARCHAR(50) NOT NULL,
    dni_cliente       INT         NOT NULL,

    CONSTRAINT pk_venta
        PRIMARY KEY (id_venta),

    CONSTRAINT fk_venta_cliente
        FOREIGN KEY (dni_cliente)
        REFERENCES cliente (dni_cliente)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,

    CONSTRAINT ck_venta_metodo_pago
        CHECK (metodo_pago_venta IN (
            'efectivo',
            'tarjeta de debito',
            'tarjeta de credito',
            'transferencia'
        ))
);
GO

-- =============================================================================
-- 9. TABLA: producto
-- =============================================================================

CREATE TABLE producto (
    id_producto      INT           IDENTITY(1,1) NOT NULL,
    nombre_producto  VARCHAR(150)  NOT NULL,
    precio_vigente   DECIMAL(10,2) NOT NULL,
    stock_disponible INT           NOT NULL,

    CONSTRAINT pk_producto
        PRIMARY KEY (id_producto),

    CONSTRAINT ck_producto_precio
        CHECK (precio_vigente > 0),

    CONSTRAINT ck_producto_stock
        CHECK (stock_disponible >= 0)
);
GO

-- =============================================================================
-- 10. TABLA: contiene
-- Detalle de venta N:M
-- =============================================================================

CREATE TABLE contiene (
    id_venta    INT           NOT NULL,
    id_producto INT           NOT NULL,
    cantidad    INT           NOT NULL,
    precio      DECIMAL(10,2) NOT NULL,

    CONSTRAINT pk_contiene
        PRIMARY KEY (id_venta, id_producto),

    CONSTRAINT fk_contiene_venta
        FOREIGN KEY (id_venta)
        REFERENCES venta (id_venta)
        ON DELETE CASCADE
        ON UPDATE NO ACTION,

    CONSTRAINT fk_contiene_producto
        FOREIGN KEY (id_producto)
        REFERENCES producto (id_producto)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,

    CONSTRAINT ck_contiene_cantidad
        CHECK (cantidad > 0),

    CONSTRAINT ck_contiene_precio
        CHECK (precio > 0)
);
GO
