#### ***# Etapa V – Optimización de consultas mediante índices***



\*\*Proyecto:\*\* Venus Spa

\*\*Equipo:\*\* 26

Optimización de consultas mediante índices



##### ***## 1. Definición y objetivo***



Los índices son estructuras que permiten buscar información de manera más rápida dentro de una base de datos, evitando tener que recorrer todos los registros de una tabla.

Su objetivo principal es mejorar el rendimiento de las consultas, especialmente cuando se trabaja con grandes cantidades de datos.



Existen distintos tipos de índices:



\- CLUSTERED (agrupado): organiza los datos de la tabla según las columnas del índice. Solo puede existir uno por tabla.

\- NONCLUSTERED (no agrupado): crea una estructura independiente para facilitar las búsquedas, sin modificar la organización de la tabla.

\- Compuesto: utiliza dos o más columnas como clave del índice.



##### ***## 2. Ventajas y aplicaciones***



Los índices permiten reducir las lecturas realizadas por SQL Server, acelerar las búsquedas y mejorar el rendimiento de las consultas.

En Venus Spa pueden utilizarse para consultar las ventas realizadas durante un período determinado o buscar turnos por fecha.



Como desventaja, ocupan espacio de almacenamiento y pueden hacer más lentas algunas operaciones de inserción, modificación o eliminación de registros.



##### ***## 3. Implementación en SQL Server Express***



Se utilizaron las siguientes instrucciones:



\- `CREATE CLUSTERED INDEX`: permite crear índices agrupados.

\- `DROP INDEX`: elimina un índice existente.

\- `SET STATISTICS IO ON`: muestra las lecturas realizadas por SQL Server.

\- `SET STATISTICS TIME ON`: muestra los tiempos de ejecución.

\- Plan de ejecución actual: permite observar cómo SQL Server realiza la búsqueda.



Estas herramientas permitieron comparar el comportamiento de una misma consulta con y sin índices.



##### ***## 4. Caso práctico en Venus Spa***



Se planteó la necesidad de consultar las ventas realizadas durante un período específico.



Para no modificar los datos originales de Venus Spa, se creó una tabla independiente llamada `venta\\\_prueba\\\_indices`, con los campos id\\\_venta, fecha\\\_venta e importe.



Se cargaron automáticamente 1.000.000 de registros ficticios y se utilizó la misma consulta en todas las pruebas: las ventas realizadas del 1 al 7 de septiembre de 2025.



##### ***## 5. Pruebas realizadas***



###### \### Prueba 1. Carga masiva de registros



Se creó la tabla `venta\\\_prueba\\\_indices` y se cargaron automáticamente 1.000.000 de registros para realizar las pruebas de rendimiento.



Evidencia:01\_carga\_masiva.png



###### \### Prueba 2. Consulta sin índice



Se consultaron las ventas del período seleccionado. SQL Server realizó un recorrido de tabla (\*Table Scan\*), con 3.585 lecturas lógicas y un tiempo de 213 ms.



Evidencias: 02\_consulta\_sin\_indice\_mensajes.png y 03\_plan\_sin\_indice.png



###### \### Prueba 3. Consulta con índice CLUSTERED



Se creó un índice agrupado sobre `fecha\\\_venta` y se repitió la misma consulta.



Las lecturas lógicas disminuyeron de 3.585 a 36 y el tiempo de ejecución pasó de 213 ms a 4 ms. El plan mostró una búsqueda mediante índice agrupado (\*Clustered Index Seek\*).



Evidencias: 04\_indice\_clustered.png, 05\_consulta\_clustered\_mensajes.png y 06\_plan\_clustered.png



###### \### Prueba 4. Eliminación del primer índice



Se eliminó el índice `idx\\\_venta\\\_prueba\\\_fecha` para realizar una nueva comparación. Se verificó que el índice ya no existía, sin eliminar los registros de la tabla.



Evidencia: 07\_eliminacion\_indice\_clustered.png



###### \### Prueba 5. Creación del índice CLUSTERED compuesto



Se creó un segundo índice agrupado llamado `idx\\\_venta\\\_prueba\\\_fecha\\\_importe`, utilizando las columnas `fecha\\\_venta` e `importe`.



Se verificó que el índice se había creado correctamente.



Evidencia: 08\_indice\_clustered\_compuesto.png



###### \### Prueba 6. Consulta con índice CLUSTERED compuesto



Se repitió la misma consulta utilizando el segundo índice.



Se obtuvieron 30 lecturas lógicas y un tiempo de ejecución de 34 ms. El plan mostró nuevamente una búsqueda mediante índice agrupado (\*Clustered Index Seek\*).



Evidencia: 09\_consulta\_clustered\_compuesto\_mensajes.png y 10\_plan\_clustered\_compuesto.png



El código completo de las pruebas se encuentra en `sql/tecnico/indices\\\_optimizacion.sql`.



##### ***## 6. Comparación de resultados***



|Medicion|Sin indice|CLUSTERED simple| CLUSTERED compuesto|
|-|-|-|-|
|Ventas encontradas|7.000|7.000|7.000|
|Lecturas lógicas  | 3.585|36|30|
|Lecturas fisicas|224|0|0|
|Tiempo de CPU|172 ms|16ms|0ms|

|Tiempo trasncurrido|213 ms|4 ms|34 ms|
|-|-|-|-|
|Plan de ejecución | Table Scan| Index Seek| Index Seek|



En las tres pruebas se obtuvieron los mismos resultados: 7.000 ventas y un total de $10.496.500.



El índice compuesto realizó menos lecturas lógicas, mientras que el índice simple presentó el menor tiempo de ejecución en las mediciones realizadas.



Los tiempos pueden variar entre ejecuciones, por lo que también se tuvieron en cuenta las lecturas y los planes de ejecución.



##### ***## 7. Conclusión***



A partir de las pruebas realizadas, pudimos comprobar que los índices mejoran considerablemente el rendimiento de las consultas cuando trabajamos con grandes cantidades de datos.



Sin índices, SQL Server tuvo que recorrer la tabla para encontrar la información. En cambio, al utilizar índices agrupados, logró realizar búsquedas más eficientes y reducir la cantidad de lecturas.



También observamos que agregar más columnas a un índice no siempre significa obtener mejores tiempos de ejecución.



En conclusión, aprendimos que es importante elegir los índices según las consultas que necesita realizar el sistema y comprobar su rendimiento mediante pruebas.

