# Esquema relacional – Venus Spa

## PERSONA
| Atributo | Tipo | Clave |
|---|---|---|
| **DNI_persona** | INT | PK |
| NombreCompleto_persona | VARCHAR(150) | |
| Telefono_persona | VARCHAR(30) | |

## PROFESIONAL
| Atributo | Tipo | Clave |
|---|---|---|
| **DNI_profesional** | INT | PK, FK → PERSONA |
| FechaDeIngreso | DATE | |
| Matricula | VARCHAR(50) | (O) |

## CLIENTE
| Atributo | Tipo | Clave |
|---|---|---|
| **DNI_cliente** | INT | PK, FK → PERSONA |
| Direccion | VARCHAR(200) | |
| FechaDeNacimiento | DATE | |

## CAMILLA
| Atributo | Tipo | Clave |
|---|---|---|
| **id_camilla** | INT | PK |
| Nombre | VARCHAR(100) | |

## SERVICIO
| Atributo | Tipo | Clave |
|---|---|---|
| **id_servicio** | INT | PK |
| Denominacion | VARCHAR(150) | |
| PrecioUnitario | DECIMAL(10,2) | |

## TURNO
| Atributo | Tipo | Clave |
|---|---|---|
| **Id_turno** | INT | PK |
| FechaTurno | DATE | Ugroup1, Ugroup2 |
| FranjaHoraria | TIME(0) | Ugroup1, Ugroup2 |
| Estado | VARCHAR(20) | |
| MetodoPagoTurno | VARCHAR(50) | |
| Precio_historico | DECIMAL(10,2) | |
| DNI_cliente | INT | FK → CLIENTE, Ugroup1 |
| Id_camilla | INT | FK → CAMILLA, Ugroup2 |
| Id_servicio | INT | FK → SERVICIO |

## SE_ASIGNA_TURNO
| Atributo | Tipo | Clave |
|---|---|---|
| **DNI_profesional** | INT | PK, FK → PROFESIONAL |
| **id_turno** | INT | PK, FK → TURNO |

## VENTA
| Atributo | Tipo | Clave |
|---|---|---|
| **id_venta** | INT | PK |
| FechaVenta | DATE | |
| MetodoPagoVenta | VARCHAR(50) | |
| DNI_cliente | INT | FK → CLIENTE |

## PRODUCTO
| Atributo | Tipo | Clave |
|---|---|---|
| **Id_producto** | INT | PK |
| NombreProducto | VARCHAR(150) | |
| PrecioVigente | DECIMAL(10,2) | |
| Stock_disponible | INT | |

## CONTIENE
| Atributo | Tipo | Clave |
|---|---|---|
| **Id_venta** | INT | PK, FK → VENTA |
| **Id_producto** | INT | PK, FK → PRODUCTO |
| Cantidad | INT | |
| Precio | DECIMAL(10,2) | |

## Claves foráneas
- PROFESIONAL(DNI_profesional) → PERSONA(DNI_persona)
- CLIENTE(DNI_cliente) → PERSONA(DNI_persona)
- TURNO(DNI_cliente) → CLIENTE(DNI_cliente)
- TURNO(Id_camilla) → CAMILLA(id_camilla)
- TURNO(Id_servicio) → SERVICIO(id_servicio)
- SE_ASIGNA_TURNO(DNI_profesional) → PROFESIONAL(DNI_profesional)
- SE_ASIGNA_TURNO(id_turno) → TURNO(Id_turno)
- VENTA(DNI_cliente) → CLIENTE(DNI_cliente)
- CONTIENE(Id_venta) → VENTA(id_venta)
- CONTIENE(Id_producto) → PRODUCTO(Id_producto)

## Restricciones únicas (UNIQUE)
- **Ugroup1:** (FechaTurno, FranjaHoraria, DNI_cliente)
- **Ugroup2:** (FechaTurno, FranjaHoraria, Id_camilla)