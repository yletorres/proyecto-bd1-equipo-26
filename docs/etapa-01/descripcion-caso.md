# Descripción del caso

## Sistema de Gestión de Turnos, Servicios y Ventas para Venus Spa

Venus Spa, centro de estética especializado en tratamientos de belleza facial y capilar, necesita llevar un control informatizado de la información relacionada con sus turnos, servicios, ventas, clientes y profesionales.

De cada persona registrada en el sistema se desea guardar su DNI (clave identificatoria, única y no repetible), nombre completo y teléfono. Una misma persona puede cumplir el rol de cliente, de profesional, o ambos simultáneamente. De los clientes se debe guardar además su dirección y su fecha de nacimiento. De los profesionales se debe guardar su fecha de ingreso y, de forma opcional, su número de matrícula profesional, dado que algunos poseen estudios en estética sin título habilitante de tipo médico.

Venus Spa ofrece distintos servicios (PRP facial, PRP capilar, limpieza profunda, etc.). De cada servicio se desea guardar un código identificador, denominación y precio vigente.

Asimismo, Venus Spa comercializa productos de uso doméstico para la continuidad del tratamiento (cremas, shampoos, serums, etc.). De cada producto se desea guardar un código identificador, nombre, precio vigente y stock disponible.

Dado que Venus Spa se encuentra en crecimiento, la cantidad de puestos de atención puede variar con el tiempo. Por ello se desea registrar cada camilla de atención con un código identificador y un nombre. La cantidad máxima de turnos que pueden coexistir en una misma franja horaria queda determinada por la cantidad de camillas registradas: no puede asignarse un turno a una franja horaria si todas las camillas ya se encuentran ocupadas en ese horario. Cada turno debe estar vinculado a una única camilla, y una misma camilla no puede alojar más de un turno en la misma franja horaria (fecha y hora); esta combinación de camilla, fecha y franja horaria debe ser única entre todos los turnos registrados.

Se desea llevar un registro de cada uno de los turnos otorgados. De cada turno se desea guardar un código identificador, fecha, franja horaria, camilla asignada, estado (pendiente, confirmado, realizado o cancelado), método de pago (correspondiente a la seña o pago anticipado, cuando corresponda) y el servicio principal por el cual fue solicitado. Cada turno corresponde a un único cliente, no pudiendo un mismo cliente tener más de un turno asignado en la misma franja horaria. Cada turno puede ser atendido por uno o varios profesionales, contemplando los casos de relevo de profesional a mitad de sesión; un profesional, por su parte, puede no haber atendido aún ningún turno o puede haber atendido varios a lo largo del tiempo. Cada turno está asociado a un único servicio, mientras que un mismo servicio puede ser el motivo de ningún, uno o varios turnos.

Se desea registrar además las ventas de productos realizadas en Venus Spa. Las ventas son independientes de los turnos: no requieren que el cliente tenga un turno asignado, y un turno no genera ni requiere una venta asociada. Cada venta corresponde a un único cliente registrado y se refiere a productos de mantenimiento, no a servicios. De cada venta se desea guardar un código identificador, fecha y método de pago. Toda venta debe incluir uno o varios ítems, referidos a producto

Al concretarse la venta de un producto, se debe descontar automáticamente la cantidad vendida del stock disponible, no pudiéndose vender una cantidad mayor a la existente en stock.
