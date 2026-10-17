# Casos de uso

Situaciones reales del spa que resuelven las consultas de la Etapa IV. Los scripts están en `sql/consultas/`:

- [`comprobante_venta.sql`](../../sql/consultas/comprobante_venta.sql)
- [`informe_ventas.sql`](../../sql/consultas/informe_ventas.sql)
- [`consulta_avanzada.sql`](../../sql/consultas/consulta_avanzada.sql)

| Quién | Qué necesita | Consulta que lo resuelve | Documentación | Estado |
|---|---|---|---|---|
| Recepcionista | Imprimir el comprobante de una venta | Factura: encabezado, detalle y total | [comprobante-venta.md](comprobante-venta.md) | Hecho |
| Dueño | Saber qué productos se venden más | Ranking general con `GROUP BY` y `SUM` | [informe-ventas.md](informe-ventas.md) | Hecho |
| Dueño | Ver los 3 productos más vendidos del mes | `TOP 3 WITH TIES` filtrado por mes | [informe-ventas.md](informe-ventas.md) | Hecho |
| Dueño | Reactivar con una campaña por mail a clientes que no sacan turno hace más de 6 meses | `LEFT JOIN` + `HAVING` | [informe-ventas.md](informe-ventas.md) | Hecho |
| Dueño | Reconocer al profesional con más turnos realizados del mes | Subconsulta con `HAVING` | [consulta-avanzada.md](consulta-avanzada.md) | Hecho |
| Recepcionista | Enviar un saludo con descuento a los cumpleañeros del mes | `LEFT JOIN` + `HAVING` | [consulta-avanzada.md](consulta-avanzada.md) | Hecho |
| Dueño | Detectar clientes frecuentes para darles un descuento | `HAVING` con varias condiciones | [consulta-avanzada.md](consulta-avanzada.md) | Hecho |
| Dueño | Saber qué servicio recaudó más | Subconsulta con `HAVING` | [consulta-avanzada.md](consulta-avanzada.md) | Hecho |
| Recepcionista | Ver qué camillas están libres en una fecha y hora | Subconsulta con `NOT IN` | [consulta-avanzada.md](consulta-avanzada.md) | Hecho |
| Administración | Ver el precio con 10 % de descuento de los 3 productos menos vendidos de un período | `LEFT JOIN` + `ISNULL` | [consulta-avanzada.md](consulta-avanzada.md) | Hecho |
| Dueño | Comparar lo recaudado por turnos contra lo vendido en productos del mes anterior | Por definir | - | Pendiente |
| Dueño | Detectar qué pares de productos se compran juntos para armar combos | Por definir | - | Pendiente |
| Dueño | Premiar al "empleado del mes": profesional con más servicios atendidos el mes anterior | Por definir | - | Pendiente |
