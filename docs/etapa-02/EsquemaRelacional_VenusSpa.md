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
| **DNI_persona** | INT | PK, FK → PERSONA |
| FechaDeIngreso | DATE | |
| Matricula | VARCHAR(50) | (O) |

## CLIENTE
| Atributo | Tipo | Clave |
|---|---|---|
| **DNI_persona** | INT | PK, FK → PERSONA |
| Direccion | VARCHAR(200) | |
| FechaDeNacimiento | DATE | |

## CAMILLA
| Atributo | Tipo | Clave |
|---|---|---|
| **id_camilla** | INT | PK |
| Nombre | VARCHAR(100) | |

## SERVICIOS
| Atributo | Tipo | Clave |
|---|---|---|
| **id_servicio** | INT | PK |
| Denominacion | VARCHAR(150) | |
| PrecioUnitario | FLOAT | |

## TURNO
| Atributo | Tipo | Clave |
|---|---|---|
| **Id_turno** | INT | PK |
| FechaTurno | DATE | Ugroup1, Ugroup2 |
| FranjaHoraria | VARCHAR(50) | Ugroup1, Ugroup2 |
| Estado | VARCHAR(20) | |
| MetodoPagoTurno | VARCHAR(50) | |
| Precio_historico | FLOAT | |
| DNI_persona | INT | FK → CLIENTE, Ugroup1 |
| Id_camilla | INT | FK → CAMILLA, Ugroup2 |
| Id_servicio | INT | FK → SERVICIOS |

## SE_ASIGNA_TURNO
| Atributo | Tipo | Clave |
|---|---|---|
| **DNI_persona** | INT | PK, FK → PROFESIONAL |
| **id_turno** | INT | PK, FK → TURNO |

## VENTAS
| Atributo | Tipo | Clave |
|---|---|---|
| **id_venta** | INT | PK |
| FechaVenta | DATE | |
| MetodoPagoVenta | VARCHAR(50) | |
| DNI_cliente | INT | FK → CLIENTE |

## PRODUCTOS
| Atributo | Tipo | Clave |
|---|---|---|
| **Id_producto** | INT | PK |
| NombreProducto | VARCHAR(150) | |
| PrecioVigente | FLOAT | |
| Stock_disponible | INT | |

## CONTIENE
| Atributo | Tipo | Clave |
|---|---|---|
| **Id_venta** | INT | PK, FK → VENTAS |
| **Id_producto** | INT | PK, FK → PRODUCTOS |
| Cantidad | INT | |
| Precio | FLOAT | |

## Claves foráneas
- PROFESIONAL(DNI_persona) → PERSONA(DNI_persona)
- CLIENTE(DNI_persona) → PERSONA(DNI_persona)
- TURNO(DNI_persona) → CLIENTE(DNI_persona)
- TURNO(Id_camilla) → CAMILLA(id_camilla)
- TURNO(Id_servicio) → SERVICIOS(id_servicio)
- SE_ASIGNA_TURNO(DNI_persona) → PROFESIONAL(DNI_persona)
- SE_ASIGNA_TURNO(id_turno) → TURNO(Id_turno)
- VENTAS(DNI_cliente) → CLIENTE(DNI_persona)
- CONTIENE(Id_venta) → VENTAS(id_venta)
- CONTIENE(Id_producto) → PRODUCTOS(Id_producto)

## Restricciones únicas (UNIQUE)
- **Ugroup1:** (FechaTurno, FranjaHoraria, DNI_persona)
- **Ugroup2:** (FechaTurno, FranjaHoraria, Id_camilla)
