# Procedimientos y funciones almacenadas

Etapa V: Implementación de temas técnicos · Proyecto Venus Spa · Equipo 26
Motor: Microsoft SQL Server Express (Transact-SQL)

Script de implementación y demostración: [`sql/tecnico/procedimientos_funciones.sql`](../../../sql/tecnico/procedimientos_funciones.sql)
Capturas de ejecución: [`evidencias/`](evidencias/)

---

## 1. Definición y objetivo

Las funciones y los procedimientos almacenados son bloques de código SQL, a menudo extendidos con lógica procedimental (variables, condicionales, manejo de errores), que se guardan directamente en la base de datos. Una vez creados, pueden ser ejecutados repetidamente por distintas aplicaciones o usuarios. Funcionan como subrutinas o métodos de la base de datos y encapsulan la lógica de negocio (UNNE, s. f.).

En SQL Server (Transact-SQL) se crean con `CREATE PROCEDURE` y `CREATE FUNCTION`.

| | Procedimiento almacenado | Función almacenada |
|---|---|---|
| Qué devuelve | Puede devolver o no un conjunto de resultados; además admite parámetros de salida (`OUTPUT`) | Siempre devuelve un valor: un único valor (escalar) o una tabla |
| Cómo se invoca | `EXEC nombre ...` | Dentro de una consulta: `SELECT`, `WHERE`, etc. |
| Qué puede hacer | Insertar, actualizar y eliminar datos; ejecutar lógica compleja | Calcular y consultar; en general no modifica datos |

**Objetivo:** centralizar en el motor las reglas y cálculos que se repiten, para que se apliquen siempre de la misma manera sin depender de cada aplicación cliente.

## 2. Ventajas y aplicaciones

**Ventajas** (UNNE, s. f.):

- **Rendimiento:** se almacenan en el servidor y su plan de ejecución puede reutilizarse.
- **Modularidad y reutilización:** la lógica se escribe una vez y la usan múltiples aplicaciones.
- **Seguridad:** se puede otorgar permiso de ejecutar un procedimiento sin dar acceso directo a las tablas subyacentes.
- **Consistencia:** la lógica de negocio se aplica de la misma forma en toda la aplicación.
- **Menos tráfico de red:** el cliente envía una sola llamada en vez de varias sentencias.

**Aplicaciones habituales:** validar datos complejos, realizar cálculos comerciales, implementar lógica de negocio crítica, auditoría y automatización de tareas.

**Buenas prácticas y trampas a evitar:** dividir la lógica en piezas pequeñas, incluir manejo de errores dentro del código y no sobrecargar un procedimiento con demasiada lógica, porque dificulta el mantenimiento.

## 3. Implementación en SQL Server Express

**Procedimientos.** Se crean con `CREATE PROCEDURE`. Sus elementos principales son:

- **Parámetros de entrada**, que llevan el prefijo `@` y se declaran con su tipo de dato.
- **Parámetros de salida**, marcados con `OUTPUT`, que devuelven valores al llamador.
- **Cuerpo** entre `BEGIN` y `END`, con variables, condicionales (`IF`), consultas y modificaciones de datos.
- **`SET NOCOUNT ON`**, que evita mensajes innecesarios de filas afectadas.
- **Manejo de errores** con `RAISERROR` y bloques `TRY...CATCH`.

Se ejecutan con `EXEC` (Microsoft, s. f.-a; s. f.-c).

Estructura general:

```sql
CREATE PROCEDURE dbo.nombre_procedimiento
    @parametro_entrada  TIPO,
    @parametro_salida   TIPO OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- sentencias T-SQL (variables, condicionales, consultas, modificaciones)
END;
GO

-- Ejecución
DECLARE @resultado TIPO;
EXEC dbo.nombre_procedimiento
     @parametro_entrada = valor,
     @parametro_salida  = @resultado OUTPUT;
```

Un parámetro marcado `OUTPUT` también puede recibir un valor de entrada, por lo que funciona como parámetro de entrada y salida a la vez. Al ejecutar, hay que indicar `OUTPUT` junto a la variable para que el valor modificado vuelva al llamador.

