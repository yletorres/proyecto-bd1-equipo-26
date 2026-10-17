# Informe de ventas y clientes (reportes agregados)

**Script SQL:** [`sql/consultas/informe_ventas.sql`](../../sql/consultas/informe_ventas.sql)

Reportes que solicita el dueño, resueltos con funciones de agregación (`GROUP BY`, `SUM`, `MAX`) y `HAVING`.

## 1. Productos más vendidos (ranking general)

**Necesidad:** saber qué productos se venden más para decidir cuáles reponer o promocionar.

**Estrategia SQL:** `JOIN` entre `producto`, `contiene` y `venta`, y `GROUP BY` por producto con `SUM(cantidad)` para las unidades vendidas y `SUM(cantidad * precio)` para el total recaudado. Se ordena de mayor a menor por unidades.

**Resultado esperado:** una fila por producto vendido, ordenada de mayor a menor, con sus unidades y lo recaudado. Considera todo el historial de ventas.

## 2. Top 3 de productos más vendidos del mes

**Necesidad:** conocer solo los productos estrella del mes en curso.

**Estrategia SQL:** la misma consulta, con un `WHERE` que filtra el mes y año actuales (`MONTH` y `YEAR` sobre `fecha_venta` comparados con `GETDATE()`) y `TOP 3 WITH TIES` para limitar el resultado e incluir los empatados en el tercer puesto.

**Resultado esperado:** los 3 productos con más unidades vendidas en el mes actual. Pueden ser más de 3 filas si hay empate. Si no hubo ventas en el mes, no devuelve filas.

## 3. Clientes inactivos

**Necesidad:** armar una campaña de reactivación por mail para los clientes que hace más de 6 meses que no sacan turno.

**Estrategia SQL:**

- `LEFT JOIN` entre `cliente` y `turno`, para no perder a los clientes que nunca tuvieron un turno.
- `GROUP BY` por cliente y `MAX(fecha_turno)` para obtener su último turno.
- `HAVING` para quedarse con los que no tienen ningún turno (`MAX(...) IS NULL`) o cuyo último turno es anterior a `DATEADD(MONTH, -6, GETDATE())`.

**Resultado esperado:** DNI, nombre y fecha del último turno de cada cliente inactivo, ordenados por esa fecha. Los que nunca sacaron turno aparecen con `NULL` en `ultimo_turno`.

> Las consultas 2 y 3 dependen de la fecha actual (`GETDATE()`), por lo que su resultado cambia con el tiempo.
