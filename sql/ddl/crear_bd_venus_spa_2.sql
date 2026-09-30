-- =============================================================================
-- Cátedra: Bases de Datos I - Lic. en Sistemas de Información (FaCENA - UNNE)
-- Proyecto: Venus Spa - Etapa III (Implementación Física)
-- Archivo: crear_bd_venus_spa_2.sql (Versión corregida, probada y optimizada)
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
-- LIMPIEZA PREVIA DE TABLAS (Orden inverso de dependencias para permitir re-ejecución)
-- =============================================================================
DROP TABLE IF EXISTS Contiene;
DROP TABLE IF EXISTS Se_Asigna_Turno;
DROP TABLE IF EXISTS Venta;
DROP TABLE IF EXISTS Turno;
DROP TABLE IF EXISTS Producto;
DROP TABLE IF EXISTS Servicio;
DROP TABLE IF EXISTS Camilla;
DROP TABLE IF EXISTS Cliente;
DROP TABLE IF EXISTS Profesional;
DROP TABLE IF EXISTS Persona;
GO

-- =============================================================================
-- 1. TABLA: Persona (Superentidad de Clientes y Profesionales - RN.01)
-- =============================================================================
CREATE TABLE Persona (
    DNI_persona      INT           NOT NULL,
    nombre_completo  VARCHAR(150)  NOT NULL,
    telefono_persona VARCHAR(30)   NOT NULL,
    CONSTRAINT PK_Persona PRIMARY KEY (DNI_persona)
);
GO

-- =============================================================================
-- 2. TABLA: Profesional (Subentidad - RN.01, RN.10)
-- =============================================================================
CREATE TABLE Profesional (
    DNI_profesional INT          NOT NULL,
    FechaDeIngreso  DATE         NOT NULL,
    Matricula       VARCHAR(50)  NULL,
    CONSTRAINT PK_Profesional PRIMARY KEY (DNI_profesional),
    CONSTRAINT FK_Profesional_Persona FOREIGN KEY (DNI_profesional)
        REFERENCES Persona (DNI_persona)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);
GO

-- Índice único filtrado para Matrícula opcional (RN.10)
CREATE UNIQUE NONCLUSTERED INDEX UQ_Profesional_Matricula 
ON Profesional(Matricula) 
WHERE Matricula IS NOT NULL;
GO

-- =============================================================================
-- 3. TABLA: Cliente (Subentidad - RN.01)
-- =============================================================================
CREATE TABLE Cliente (
    DNI_cliente       INT           NOT NULL,
    Direccion         VARCHAR(200)  NOT NULL,
    FechaDeNacimiento DATE          NOT NULL,
    CONSTRAINT PK_Cliente PRIMARY KEY (DNI_cliente),
    CONSTRAINT FK_Cliente_Persona FOREIGN KEY (DNI_cliente)
        REFERENCES Persona (DNI_persona)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);
GO

-- =============================================================================
-- 4. TABLA: Camilla (RN.02, RN.02.1)
-- =============================================================================
CREATE TABLE Camilla (
    id_camilla INT           IDENTITY(1, 1) NOT NULL,
    nombre     VARCHAR(100)  NOT NULL,
    CONSTRAINT PK_Camilla PRIMARY KEY (id_camilla)
);
GO

-- =============================================================================
-- 5. TABLA: Servicio (Catálogo de Servicios - RN.07)
-- =============================================================================
CREATE TABLE Servicio (
    id_servicio    INT            IDENTITY(1, 1) NOT NULL,
    Denominacion   VARCHAR(150)   NOT NULL,
    PrecioUnitario DECIMAL(10, 2) NOT NULL,
    CONSTRAINT PK_Servicio PRIMARY KEY (id_servicio),
    CONSTRAINT CK_Servicio_Precio CHECK (PrecioUnitario > 0)
);
GO