**Funciones.** Se crean con `CREATE FUNCTION` y siempre indican qué devuelven con `RETURNS`. Se usan dos tipos (Microsoft, s. f.-b):

- **Escalar:** devuelve un único valor. Se invoca anteponiendo el esquema (`dbo.nombre(...)`).
- **De tabla en línea (inline):** devuelve una tabla a partir de un único `SELECT`. Se usa en la cláusula `FROM` como si fuera una vista con parámetros.

Estructura general de una función escalar:

```sql
CREATE FUNCTION dbo.fn_nombre (@parametro TIPO)
RETURNS TIPO
AS
BEGIN
    DECLARE @resultado TIPO;

    -- cálculo o consulta que asigna @resultado

    RETURN @resultado;
END;
GO

-- Uso dentro de una consulta
SELECT dbo.fn_nombre(valor) AS columna;
```

Estructura general de una función de tabla en línea:

```sql
CREATE FUNCTION dbo.fn_nombre_tabla (@parametro TIPO)
RETURNS TABLE
AS
RETURN
(
    SELECT columna1, columna2
    FROM tabla
    WHERE columna = @parametro
);
GO

-- Uso en la cláusula FROM
SELECT * FROM dbo.fn_nombre_tabla(valor);
```

## 4. Caso concreto aplicado al sistema de ventas (Venus Spa)

Se implementan tres objetos que apoyan reglas de negocio ya modeladas en la base `Venus_Spa`:

| Objeto | Tipo | Regla de negocio que apoya |
|---|---|---|
| `usp_RegistrarTurno` | Procedimiento con parámetro `OUTPUT` | RN.02.1, RN.03, RN.05.1, RN.07, RN.07.1 |
| `fn_TotalVenta` | Función escalar | RN.05 (precio histórico en el detalle de venta) |
| `fn_TurnosPorCliente` | Función de tabla en línea | Consulta de turnos de un cliente con su servicio y profesional |

**Criterio de elección:** se usa un **procedimiento** cuando hay que *hacer* algo (modificar datos, validar, controlar errores) y una **función** cuando hay que *calcular o consultar* algo que se reutiliza dentro de otras consultas.

### 4.1 `usp_RegistrarTurno`

**Problema:** registrar un turno implica varios pasos que, sin un procedimiento, dependerían de cada aplicación: verificar que el servicio exista, comprobar que la camilla y el cliente estén libres en esa fecha y franja, copiar el precio vigente del servicio al turno (precio histórico) y asignar al menos un profesional.

**Solución:** un único procedimiento que recibe los datos del turno, valida las reglas, inserta en `turno` y en `se_asigna_turno`, y devuelve el `id_turno` generado mediante un parámetro `OUTPUT`. Si alguna validación falla, informa el motivo con un mensaje de error y no inserta nada.

Las dos inserciones se agrupan en una transacción mínima, para que se guarden juntas o ninguna. El desarrollo de ese mecanismo corresponde al tema *Manejo de transacciones*. Las restricciones `CHECK` de la tabla (franjas válidas, estados y métodos de pago) siguen protegiendo los datos: si se envía un valor inválido, la transacción se deshace y se devuelve el error.

**Por qué un procedimiento y no una función:** registrar un turno **modifica datos** (inserta en dos tablas), y las funciones no pueden modificar tablas. Además necesita una transacción y manejo de errores con `TRY...CATCH` y `RAISERROR`, elementos que tampoco se admiten dentro de una función. Y tiene que devolver el `id_turno` recién generado, lo que se resuelve con un parámetro `OUTPUT`. Es una acción con efectos sobre la base, no un cálculo.

### 4.2 `fn_TotalVenta`

**Problema:** el importe de una venta no se guarda como columna; surge de sumar `cantidad * precio` de cada ítem de `contiene`. Ese cálculo se repetiría en cada informe.

**Solución:** una función escalar que recibe el `id_venta` y devuelve el total (o 0 si la venta no tiene ítems). Se usa dentro de cualquier `SELECT`. Como `precio` es el valor histórico guardado en cada ítem (RN.05), el total de ventas pasadas no cambia si luego se modifica el precio del catálogo.

