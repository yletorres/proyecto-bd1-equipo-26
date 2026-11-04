# Triggers de auditoría

Etapa V: Implementación de temas técnicos · Proyecto Venus Spa · Equipo 26  
Motor: Microsoft SQL Server Express (Transact-SQL)  

Script de implementación y demostración: [`sql/tecnico/triggers_auditoria.sql`](../../../sql/tecnico/triggers_auditoria.sql)  
Capturas de ejecución: [`evidencias/`](evidencias/)  

---

## 1. Definición y objetivo

Un **trigger** (o disparador) es un bloque de código SQL asociado a una tabla que se ejecuta automáticamente cuando ocurre una operación de datos: `INSERT`, `UPDATE` o `DELETE` (UNNE, s. f.). A diferencia de los procedimientos almacenados, un trigger no se llama con `EXEC`, no recibe parámetros del usuario ni se puede saltear: se dispara solo cada vez que se tocan los datos de la tabla.

En este trabajo nos enfocamos en **triggers de auditoría**. Su objetivo es llevar un registro histórico de los cambios importantes que pasan en el sistema para responder siempre a cuatro preguntas básicas:
- **¿Quién?** Qué usuario de SQL Server hizo la modificación.
- **¿Cuándo?** La fecha y hora exacta del cambio.
- **¿Dónde?** En qué tabla y sobre qué registro puntual ocurrió.
- **¿Qué cambió?** Qué operación fue (`INSERT`, `UPDATE`, `DELETE`), qué columna se tocó, cuál era el valor anterior y cuál es el valor nuevo.

| | Restricción CHECK | Procedimiento almacenado | Trigger de auditoría (AFTER) |
|---|---|---|---|
| **Cuándo actúa** | Al validar los datos de la fila | Solo cuando la aplicación lo invoca explícitamente | Automáticamente, justo después de modificar la tabla |
| **Guarda historial** | No, solo permite o rechaza el cambio | Solo si se programa a mano dentro del procedimiento | Sí, guarda en una tabla de auditoría de forma desatendida |
| **Se puede esquivar** | No, es fija en la tabla | Sí, si alguien hace un `UPDATE` directo desde SSMS | No, salta siempre aunque se modifique la tabla a mano |
| **Acceso a valores viejos y nuevos** | No | Solo si hace una consulta previa | Sí, mediante las tablas del sistema `inserted` y `deleted` |

**Objetivo:** asegurar que en Venus Spa nadie pueda modificar precios o stock a escondidas, dejando siempre registrado quién hizo el cambio, cuándo y qué valor tenía antes.

---

## 2. Ventajas y aplicaciones

**Ventajas** (UNNE, s. f.):
- **Funciona en segundo plano:** la aplicación o la persona que usa el sistema no tiene que hacer nada extra; el trigger se encarga solo de registrar el movimiento.
- **Seguridad e integridad:** aunque un recepcionista, empleado o administrador entre directo con SQL Server Management Studio a modificar una fila con un `UPDATE`, el trigger salta igual y deja el registro.
- **Comparación de valores:** permite guardar el dato viejo y el dato nuevo, lo que facilita entender qué se corrigió o alteró.
- **Soporte para múltiples filas:** si se actualizan 10 filas de golpe, un trigger bien hecho puede auditar las 10 sin problemas.

**Desventajas y cuidados a tener en cuenta:**
- **Rendimiento:** cada vez que se inserta, modifica o borra, el motor tiene que escribir también en la tabla de auditoría. Si se abusa de los triggers o se programan mal, pueden poner lenta la base de datos.
- **Depuración:** como actúan "por detrás", a veces cuesta encontrar errores si un trigger falla, ya que cuando el trigger da error se cancela toda la operación del usuario.

**Buenas prácticas:**
- Programar siempre pensando en conjuntos de datos (`JOIN` entre `inserted` y `deleted`), nunca asumiendo que se modifica de a una sola fila.
- Usar `SET NOCOUNT ON` para que los mensajes internos de filas afectadas no interfieran con las aplicaciones.
- Usar la función `UPDATE(columna)` para que el trigger solo trabaje cuando realmente cambió la columna que nos interesa vigilar.

---

## 3. Implementación en SQL Server Express

### Tablas lógicas: `inserted` y `deleted`
Cuando se ejecuta una acción sobre una tabla con triggers, SQL Server crea temporalmente en memoria dos tablas especiales con la misma estructura que la tabla original (Microsoft, s. f.-b):

- **`inserted`:** contiene las filas nuevas que se insertaron con `INSERT`, o las filas con los valores nuevos tras un `UPDATE`.
- **`deleted`:** contiene las filas viejas que se borraron con `DELETE`, o las filas con los valores viejos antes de ser modificadas por un `UPDATE`.

| Operación | ¿Qué tiene `deleted`? | ¿Qué tiene `inserted`? |
|---|---|---|
| `INSERT` | Vacía | Las filas nuevas recién insertadas |
| `UPDATE` | Las filas con sus valores anteriores | Las mismas filas con sus valores nuevos |
| `DELETE` | Las filas que se acaban de borrar | Vacía |