-- =============================================================================
-- 6. TABLA: Turno (RN.02.1, RN.03, RN.05.1, RN.06.1, RN.07, RN.09, RN.11)
-- =============================================================================
CREATE TABLE Turno (
    id_turno          INT            IDENTITY(1, 1) NOT NULL,
    FechaTurno        DATE           NOT NULL,
    FranjaHoraria     TIME(0)        NOT NULL,
    Estado            VARCHAR(20)    NOT NULL,
    Metodo_Pago_Turno VARCHAR(50)    NOT NULL,
    Precio_historico  DECIMAL(10, 2) NOT NULL,
    DNI_cliente       INT            NOT NULL,
    id_camilla        INT            NOT NULL,
    id_servicio       INT            NOT NULL,
    
    CONSTRAINT PK_Turno PRIMARY KEY (id_turno),
    
    -- RN.09: Estados válidos
    CONSTRAINT CK_Turno_Estado 
        CHECK (Estado IN ('pendiente', 'confirmado', 'realizado', 'cancelado')),
        
    -- RN.11: Franjas horarias válidas de una hora en punto
    CONSTRAINT CK_Turno_FranjaHoraria 
        CHECK (FranjaHoraria IN (
            '08:00:00', '09:00:00', '10:00:00', '11:00:00',
            '15:00:00', '16:00:00', '17:00:00', '18:00:00'
        )),
        
    -- RN.06.1: Métodos de pago válidos
    CONSTRAINT CK_Turno_MetodoPago 
        CHECK (Metodo_Pago_Turno IN (
            'efectivo', 'tarjeta de debito', 'tarjeta de credito', 'transferencia'
        )),
        
    -- RN.05.1: Precio histórico mayor a cero
    CONSTRAINT CK_Turno_PrecioHistorico 
        CHECK (Precio_historico > 0),
        
    -- Integridad referencial
    CONSTRAINT FK_Turno_Cliente FOREIGN KEY (DNI_cliente)
        REFERENCES Cliente (DNI_cliente)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
        
    CONSTRAINT FK_Turno_Camilla FOREIGN KEY (id_camilla)
        REFERENCES Camilla (id_camilla)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
        
    CONSTRAINT FK_Turno_Servicio FOREIGN KEY (id_servicio)
        REFERENCES Servicio (id_servicio)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
        
    -- RN.03: Un cliente solo puede tener 1 turno por fecha y franja horaria
    CONSTRAINT UQ_Turno_Cliente_Horario UNIQUE (FechaTurno, FranjaHoraria, DNI_cliente),
    
    -- RN.02.1: Una camilla solo puede tener 1 turno por fecha y franja horaria
    CONSTRAINT UQ_Turno_Camilla_Horario UNIQUE (FechaTurno, FranjaHoraria, id_camilla)
);
GO

-- =============================================================================
-- 7. TABLA: Se_Asigna_Turno (Relación N:M Profesional - Turno - RN.07.1)
-- =============================================================================
CREATE TABLE Se_Asigna_Turno (
    DNI_profesional INT NOT NULL,
    id_turno        INT NOT NULL,
    CONSTRAINT PK_SeAsignaTurno PRIMARY KEY (DNI_profesional, id_turno),
    CONSTRAINT FK_SeAsignaTurno_Profesional FOREIGN KEY (DNI_profesional)
        REFERENCES Profesional (DNI_profesional)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT FK_SeAsignaTurno_Turno FOREIGN KEY (id_turno)
        REFERENCES Turno (id_turno)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);
GO

-- =============================================================================
-- 8. TABLA: Venta (Cabecera de Ventas de Productos - RN.06, RN.08)
-- =============================================================================
CREATE TABLE Venta (
    id_venta          INT          IDENTITY(1, 1) NOT NULL,
    FechaVenta        DATE         NOT NULL,
    Metodo_Pago_Venta VARCHAR(50)  NOT NULL,
    DNI_cliente       INT          NOT NULL,
    CONSTRAINT PK_Venta PRIMARY KEY (id_venta),
    CONSTRAINT FK_Venta_Cliente FOREIGN KEY (DNI_cliente)
        REFERENCES Cliente (DNI_cliente)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT CK_Venta_MetodoPago 
        CHECK (Metodo_Pago_Venta IN (
            'efectivo', 'tarjeta de debito', 'tarjeta de credito', 'transferencia'
        ))
);
GO

-- =============================================================================
-- 9. TABLA: Producto (Catálogo de Productos - RN.04)
-- =============================================================================
CREATE TABLE Producto (
    id_producto      INT            IDENTITY(1, 1) NOT NULL,
    nombre_producto  VARCHAR(150)   NOT NULL,
    precio_vigente   DECIMAL(10, 2) NOT NULL,
    stock_disponible INT            NOT NULL,
    CONSTRAINT PK_Producto PRIMARY KEY (id_producto),
    CONSTRAINT CK_Producto_Precio CHECK (precio_vigente > 0),
    CONSTRAINT CK_Producto_Stock  CHECK (stock_disponible >= 0)
);
GO

-- =============================================================================
-- 10. TABLA: Contiene (Detalle de Venta N:M - RN.04, RN.05)
-- =============================================================================
CREATE TABLE Contiene (
    id_venta    INT            NOT NULL,
    id_producto INT            NOT NULL,
    cantidad    INT            NOT NULL,
    precio      DECIMAL(10, 2) NOT NULL,
    CONSTRAINT PK_Contiene PRIMARY KEY (id_venta, id_producto),
    CONSTRAINT FK_Contiene_Venta FOREIGN KEY (id_venta)
        REFERENCES Venta (id_venta)
        ON DELETE CASCADE
        ON UPDATE NO ACTION,
    CONSTRAINT FK_Contiene_Producto FOREIGN KEY (id_producto)
        REFERENCES Producto (id_producto)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT CK_Contiene_Cantidad CHECK (cantidad > 0),
    CONSTRAINT CK_Contiene_Precio   CHECK (precio > 0)
);
GO
