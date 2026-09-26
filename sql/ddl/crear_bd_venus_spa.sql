--Crea la base de datos del sistema Venus Spa
CREATE DATABASE Venus_Spa;
GO 

--Crea las siguientes tablas en la base de datos Venus_Spa
USE Venus_Spa;
GO


/*
=========================
DDL - Creacion de tabla Persona
Proyecto: Venus Spa
Descripción: Representa una persona
en el sistema de Venus Spa
=========================
*/
CREATE TABLE Persona(
	DNI_persona INT,
	nombre_completo VARCHAR (150) NOT NULL,
	telefono_persona VARCHAR (30) NOT NULL,
	CONSTRAINT PK_persona PRIMARY KEY (DNI_persona)
);
GO

/*
=========================
DDL - Creacion de tabla Profesional
Proyecto: Venus Spa
Descripción: Representa un profesional
en el sistema de Venus Spa
=========================
*/
CREATE TABLE Profesional(
	DNI_profesional INT,
	FechaDeIngreso DATE NOT NULL,
	Matricula VARCHAR (50) NULL,							--Ver si debe ser unico
	CONSTRAINT FK_profesional_persona 
		FOREIGN KEY (DNI_profesional) 
		REFERENCES Persona (DNI_persona),
	CONSTRAINT PK_profesional PRIMARY KEY (DNI_profesional)
);
GO

/*
=========================
DDL - Creacion de tabla Cliente
Proyecto: Venus Spa
Descripción: Representa un cliente
en el sistema de Venus Spa
=========================
*/
CREATE TABLE Cliente(
	DNI_cliente INT NOT NULL,
	Direccion VARCHAR (200) NOT NULL,
	FechaDeNacimiento DATE NOT NULL,
	CONSTRAINT FK_cliente_persona 
		FOREIGN KEY (DNI_cliente) 
		REFERENCES Persona (DNI_persona),
	CONSTRAINT PK_cliente PRIMARY KEY (DNI_cliente)
);
GO

/*
=========================
DDL - Creacion de tabla Camilla
Proyecto: Venus Spa
Descripción: Representa una camilla
en el sistema de Venus Spa
=========================
*/
CREATE TABLE Camilla(
	id_camilla INT IDENTITY(1, 1),							--Ver si es incremental
	nombre VARCHAR(100),									--Ver si es NOT NULL
	CONSTRAINT PK_camilla PRIMARY KEY (id_camilla)
);
GO

/*
=========================
DDL - Creacion de tabla Servicio
Proyecto: Venus Spa
Descripción: Representa una servicio
en que ofrece Venus Spa
=========================
*/
CREATE TABLE Servicio(
	id_servicio INT IDENTITY(1, 1),
	Denominacion VARCHAR(150) NOT NULL,	
	PrecioUnitario DECIMAL(10, 2) NOT NULL,							--Ver, cambio a DECIMAL para mejor toma de los decimales
	CONSTRAINT PK_servicio PRIMARY KEY (id_servicio),
	CONSTRAINT CK_precio_servicio CHECK (PrecioUnitario > 0)		--Ver si poner check
);
GO


/*
=========================
DDL - Creacion de tabla Turno
Proyecto: Venus Spa
Descripción: Representa un Turno
de un cliente en el sistema de Venus Spa
=========================
*/
CREATE TABLE Turno(
	id_turno INT IDENTITY(1, 1),
	FechaTurno DATE NOT NULL,
	FranjaHoraria VARCHAR (50) NOT NULL,
	Estado VARCHAR (20) NOT NULL,										--Ver si tiene default
	Metodo_Pago_Turno VARCHAR (50) NOT NULL,
	Precio_historico DECIMAL(10, 2) NOT NULL,							--Ver, cambio a DECIMAL para mejor toma de los decimales, y tambien ver posibilidad de Check >0
	DNI_cliente INT NOT NULL,
	id_camilla INT NOT NULL,
	id_servicio INT NOT NULL,
	CONSTRAINT PK_Turno PRIMARY KEY (id_turno),
	CONSTRAINT FK_Turno_Cliente
		FOREIGN KEY (DNI_cliente)
		REFERENCES CLiente(DNI_cliente),
	CONSTRAINT FK_Turno_Camilla
		FOREIGN KEY (id_camilla)
		REFERENCES Camilla (id_camilla),
	CONSTRAINT FK_Turno_Servicio
		FOREIGN KEY (id_servicio)
		REFERENCES Servicio(id_servicio),
	CONSTRAINT UQ_Fecha_Franja_Cliente
		UNIQUE (FechaTurno, FranjaHoraria, DNI_cliente),
	CONSTRAINT UQ_Fecha_Franja_Camilla
		UNIQUE (FechaTurno, FranjaHoraria, id_camilla)
);
GO

/*
=========================
DDL - Creacion de tabla Se_asigna_turno
Proyecto: Venus Spa
Descripción: Representa la relacion
profesional-turno de N:M
=========================
*/
CREATE TABLE Se_Asigna_Turno(
	DNI_profesional INT,
	id_turno INT,
	CONSTRAINT FK_Asigna_Profesional
		FOREIGN KEY (DNI_profesional)
		REFERENCES Profesional (DNI_profesional),
	CONSTRAINT FK_Asigna_Turno
		FOREIGN KEY (id_turno)
		REFERENCES Turno (id_turno),
	CONSTRAINT PK_Asigna_Profesional_Turno
		PRIMARY KEY (DNI_profesional, id_turno)
);
GO

 /*
=========================
DDL - Creacion de tabla Venta
Proyecto: Venus Spa
Descripción: Representa las ventas
de productos de Venus Spa
=========================
*/
CREATE TABLE Venta(
	id_venta INT IDENTITY(1, 1), 
	FechaVenta DATE NOT NULL,
	Metodo_Pago_Venta VARCHAR (150) NOT NULL,
	DNI_cliente INT NOT NULL,
	CONSTRAINT FK_Venta_Cliente
		FOREIGN KEY (DNI_cliente)
		REFERENCES Cliente (DNI_cliente),
	CONSTRAINT PK_Venta PRIMARY KEY (id_venta)
);
GO

 /*
=========================
DDL - Creacion de tabla Producto
Proyecto: Venus Spa
Descripción: Representa los productos
a la venta de Venus Spa
=========================
*/
CREATE TABLE Producto(
	id_producto INT IDENTITY(1, 1),
	nombre_producto VARCHAR (150) NOT NULL,
	precio_vigente DECIMAL(10, 2) NOT NULL,				--Ver, cambio a DECIMAL para mejor toma de los decimal y check >0
	stock_disponible INT NOT NULL,						--Ver check
	CONSTRAINT PK_producto PRIMARY KEY (id_producto)
);
GO

 /*
=========================
DDL - Creacion de tabla contenido
Proyecto: Venus Spa
Descripción: Representa el contenido
de productos dentro de la venta
=========================
*/
CREATE TABLE Contiene(
	id_venta INT,
	id_producto INT,
	cantidad INT NOT NULL,
	precio DECIMAL(10,2) NOT NULL,						--Ver, cambio a DECIMAL para mejor toma de los decimal y check >0
	CONSTRAINT FK_Contiene_Venta
		FOREIGN KEY (id_venta)
		REFERENCES Venta (id_venta),
	CONSTRAINT FK_Contiene_Producto
		FOREIGN KEY (id_producto)
		REFERENCES Producto(id_producto),
	CONSTRAINT PK_Contiene_Venta_Producto
		PRIMARY KEY (id_venta, id_producto)
);
GO