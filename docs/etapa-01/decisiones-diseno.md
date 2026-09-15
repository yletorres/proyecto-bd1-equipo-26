# Aclaraciones y Asunciones de Diseño (Justificación)

## 1. Simplificación y desacoplamiento del modelo Venta–Turno

Se ha optado por no establecer una relación directa entre las entidades Turno y Ventas, fundamentado en los siguientes criterios de diseño de bases de datos:

- **Prevención de redundancia y ciclos de transitividad:** Dado que la entidad Turno ya posee una relación obligatoria con Cliente (Cliente "Tiene" Turno) y la entidad Ventas se vincula directamente con Cliente (Cliente "Corresponde" Ventas), conectar Turno con Ventas generaría un bucle/ciclo de relaciones redundante. Esto crearía dos caminos de acceso al mismo Cliente para una misma transacción, incrementando el riesgo de inconsistencias en la base de datos.
- **Optimización y carga semántica de la entidad Turno:** La entidad Turno representa un punto crítico de sobrecarga en el modelo, al articular simultáneamente relaciones con Cliente, Servicio, Camilla y Profesional. Agregar la gestión de ventas de productos dentro de su alcance saturaría la lógica de la entidad e incrementaría la presencia de atributos y claves opcionales (valores nulos).
- **Alineación con la independencia de negocio (RN.08):** La Regla de Negocio RN.08 establece expresamente que las ventas de productos son independientes de los turnos y no requieren de estos para su concreción. Desacoplar ambas entidades permite que la entidad Ventas funcione como un registro transaccional autónomo (asociado únicamente al Cliente y sus Productos mediante la relación "Contiene"), preservando un diseño más limpio, escalable y flexible para el sistema.

## 2. Atributos derivados incorporados en el modelo

- En la entidad Ventas se incluyó el atributo `Total_venta` como atributo derivado/calculado a partir de la suma de los importes de los ítems (`Cantidad` * `Precio_unitario` del detalle).

## 3. Especialización de la entidad Persona (RN.01)

- La especialización de Persona en Cliente y Profesional se modeló como parcial y overlapping (superpuesta), permitiendo que una persona registrada pueda asumir el rol de cliente, de profesional, o ambos simultáneamente según lo estipula la RN.01.