**Por qué una función y no un procedimiento:** es un cálculo que **no modifica datos** y devuelve **un único valor**. Al ser función puede usarse dentro de un `SELECT`, una vez por cada venta del listado, algo que un procedimiento no permite (hay que ejecutarlo aparte con `EXEC`, venta por venta). Así el mismo cálculo se reutiliza en informes, filtros u ordenamientos sin repetir la lógica.

### 4.3 `fn_TurnosPorCliente`

**Problema:** consultar los turnos de un cliente con su servicio y su profesional requiere unir cuatro tablas (`turno`, `servicio`, `se_asigna_turno` y `persona`).

**Solución:** una función de tabla en línea que recibe el DNI del cliente y devuelve sus turnos con fecha, franja, estado, servicio, precio histórico y profesional. Se consulta como una tabla: `SELECT * FROM dbo.fn_TurnosPorCliente(dni)`.

**Por qué una función y no un procedimiento:** es una consulta de **solo lectura** cuyo resultado conviene seguir manipulando. Como función de tabla se puede usar en el `FROM`, filtrar con `WHERE` (por ejemplo, solo los turnos pendientes), ordenar o combinar con otras tablas mediante `JOIN`. Si fuera un procedimiento, sus filas solo se mostrarían en pantalla, y para filtrarlas habría que guardarlas antes en una tabla temporal.

## 5. Script de demostración y resultados obtenidos

La demostración está en la Parte 2 de `sql/tecnico/procedimientos_funciones.sql` y toma datos ya cargados en la base. Sigue este orden:

1. **Registro exitoso:** se ejecuta `usp_RegistrarTurno` con datos válidos y se muestra el `id_turno` devuelto por el parámetro `OUTPUT`.
2. **Verificación:** se consultan `turno` y `se_asigna_turno` para comprobar que se insertaron ambas filas y que `precio_historico` coincide con el precio del servicio.
3. **Camilla ocupada:** se repiten fecha, franja y camilla; debe rechazarse (RN.02.1).
4. **Cliente con turno:** mismo cliente, fecha y franja con otra camilla; debe rechazarse (RN.03).
5. **Función escalar:** consulta de `venta` con `fn_TotalVenta`.
6. **Función de tabla:** consulta con `fn_TurnosPorCliente`.

### Resultados

| Prueba | Resultado esperado | Captura |
|---|---|---|
| 1. Registro exitoso | Se devuelve un `id_turno` | `evidencias/01_registro_exitoso.png` |
| 2. Verificación de inserciones | Una fila en `turno` y una en `se_asigna_turno` | `evidencias/02_verificacion.png` |
| 3. Camilla ocupada | Error: la camilla ya tiene un turno | `evidencias/03_error_camilla.png` |
| 4. Cliente con turno | Error: el cliente ya tiene un turno | `evidencias/04_error_cliente.png` |
| 5. `fn_TotalVenta` | Total por venta | `evidencias/05_fn_total_venta.png` |
| 6. `fn_TurnosPorCliente` | Turnos del cliente con servicio y profesional | `evidencias/06_fn_turnos_cliente.png` |

---

## Bibliografía

- Universidad Nacional del Nordeste, FaCENA. (s. f.). *Unidad 5. SQL y SQL Avanzado, Tema 14: Funciones y Procedimientos Almacenados* [Guía de lectura]. Bases de Datos I, Lic. en Sistemas de Información.
- Microsoft. (s. f.-a). *CREATE PROCEDURE (Transact-SQL)*. Microsoft Learn. https://learn.microsoft.com/en-us/sql/t-sql/statements/create-procedure-transact-sql
- Microsoft. (s. f.-b). *CREATE FUNCTION (Transact-SQL)*. Microsoft Learn. https://learn.microsoft.com/en-us/sql/t-sql/statements/create-function-transact-sql
- Microsoft. (s. f.-c). *EXECUTE (Transact-SQL)*. Microsoft Learn. https://learn.microsoft.com/en-us/sql/t-sql/language-elements/execute-transact-sql