### Funciones útiles del motor
- `SUSER_SNAME()`: devuelve el nombre del usuario de SQL Server conectado (Microsoft, s. f.-a).
- `HOST_NAME()`: devuelve el nombre de la computadora o terminal desde donde se ejecutó la consulta.
- `GETDATE()`: fecha y hora actual del sistema.
- `UPDATE(columna)`: devuelve verdadero si esa columna fue incluida en la sentencia `UPDATE`.

Estructura básica de un trigger de auditoría:

```sql
CREATE TRIGGER dbo.trg_nombre
ON dbo.tabla_origen
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Ejemplo para UPDATE uniendo inserted con deleted
    INSERT INTO dbo.auditoria (tabla_auditada, operacion, valor_anterior, valor_nuevo, ...)
    SELECT 'tabla_origen', 'UPDATE', d.precio, i.precio, ...
    FROM inserted i
    INNER JOIN deleted d ON i.id = d.id
    WHERE i.precio <> d.precio;
END;
GO
```

---

## 4. Caso concreto aplicado al sistema de ventas (Venus Spa)

En Venus Spa definimos una tabla central llamada `dbo.auditoria` y cuatro triggers sobre las tablas donde se maneja dinero, precios y mercadería:

| Objeto | Tipo | Qué audita | Regla de negocio que apoya |
|---|---|---|---|
| `dbo.auditoria` | Tabla de auditoría | Centraliza todos los registros históricos de cambios | Soporte general de auditoría |
| `trg_auditoria_producto` | Trigger AFTER INSERT, UPDATE, DELETE | Cambios en `precio_vigente`, `stock_disponible`, altas y bajas | RN.04 (stock) y RN.05 (catálogo) |
| `trg_auditoria_servicio` | Trigger AFTER INSERT, UPDATE, DELETE | Cambios en el `precio_unitario` y eliminación de tratamientos | Catálogo de servicios |
| `trg_auditoria_turno_precio` | Trigger AFTER UPDATE | Modificaciones sobre `precio_historico` en turnos | RN.05.1 (precio congelado en turno) |
| `trg_auditoria_contiene_precio` | Trigger AFTER UPDATE | Modificaciones sobre `precio` en renglones de venta ya cerradas | RN.05 (precio congelado en venta) |

**Criterio de elección:** usamos **triggers** en lugar de procedimientos almacenados porque los precios y el stock son datos muy sensibles. Un procedimiento se puede esquivar si alguien ejecuta un `UPDATE` a mano en la base, mientras que el trigger salta de forma obligatoria siempre.

### 4.1 Tabla central `dbo.auditoria`

**Problema:** necesitábamos un lugar común y prolijo donde guardar el historial de modificaciones sin ensuciar las tablas del negocio.

**Solución:** una tabla con columnas claras:
- `id_auditoria`: número secuencial para ordenar los eventos.
- `fecha_hora`: cuándo pasó (por defecto `GETDATE()`).
- `usuario`: quién lo hizo (por defecto `SUSER_SNAME()`).
- `terminal`: desde qué máquina (por defecto `HOST_NAME()`).
- `tabla_auditada`: nombre de la tabla (`producto`, `servicio`, `turno`, `contiene`).
- `operacion`: qué hizo (`INSERT`, `UPDATE` o `DELETE`).
- `id_registro`: el código o clave de la fila afectada.
- `columna_afectada`: la columna puntual que cambió (por ejemplo `precio_vigente`).
- `valor_anterior` y `valor_nuevo`: qué valor tenía antes y cuál tiene ahora.
- `detalle`: un texto corto explicando la acción.

### 4.2 `trg_auditoria_producto`

**Problema:** en Venus Spa se venden productos como cremas y sérums. Si alguien cambia el stock a mano sin una venta (RN.04) o sube el precio de lista (RN.05), el negocio necesita saber quién fue y qué valor tocó. También importa saber si se da de alta o de baja un producto.

**Solución:** un trigger sobre `dbo.producto` que vigila las altas, bajas y modificaciones. Si cambia `precio_vigente`, guarda el precio anterior y el nuevo. Si cambia `stock_disponible`, guarda las cantidades viejas y nuevas. Si es un `INSERT`, guarda los datos iniciales; y si es un `DELETE`, preserva los últimos valores del producto que se borró.

### 4.3 `trg_auditoria_servicio`

**Problema:** los tratamientos del spa (como limpiezas o PRP) tienen precios de lista. Modificar el precio de un servicio cambia lo que van a costar los turnos a futuro, por lo que debe quedar asentado.

**Solución:** un trigger sobre `dbo.servicio` que detecta cuando cambia `precio_unitario`, guardando el valor anterior, el nuevo y el nombre del servicio. También registra si se elimina un servicio del catálogo.

### 4.4 `trg_auditoria_turno_precio`

