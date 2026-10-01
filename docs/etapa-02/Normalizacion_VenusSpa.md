# Proceso de normalización – Venus Spa

## 1. Enfoque adoptado: diseño directo en 3FN

Este proyecto **no partió de una tabla única desnormalizada** que luego se fue refinando forma normal por forma normal (0FN → 1FN → 2FN → 3FN). Desde el modelado conceptual, el sistema se planteó de manera que la transformación del DER al modelo relacional produjera **directamente un esquema en Tercera Forma Normal (3FN)**.

Por eso, en esta documentación no se muestra una "evolución" de tablas intermedias. En su lugar se documenta:

1. Qué **decisiones de diseño** se tomaron en el DER para evitar cada tipo de anomalía desde el principio.
2. La **verificación formal** de que el esquema final cumple 1FN, 2FN y 3FN.

> Normalizar un esquema es, en definitiva, garantizar que no existan las dependencias que generan redundancia y anomalías. Si el diseño conceptual ya separa correctamente las entidades y resuelve las relaciones, esas dependencias nunca llegan a aparecer, y las etapas intermedias resultan innecesarias.

---

## 2. Esquema relacional final

| Relación | Clave primaria | Claves foráneas | Otras claves candidatas |
|---|---|---|---|
| PERSONA | DNI_persona | – | – |
| PROFESIONAL | DNI_profesional | DNI_profesional → PERSONA | – |
| CLIENTE | DNI_cliente | DNI_cliente → PERSONA | – |
| CAMILLA | id_camilla | – | – |
| SERVICIO | id_servicio | – | – |
| TURNO | Id_turno | DNI_cliente → CLIENTE, Id_camilla → CAMILLA, Id_servicio → SERVICIO | (FechaTurno, FranjaHoraria, DNI_cliente) y (FechaTurno, FranjaHoraria, Id_camilla) |
| SE_ASIGNA_TURNO | (DNI_profesional, id_turno) | DNI_profesional → PROFESIONAL, id_turno → TURNO | – |
| VENTA | id_venta | DNI_cliente → CLIENTE | – |
| PRODUCTO | Id_producto | – | – |
| CONTIENE | (Id_venta, Id_producto) | Id_venta → VENTA, Id_producto → PRODUCTO | – |

---

## 3. Decisiones de diseño que evitaron las anomalías desde el DER

### 3.1 Atributos atómicos y sin grupos repetitivos (1FN)
- Cada atributo guarda **un único valor** por fila (fecha, franja horaria, estado, método de pago, etc.).
- Las relaciones **N:M** no se resolvieron con atributos multivaluados ni columnas repetidas (por ejemplo, `Producto1`, `Producto2`, …), sino con **tablas intermedias**:
  - **CONTIENE**: una venta contiene muchos productos y un producto aparece en muchas ventas.
  - **SE_ASIGNA_TURNO**: un turno puede tener asignados varios profesionales y un profesional atiende muchos turnos.

### 3.2 Sin dependencias parciales (2FN)
- Las únicas tablas con clave compuesta son **CONTIENE** y **SE_ASIGNA_TURNO**.
- En **SE_ASIGNA_TURNO** todos los atributos forman parte de la clave, por lo que no puede haber dependencia parcial.
- En **CONTIENE**, los atributos `Cantidad` y `Precio` describen **el producto dentro de una venta concreta**, es decir, dependen de la clave completa (`Id_venta`, `Id_producto`) y no solo de una de sus partes.
- Los datos propios de cada entidad (nombre del producto, stock, denominación del servicio, etc.) viven en su propia tabla y no se mezclan con las tablas intermedias.

### 3.3 Sin dependencias transitivas (3FN)
Se separaron en tablas propias las entidades cuyos datos dependerían de otro atributo no clave si estuvieran juntas:

- **PERSONA** guarda los datos comunes (nombre, teléfono) una sola vez. **CLIENTE** y **PROFESIONAL** son especializaciones **parciales y superpuestas** de PERSONA: una misma persona puede ser cliente, profesional o ambos (RN.01). Cada una toma su clave de PERSONA (`DNI_persona`) y la nombra según su rol (`DNI_cliente`, `DNI_profesional`), y solo contiene sus atributos específicos. Así, nombre y teléfono no se repiten ni dependen transitivamente del rol.
- **SERVICIO**, **CAMILLA** y **PRODUCTO** son catálogos independientes. `TURNO` solo guarda la referencia (`Id_servicio`, `Id_camilla`), no los datos descriptivos del servicio o la camilla.
- **VENTA** referencia a **CLIENTE** por `DNI_cliente`, sin duplicar datos del cliente.

### 3.4 Precios históricos: redundancia aparente, no real
`Precio_historico` (en TURNO) y `Precio` (en CONTIENE) parecen repetir `PrecioUnitario` (SERVICIO) y `PrecioVigente` (PRODUCTO), pero **no son dependencias transitivas**:

- `PrecioUnitario` y `PrecioVigente` reflejan el precio **actual** y pueden cambiar.
- `Precio_historico` y `Precio` guardan el precio **congelado al momento del turno o la venta**.
- Como el precio actual puede cambiar, el valor histórico **no se puede derivar** del catálogo. Depende de la clave de su propia tabla (`Id_turno`, o (`Id_venta`, `Id_producto`)).

---

## 4. Verificación formal

### 4.1 Primera Forma Normal (1FN)
| Criterio | Resultado |
|---|---|
| Todos los atributos son atómicos (a nivel de dominio) | ✔ |
| No hay grupos repetitivos ni atributos multivaluados | ✔ |
| Toda relación tiene clave primaria definida | ✔ |

### 4.2 Segunda Forma Normal (2FN)
| Relación | ¿Clave compuesta? | Resultado |
|---|---|---|
| PERSONA, PROFESIONAL, CLIENTE, CAMILLA, SERVICIO, TURNO, VENTA, PRODUCTO | No (clave simple) | ✔ 2FN se cumple automáticamente |
| SE_ASIGNA_TURNO | Sí | ✔ Solo tiene atributos de clave |
| CONTIENE | Sí | ✔ `Cantidad` y `Precio` dependen de (`Id_venta`, `Id_producto`) completa |

### 4.3 Tercera Forma Normal (3FN)
Dependencias funcionales de cada relación (los determinantes son siempre superclaves):

| Relación | Dependencias funcionales | ¿Determinante superclave? |
|---|---|---|
| PERSONA | DNI_persona → NombreCompleto_persona, Telefono_persona | ✔ |
| PROFESIONAL | DNI_profesional → FechaDeIngreso, Matricula | ✔ |
| CLIENTE | DNI_cliente → Direccion, FechaDeNacimiento | ✔ |
| CAMILLA | id_camilla → Nombre | ✔ |
| SERVICIO | id_servicio → Denominacion, PrecioUnitario | ✔ |
| TURNO | Id_turno → todos los atributos. (FechaTurno, FranjaHoraria, DNI_cliente) → Id_turno y demás. (FechaTurno, FranjaHoraria, Id_camilla) → Id_turno y demás | ✔ (las tres son superclaves) |
| SE_ASIGNA_TURNO | (DNI_profesional, id_turno) → (sin atributos no clave) | ✔ |
| VENTA | id_venta → FechaVenta, MetodoPagoVenta, DNI_cliente | ✔ |
| PRODUCTO | Id_producto → NombreProducto, PrecioVigente, Stock_disponible | ✔ |
| CONTIENE | (Id_venta, Id_producto) → Cantidad, Precio | ✔ |

Ningún atributo no clave depende de otro atributo no clave, por lo tanto **no existen dependencias transitivas**.

---

## 5. Conclusión

El modelo relacional de Venus Spa se diseñó para que el paso del DER al esquema de tablas resultara **directamente en 3FN**:

- Las entidades se separaron según su identidad propia (personas, clientes, profesionales, servicios, camillas, productos).
- Las relaciones N:M se resolvieron con tablas intermedias con clave compuesta.
- Los datos que dependen de un momento puntual (precios) se guardan donde corresponde, sin generar redundancia derivable.

Por este motivo no fue necesario recorrer las etapas intermedias de normalización: el esquema **no presentaba violaciones** que corregir en 1FN, 2FN ni 3FN, y la sección 4 verifica formalmente que así es.