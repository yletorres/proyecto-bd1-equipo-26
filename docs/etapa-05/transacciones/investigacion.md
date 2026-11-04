# 🔄 Informe Técnico-Teórico: Manejo de Transacciones y Control Concurrente (Etapa V)

### Sistema de Gestión de Turnos, Servicios y Ventas — Venus Spa

*Proyecto integrador de **Bases de Datos I** · Equipo 26*
*Asignatura: Bases de Datos I — Licenciatura en Sistemas de Información*
*Facultad de Ciencias Exactas y Naturales y Agronomía (FaCENA) — UNNE*

[📖 Fundamentos](#-1-introducción-y-fundamentos-teóricos) · [💆 Problemática](#-2-problemática-del-negocio-en-venus-spa) · [⚙️ Implementación](#️-3-implementación-técnica-y-reglas-de-negocio) · [🧪 Pruebas](#-4-análisis-de-la-batería-de-pruebas-y-evidencias-de-ejecución) · [✅ Conclusiones](#-5-conclusiones)

* * *

## 📖 1. Introducción y Fundamentos Teóricos

En los Sistemas de Gestión de Bases de Datos Relacionales (SGBDR) como Microsoft SQL Server, las operaciones de modificación de datos (**DML**: `INSERT`, `UPDATE`, `DELETE`) deben ejecutarse bajo un marco estricto que garantice la consistencia e integridad de la información ante fallos del sistema, errores de usuario, fallos de infraestructura o ejecuciones concurrentes [107, 365, 366].

Para lograr esto, el estándar SQL define el **Lenguaje de Control Transaccional (TCL - Transaction Control Language)** [108, 378], cuyo propósito es agrupar un conjunto de instrucciones SQL individuales en una **Unidad Lógica de Trabajo (LUW - Logical Unit of Work)** atómica e indivisible [12, 14, 382].

### 🧬 1.1. Propiedades ACID

Toda transacción en un SGBD relacional debe cumplir rigurosamente con las cuatro propiedades fundamentales conocidas como **ACID** [13, 15, 385]:

1. **Atomicidad (Atomicity):** Principio de "todo o nada" [15, 385]. Una transacción se trata como un bloque único e indivisible: o todas sus operaciones se completan de forma exitosa mediante un `COMMIT`, o ninguna lo hace, revirtiéndose completamente los cambios aplicados hasta el momento mediante un `ROLLBACK` [13, 15, 378].
2. **Consistencia (Consistency):** La transacción lleva la base de datos de un estado válido a otro estado válido [15, 386], asegurando el cumplimiento de todas las restricciones de integridad definidas en el DDL (`PRIMARY KEY`, `FOREIGN KEY`, `CHECK`, `UNIQUE`, `NOT NULL`) [118, 584, 656] y las **Reglas de Negocio (RN)** del sistema [692, 947].
3. **Aislamiento (Isolation):** Las transacciones que se ejecutan simultáneamente operan de manera aislada e independiente [15, 386]. El estado intermedio de una transacción no confirmada permanece invisible para los demás usuarios, previniendo anomalías como lecturas sucias o actualizaciones perdidas [11, 15].
4. **Durabilidad (Durability):** Una vez que la transacción es confirmada con un `COMMIT`, sus modificaciones quedan grabadas de forma permanente en el almacenamiento no volátil y persisten a cualquier fallo posterior del servidor [16, 386].

### 🛠️ 1.2. Control Transaccional en Transact-SQL (T-SQL)

En SQL Server, el control transaccional explícito utiliza los siguientes comandos del sublenguaje TCL [108, 109, 378]:

| Comando | Descripción |
|---------|-------------|
| `BEGIN TRANSACTION` / `BEGIN TRAN` | Marca el inicio formal de la unidad lógica de trabajo [162, 202]. |
| `COMMIT TRANSACTION` / `COMMIT TRAN` | Confirma definitivamente las modificaciones en la base de datos [109, 378]. |
| `ROLLBACK TRANSACTION` / `ROLLBACK TRAN` | Cancela y revierte todos los cambios realizados desde la apertura de la transacción [107, 109, 378]. |
| `BEGIN TRY ... BEGIN CATCH` | **Manejo de Excepciones:** Permite capturar cualquier error imprevisto o disparo de `RAISERROR` durante la ejecución DML, derivando el flujo al bloque `CATCH` para ejecutar el `ROLLBACK TRANSACTION` de seguridad [202, 830]. |

* * *

## 💆 2. Problemática del Negocio en Venus Spa

### 🛒 2.1. El Proceso de Venta de Productos

En el centro de estética **Venus Spa**, la comercialización de productos de uso doméstico (cremas, shampoos, serums) requiere la interacción coordinada de tres tablas principales [688, 690, 943]:

| Tabla | Descripción |
|-------|-------------|
| 🧾 **`Venta`** (Cabecera) | Registra la fecha (`FechaVenta`), el método de pago (`Metodo_Pago_Venta`), el cliente (`DNI_cliente`) y el importe acumulado (`total_venta`) [144, 295, 690]. |
| 🔗 **`Contiene`** (Detalle N:M) | Relaciona la venta con los productos seleccionados, registrando la `cantidad` e insertando el `precio` congelado [297, 690, 705]. |
| 🧴 **`Producto`** (Catálogo e Inventario) | Guarda el `nombre_producto`, el `precio_vigente` y el `stock_disponible` [296, 690, 704]. |

### ⚠️ 2.2. Riesgos de una Modificación sin Control Transaccional

Si el registro de ventas se realizara mediante consultas DML sueltas sin delimitar una transacción atómica:

- **Ventas Incompletas / Huérfanas:** Si se insertara la cabecera en `Venta` y ocurriera un fallo de red o falta de stock al insertar en `Contiene`, quedaría guardada en la base de datos una venta sin ítems ni productos [720, 732].
- **Inconsistencias de Inventario:** El stock de la tabla `Producto` podría descontarse sin confirmarse la venta, o venderse unidades que superen la disponibilidad física [719, 731].
- **Inconsistencia de Precios:** Si el precio de un producto cambiara en el catálogo con posterioridad, alteraría el historial de ventas anteriores si no se hubiera congelado el precio de venta histórico al momento de la operación [691, 692, 949].

* * *

## ⚙️ 3. Implementación Técnica y Reglas de Negocio

Para resolver estas vulnerabilidades, se diseñaron e implementaron los procedimientos almacenados `usp_RegistrarVenta` y `usp_CancelarVenta` en el archivo `sql/tecnico/transacciones.sql` [138, 162, 822].

### 🧾 3.1. Procedimiento Principal: `usp_RegistrarVenta`

El procedimiento `usp_RegistrarVenta` soporta la venta de $1$ a $3$ productos de forma simultánea dentro de un mismo `BEGIN TRANSACTION` [822, 829, 830].

#### 📏 Reglas de Negocio Garantizadas

| Regla | Qué garantiza |
|-------|---------------|
| **RN.04** (Control y Descuento de Stock) | Valida que el producto exista y que el `stock_disponible` sea suficiente [692, 830, 948]. Si no hay stock o la cantidad solicitada es inválida ($\le 0$), el procedimiento ejecuta `RAISERROR`, saltando al bloque `CATCH` que realiza el **`ROLLBACK TRANSACTION`** y cancela toda la venta [830]. Si hay stock suficiente, descuenta las unidades vendidas en la tabla `Producto` [830, 948]. |
| **RN.05** (Precio Histórico en el Detalle) | Copia el `precio_vigente` del catálogo de productos a la columna `precio` de la tabla `Contiene` al concretar la venta [691, 692, 830, 949]. Esto congela el importe histórico y garantiza que futuros cambios de precio de lista no modifiquen ventas pasadas [691, 949]. |
| **RN.06** (Método de Pago Válido) | Garantiza que la venta registre un único método de pago permitido entre `'efectivo'`, `'tarjeta de debito'`, `'tarjeta de credito'` o `'transferencia'`, validado por la restricción `CHECK (CK_Venta_MetodoPago)` [144, 295, 692, 950]. |

### ❌ 3.2. Procedimiento Complementario: `usp_CancelarVenta`

Permite anular una venta previamente registrada [832, 836]. Dentro de un `BEGIN TRANSACTION`, reintegra atómicamente la cantidad de cada ítem vendido al `stock_disponible` de la tabla `Producto`, y elimina las filas correspondientes en `Contiene` y `Venta` [207, 835, 837]. Si la venta no existe o la operación falla, se ejecuta `ROLLBACK TRANSACTION` sin alterar la base [207, 837].

* * *

## 🧪 4. Análisis de la Batería de Pruebas y Evidencias de Ejecución

Para respaldar el informe con evidencia empírica, se ejecutó una batería de **9 casos de prueba autocontenidos** en SQL Server Management Studio (SSMS) [838, 842].

### 📋 4.1. Matriz de Evaluación de Pruebas

| N° | Escenario de Prueba | Comportamiento Esperado | Resultado TCL | Regla Validada |
|:--:|---------------------|-------------------------|:-------------:|:--------------:|
| **1** | Venta exitosa con 2 ítems de productos | Registra cabecera en `Venta`, detalles en `Contiene` y descuenta stock | ✅ **`COMMIT`** | RN.04, RN.05 [857, 863] |
| **2** | Intento de venta con stock insuficiente | Detecta la falta de stock y revierte la operación | ↩️ **`ROLLBACK`** | RN.04 [870, 873] |
| **3** | Falla en el Ítem 2 por stock insuficiente | Ítem 1 era válido, pero al fallar el Ítem 2 se deshace la cabecera y el Ítem 1 | ↩️ **`ROLLBACK`** | Atomicidad (ACID) [876, 881] |
| **4** | Verificación de precio histórico | Un cambio en `Producto.precio_vigente` no modifica `Contiene.precio` | ✅ **`COMMIT`** | RN.05 [884, 887] |
| **5** | Verificación de ventas sin detalle | Consulta `LEFT JOIN` comprueba 0 ventas huérfanas o sin filas en `Contiene` | 0 filas | Integridad [891, 894] |
| **6** | Intento con cantidad inválida ($0$) | Cancela la transacción al validar la cantidad | ↩️ **`ROLLBACK`** | Validación [895, 898] |
| **7** | Método de pago no válido (`'bitcoin'`) | La restricción `CHECK` deriva al `CATCH` y deshace la transacción | ↩️ **`ROLLBACK`** | RN.06 [900, 905] |
| **8** | Anulación atómica de venta existente | Reintegra el stock a `Producto` y elimina cabecera y detalle | ✅ **`COMMIT`** | RN.04 [907, 912] |
| **9** | Anulación de venta inexistente (`id = -1`) | Detecta que la venta no existe y revierte la operación | ↩️ **`ROLLBACK`** | Integridad [913, 915] |

### 📸 4.2. Evidencias de Ejecución Guardadas

Las imágenes que certifican las pruebas ejecutadas en SSMS se ubican en la carpeta `docs/etapa-05/transacciones/evidencias/` [136, 137, 164]:

| Evidencia | Descripción |
|-----------|-------------|
| 🖼️ **`venta_exitosa.png`** | Muestra la ejecución de la Prueba 1 con el mensaje *"Venta registrada con éxito"* y el resultado de las tres tablas pobladas con datos e inventario actualizado [685, 869]. |
| 🖼️ **`prueba_rollback.png`** | Muestra la ejecución de la Prueba 2/3 con el recuadro de mensaje de error `RAISERROR` en rojo demostrando la reversión total por `ROLLBACK TRANSACTION` [686, 830]. |

* * *

## ✅ 5. Conclusiones

La implementación del **Control Transaccional (TCL)** en el sistema **Venus Spa** garantiza la observancia estricta de las propiedades **ACID** en el módulo de ventas [13, 15, 385]. Mediante el uso de procedimientos almacenados que encapsulan la lógica DML en bloques `BEGIN TRANSACTION ... COMMIT / ROLLBACK` gestionados por `TRY...CATCH` [202, 830], se eliminan las vulnerabilidades de ventas incompletas, se protege la consistencia del stock (**RN.04**) [692, 948], se congela el precio histórico de los ítems (**RN.05**) [691, 949] y se imponen métodos de pago válidos (**RN.06**) [144, 950], consolidando una arquitectura relacional sólida y libre de inconsistencias.

* * *

**Bases de Datos I** · Facultad de Ciencias Exactas y Naturales y Agrimensura · UNNE
Hecho con 💗 por el Equipo 26