**Problema:** según la regla **RN.05.1**, cuando un cliente saca un turno, el precio del servicio queda congelado en la columna `precio_historico`. Nadie debería cambiar ese valor después, porque alteraría la recaudación real del turno.

**Solución:** un trigger sobre `dbo.turno` que se dispara ante un `UPDATE`. Si detecta que alguien modificó la columna `precio_historico`, guarda un aviso en auditoría con el precio que tenía, el precio nuevo y el DNI del cliente.

### 4.5 `trg_auditoria_contiene_precio`

**Problema:** según la regla **RN.05**, cuando se vende un producto, el precio unitario cobrado se congela en la tabla `contiene`. Cambiar ese precio después de que la venta se cerró sería una irregularidad grave.

**Solución:** un trigger sobre `dbo.contiene` ante `UPDATE`. Si alguien toca la columna `precio`, guarda en auditoría el número de venta, el producto, el precio cobrado original y el precio modificado.

---

## 5. Script de demostración y resultados obtenidos

En la Parte 3 de `sql/tecnico/triggers_auditoria.sql` armamos una serie de pruebas paso a paso. El script es repetible: borra los datos de prueba anteriores al empezar y limpia todo al terminar.

### Plan de pruebas ejecutado:

1. **Creación:** se crea la tabla `auditoria` y los 4 triggers sin errores.
2. **Prueba 1 (Alta de producto):** se inserta un producto de prueba y se verifica que aparezca en auditoría con operación `INSERT`.
3. **Prueba 2 (Cambio de precio y stock):** se hace un `UPDATE` cambiando el precio y el stock del producto; la auditoría muestra dos registros con los valores viejos y nuevos.
4. **Prueba 3 (Actualización multi-fila):** se actualizan dos productos al mismo tiempo con un 10% de aumento; se comprueba que el trigger audita ambas filas juntas.
5. **Prueba 4 (Cambio de arancel en servicio):** se modifica el precio de un servicio y se corrobora que se registre el arancel viejo y el nuevo.
6. **Prueba 5 (Precio histórico en turno):** se fuerza una modificación en `turno.precio_historico`; el trigger lo atrapa y deja asentado el cambio.
7. **Prueba 6 (Precio en detalle de venta):** se modifica el precio de un ítem en `contiene`; queda registrada la venta y el producto.
8. **Prueba 7 (Baja de producto):** se hace un `DELETE` del producto de prueba y se comprueba que sus datos no se perdieron, quedaron en `valor_anterior`.
9. **Prueba 8 (Log consolidado):** se consulta la tabla `auditoria` completa mostrando las 13 acciones ordenadas cronológicamente.

### Resumen de evidencias fotográficas:

| Prueba | Acción realizada | Qué muestra la captura | Archivo |
|---|---|---|---|
| **01** | Creación DDL | Mensaje de "Comandos completados correctamente" | `evidencias/01_creacion_tabla_y_triggers.png` |
| **02** | `INSERT` en producto | Fila de auditoría con operación `INSERT` y datos iniciales | `evidencias/02_insert_producto.png` |
| **03** | `UPDATE` precio y stock | Dos filas en auditoría mostrando valores viejos y nuevos | `evidencias/03_update_precio_stock_producto.png` |
| **04** | `UPDATE` multi-fila | Múltiples productos actualizados en una sola consulta | `evidencias/04_update_multifila_producto.png` |
| **05** | `UPDATE` en servicio | Variación del arancel en la tabla servicio | `evidencias/05_update_precio_servicio.png` |
| **06** | `UPDATE` en turno | Registro de cambio sobre el precio histórico del turno | `evidencias/06_update_precio_historico_turno.png` |
| **07** | `UPDATE` en contiene | Registro de cambio sobre el precio cobrado en la venta | `evidencias/07_update_precio_historico_contiene.png` |
| **08** | `DELETE` de producto | Operación `DELETE` preservando los datos borrados | `evidencias/08_delete_producto.png` |
| **09** | Consulta general | Vista completa del log con las 13 filas cronológicas | `evidencias/09_log_auditoria_consolidado.png` |

---

## Bibliografía

- Universidad Nacional del Nordeste, FaCENA. (s. f.). *Unidad 5. SQL y SQL Avanzado: Disparadores (Triggers)* [Guía de lectura]. Bases de Datos I, Lic. en Sistemas de Información.
- Microsoft. (s. f.-a). *CREATE TRIGGER (Transact-SQL)*. Microsoft Learn. https://learn.microsoft.com/en-us/sql/t-sql/statements/create-trigger-transact-sql
- Microsoft. (s. f.-b). *Usar las tablas inserted y deleted*. Microsoft Learn. https://learn.microsoft.com/es-es/sql/relational-databases/triggers/use-the-inserted-and-deleted-tables
- Microsoft. (s. f.-c). *UPDATE() (Transact-SQL)*. Microsoft Learn. https://learn.microsoft.com/en-us/sql/t-sql/functions/update-transact-sql
