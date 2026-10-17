# Consultas avanzadas y casos de uso

**Script SQL:** [`sql/consultas/consulta_avanzada.sql`](../../sql/consultas/consulta_avanzada.sql)

Consultas que combinan varias tablas y usan subconsultas, `HAVING` con varias condiciones, `NOT IN` o expresiones de tabla común (CTE).

## 1. Profesional del mes

**Necesidad:** el dueño quiere reconocer al profesional que más turnos realizados tuvo en septiembre de 2026.

**Estrategia SQL:**

- `JOIN` entre `persona`, `profesional`, `se_asigna_turno` y `turno`, filtrando los turnos con estado `realizado` dentro del mes.
- `GROUP BY` por profesional con `COUNT(*)` de turnos.
- `HAVING COUNT(*) = (subconsulta)`: la subconsulta calcula la mayor cantidad de turnos realizados (`TOP (1)` con `ORDER BY COUNT(*) DESC`). En caso de empate se muestran todos los profesionales.

**Resultado esperado:** nombre del profesional y cantidad de turnos realizados. Con los datos de prueba: Camila Fernandez, con 14 turnos.

## 2. Cumpleañeros del mes

**Necesidad:** la recepcionista quiere enviar un saludo con un descuento a los clientes que cumplen años en el mes actual y ya compraron en el spa, como estrategia de fidelización.

**Estrategia SQL:**

- `JOIN` entre `persona` y `cliente`, y `LEFT JOIN` con `venta`.
- `WHERE MONTH(fecha_nacimiento) = MONTH(GETDATE())` para los cumpleaños del mes.
- `GROUP BY` por cliente con `COUNT(id_venta)` y `MAX(fecha_venta)`.
- `HAVING COUNT(id_venta) >= 1` para dejar solo a quienes compraron al menos una vez.
- `ORDER BY DAY(fecha_nacimiento)` para listarlos según el día del cumpleaños.

**Resultado esperado:** nombre, teléfono, fecha de nacimiento, cantidad de compras y fecha de la última compra de cada cliente que cumple años este mes y tiene compras, ordenados por día de cumpleaños.

## 3. Clientes frecuentes

**Necesidad:** el dueño quiere identificar a los clientes que más vienen al spa (al menos 4 turnos realizados y $60.000 o más gastados) para darles un descuento por fidelidad.

**Estrategia SQL:**

- `JOIN` entre `persona`, `cliente` y `turno`, filtrando los turnos `realizado`.
- `GROUP BY` por cliente con `COUNT(id_turno)`, `SUM(precio_historico)` y `MAX(fecha_turno)`.
- `HAVING` con dos condiciones: cantidad de turnos y total gastado.
- Orden por total gastado, de mayor a menor.

**Resultado esperado:** DNI, nombre, teléfono, turnos realizados, total gastado y último turno de cada cliente frecuente. Con los datos de prueba el primero es Antonella Herrera, con 11 turnos y $173.500.

## 4. Servicio con mayor recaudación

**Necesidad:** el dueño quiere saber qué servicio generó más dinero con turnos realizados, para planificar la compra de insumos y la disponibilidad de camillas.

**Estrategia SQL:**

- `JOIN` entre `servicio`, `turno` y `camilla`, filtrando los turnos `realizado`.
- `GROUP BY` por servicio con `COUNT(id_turno)` y `SUM(precio_historico)`.
- `HAVING SUM(...) = (subconsulta)`: la subconsulta obtiene la mayor recaudación por servicio (`TOP (1)` con `ORDER BY ... DESC`). Si hay empate, se muestran todos.

**Resultado esperado:** una fila con el servicio, la cantidad de turnos realizados y el total recaudado. Con los datos de prueba: PRP Facial, con 18 turnos y $450.000.

## 5. Camillas libres

**Necesidad:** la recepcionista quiere saber qué camillas están libres en una fecha y franja horaria determinadas, para asignar turnos nuevos sin superponerlos.

**Estrategia SQL:**

- Variables `@fecha_consulta` y `@franja_consulta` para elegir el horario.
- Subconsulta anidada con `NOT IN`: se buscan las camillas con turno `pendiente`, `confirmado` o `realizado` en ese horario, y la consulta principal devuelve las demás. Los turnos cancelados no ocupan camilla.

**Resultado esperado:** id y nombre de cada camilla disponible. Con el script tal como está (20/10/2026 a las 10:00) devuelve las 10 camillas, porque no hay turnos cargados a esa hora. Para ver el filtro en acción, hay que probar con una fecha y hora que tengan turnos.

## 6. Descuento del 10 % a los 3 productos menos vendidos

**Necesidad:** administración quiere impulsar la venta de los productos de baja rotación, aplicando un 10 % de descuento a los 3 menos vendidos en un período (por defecto, septiembre de 2026).

**Estrategia SQL:**

- Variables `@fecha_inicio` y `@fecha_fin` para definir el período.
- `LEFT JOIN` entre `producto`, `contiene` y `venta` con `ISNULL(SUM(cantidad), 0)`, para incluir también a los productos sin ventas.
- **Paso 1:** `SELECT TOP 3 ... ORDER BY unidades_vendidas ASC` para verificar cuáles son.
- **Paso 2:** una CTE (`WITH`) elige los 3 productos y un `UPDATE` multiplica su `precio_vigente` por 0,90.

**Resultado esperado:** el paso 1 muestra los 3 productos con su precio original y sus unidades vendidas. El paso 2 modifica esos precios. Con los datos de prueba, el menos vendido de septiembre es la Mascarilla de Arcilla Purificante, con 3 unidades.

> **Importante:** el paso 2 modifica datos. Si se ejecuta dos veces, el descuento se aplica dos veces. Además, si hay empate en el tercer puesto, `TOP 3` elige uno de los empatados.

> La consulta 2 depende de la fecha actual (`GETDATE()`). Las consultas 1 y 6 están fijadas en septiembre de 2026 y la 5 usa la fecha y hora que se escriban en las variables.
