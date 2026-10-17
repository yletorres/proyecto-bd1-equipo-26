# Comprobante de venta

**Script SQL:** [`sql/consultas/comprobante_venta.sql`](../../sql/consultas/comprobante_venta.sql)

## Necesidad de información

La recepcionista debe imprimir el comprobante de una venta con sus datos generales, los productos vendidos y el total.

## Estrategia SQL

Se divide en tres consultas sobre la misma venta (`id_venta`):

- **Encabezado:** `JOIN` entre `venta`, `cliente` y `persona` para obtener número, fecha, nombre del cliente y método de pago.
- **Detalle:** `JOIN` entre `contiene` y `producto`. Se usa el `precio` guardado en `contiene` (precio histórico, RN.05) y no el precio vigente del producto. El subtotal por renglón es `cantidad * precio`.
- **Total:** `SUM(cantidad * precio)` agrupado por `id_venta`.

## Resultado esperado

- El encabezado devuelve una fila.
- El detalle devuelve una fila por producto vendido.
- El total devuelve una única fila con el importe de la venta.

Ejemplo con los datos de prueba, venta 1: cliente Beatriz Almirón, pago en efectivo, 2 cremas hidratantes ($17.000) y 1 protector solar ($14.200). Total: **$31.200**.
