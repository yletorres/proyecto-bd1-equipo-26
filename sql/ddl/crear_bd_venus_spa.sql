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
	DNI_profesional INT NOT NULL,
	FechaDeIngreso DATE NOT NULL,
	Matricula VARCHAR (50) NULL, 							
	CONSTRAINT FK_profesional_persona 
		FOREIGN KEY (DNI_profesional) 
		REFERENCES Persona (DNI_persona),
	CONSTRAINT PK_profesional PRIMARY KEY (DNI_profesional)
);
GO
	--Para permitir varias matrículas vacías (NULL), pero impedir que se repita una matrícula cargada.
CREATE UNIQUE INDEX UQ_Profesional_Matricula 
ON Profesional(Matricula)
WHERE Matricula IS NOT NULL;
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
	id_camilla INT IDENTITY(1, 1),		--la cantidad de camillas puede aumentar a medida que el spa crece
	nombre VARCHAR(100) NOT NULL,		--no se permite registrar una camilla sin nombre							
	CONSTRAINT PK_camilla PRIMARY KEY (id_camilla)
);
GO

/*
=========================
DDL - Creacion de tabla Servicio
Proyecto: Venus Spa
Descripción: Representa un servicio
en que ofrece Venus Spa
=========================
*/
CREATE TABLE Servicio(
	id_servicio INT IDENTITY(1, 1),
	Denominacion VARCHAR(150) NOT NULL,	
	PrecioUnitario DECIMAL(10, 2) NOT NULL,							
	CONSTRAINT PK_servicio PRIMARY KEY (id_servicio),
	CONSTRAINT CK_precio_servicio CHECK (PrecioUnitario > 0)		
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
	FranjaHoraria TIME (0) NOT NULL, --PARA QUE EL SQL entienda que se esta guardando una hora
	Estado VARCHAR (20) NOT NULL,										
	Metodo_Pago_Turno VARCHAR (50) NOT NULL,
	Precio_historico DECIMAL(10, 2) NOT NULL,					--Ver, cambio a DECIMAL para mejor toma de los decimales, y tambien ver posibilidad de Check >0
	DNI_cliente INT NOT NULL,
	id_camilla INT NOT NULL,
	id_servicio INT NOT NULL,
	
	CONSTRAINT PK_Turno PRIMARY KEY (id_turno),
	--RN.09 define exactamente cuatro estados posibles: pendiente, confirmado, realizado o cancelado.
	 CONSTRAINT CK_Turno_Estado
    	CHECK (Estado IN ('pendiente', 'confirmado', 'realizado', 'cancelado')),
	--RN.11
	CONSTRAINT CK_Turno_FranjaHoraria
		CHECK (FranjaHoraria IN (
				'08:00',
				'09:00',
				'10:00',
				'11:00',
				'15:00',
				'16:00',
				'17:00',
				'18:00'
			) ),
	--RN 06.1
	CONSTRAINT CK_Turno_MetodoPago
		CHECK (
			Metodo_Pago_Turno IN (
				'efectivo',
				'tarjeta de debito',
				'tarjeta de credito',
				'transferencia'
			)
		),
	-- RN.05.1
	CONSTRAINT CK_Turno_PrecioHistorico
		CHECK (
			Precio_historico IS NULL
			OR Precio_historico > 0
		),
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
	DNI_profesional INT NOT NULL,
	id_turno INT NOT NULL,
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
	Metodo_Pago_Venta VARCHAR (50) NOT NULL,
	DNI_cliente INT NOT NULL,
	CONSTRAINT PK_Venta 
		PRIMARY KEY (id_venta),

	CONSTRAINT FK_Venta_Cliente
		FOREIGN KEY (DNI_cliente)
		REFERENCES Cliente (DNI_cliente),

	CONSTRAINT CK_Venta_MetodoPago
	--RN.06, que establece que toda venta debe registrar un único método de pago entre esas opciones.
		CHECK ( Metodo_Pago_Venta IN (
				'efectivo',
				'tarjeta de debito',
				'tarjeta de credito',
				'transferencia')	)
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
	precio_vigente DECIMAL(10, 2) NOT NULL,				
	stock_disponible INT NOT NULL,						
	CONSTRAINT PK_producto PRIMARY KEY (id_producto),
	CONSTRAINT CK_Producto_Precio
	CHECK (precio_vigente > 0), 
	CONSTRAINT CK_Producto_Stock --RN.04 exige registrar stock y además que nunca pueda venderse una cantidad mayor a la disponible.
	CHECK (stock_disponible >= 0)
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
	id_venta INT NOT NULL, --toda fila de Contiene debe pertenecer a una venta.
	id_producto INT NOT NULL,--toda fila debe indicar qué producto se vendió
	cantidad INT NOT NULL,
	precio DECIMAL(10,2) NOT NULL,						--Ver, cambio a DECIMAL para mejor toma de los decimal y check >0
	CONSTRAINT PK_Contiene_Venta_Producto
		PRIMARY KEY (id_venta, id_producto),

	CONSTRAINT FK_Contiene_Venta
		FOREIGN KEY (id_venta)
		REFERENCES Venta(id_venta),
	
	CONSTRAINT FK_Contiene_Producto
		FOREIGN KEY (id_producto)
		REFERENCES Producto(id_producto),

	CONSTRAINT CK_Contiene_Cantidad
		CHECK (cantidad > 0), --no permite cantidades 0 ni negativas.

	CONSTRAINT CK_Contiene_Precio
		CHECK (precio > 0) --no permite precios 0 ni negativos.
);
GO
