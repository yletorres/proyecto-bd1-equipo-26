# Etapa III: Implementación Física

En esta etapa se realizó la implementación física de la base de datos **Venus Spa** mediante scripts SQL para Microsoft SQL Server.

## 1. Script DDL – Data Definition Language

Se desarrolló el script DDL encargado de crear la estructura de la base de datos.

En este script se realizaron las siguientes tareas:

* Creación de las tablas correspondientes al modelo relacional.
* Definición de **claves primarias (PRIMARY KEY)** para identificar de forma única los registros.
* Definición de **claves foráneas (FOREIGN KEY)** para establecer la integridad referencial entre las tablas.
* Configuración de reglas de **borrado y modificación** de los registros relacionados.
* Definición de tipos de datos adecuados para cada atributo, como `INT`, `VARCHAR`, `DATE`, `TIME` y `DECIMAL`.
* Incorporación de restricciones `NOT NULL` para los atributos obligatorios.
* Incorporación de restricciones `UNIQUE` para evitar valores duplicados en los casos correspondientes.
* Incorporación de restricciones `CHECK` para validar los valores permitidos en determinados atributos.
* Definición de restricciones de unicidad para evitar, por ejemplo, la asignación de un mismo cliente o una misma camilla en un mismo horario.

De esta manera, el script permite crear la estructura de la base de datos y garantizar las principales reglas de integridad definidas para el sistema.

## 2. Script DML – Data Manipulation Language

Se desarrolló el script DML para realizar el poblado inicial de la base de datos con datos de prueba coherentes.

Se incorporaron registros en todas las tablas del sistema, respetando las relaciones establecidas mediante las claves foráneas. Los datos fueron seleccionados de manera que permitieran probar diferentes situaciones del sistema, como:

* Clientes y profesionales registrados.
* Diferentes servicios y sus precios.
* Camillas disponibles.
* Turnos con distintos estados y métodos de pago.
* Asignación de profesionales a turnos.
* Ventas realizadas por los clientes.
* Productos disponibles y sus respectivos precios y cantidades.
* Detalle de los productos incluidos en cada venta.

Se cargaron **al menos 8 registros por tabla**, superando en varios casos la cantidad mínima solicitada, con el objetivo de contar con un conjunto de datos suficiente para realizar pruebas sobre la base de datos.

## 3. Resultado de la implementación

Como resultado de esta etapa, se obtuvieron los scripts necesarios para:

* Crear la base de datos y sus tablas.
* Establecer las relaciones e integridad referencial.
* Validar los datos mediante restricciones.
* Cargar datos iniciales coherentes.
* Contar con una base de datos preparada para realizar consultas y pruebas posteriores.
