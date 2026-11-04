# Seguridad: permisos a nivel de usuarios y de roles

Etapa V: Implementación de temas técnicos · Proyecto Venus Spa · Equipo 26
Motor: Microsoft SQL Server Express (Transact-SQL)

Script de implementación y demostración: [`sql/tecnico/seguridad.sql`](../../../sql/tecnico/seguridad.sql)
Capturas de ejecución: [`evidencias/`](evidencias/)

---

## 1. Definición y objetivo

La autorización es el proceso que controla qué usuarios o roles pueden realizar qué operaciones sobre qué objetos de la base de datos (UNNE, s. f.). No debe confundirse con la autenticación: la autenticación verifica *quién es* quien se conecta, y la autorización define *qué puede hacer* una vez conectado.

En SQL Server (Transact-SQL) los permisos se administran con tres sentencias:

| Sentencia | Qué hace |
|---|---|
| `GRANT` | Otorga un permiso a un usuario o a un rol |
| `DENY` | Prohíbe explícitamente un permiso; tiene prioridad sobre un `GRANT` |
| `REVOKE` | Retira un permiso previamente otorgado o denegado; no equivale a prohibirlo |

**Objetivo:** que cada perfil del spa pueda hacer únicamente lo que necesita para su tarea. En Venus Spa esto resuelve un problema concreto (RN.07.1): un `INSERT` directo en `turno` crea un turno sin profesional asignado. Si el recepcionista solo puede registrar turnos a través de `usp_RegistrarTurno`, y no tiene `INSERT` ni `DELETE` directos sobre la tabla, la regla se cumple siempre.

## 2. Ventajas y aplicaciones

**Ventajas** (UNNE, s. f.):

- **Mínimo privilegio:** se otorgan solo los permisos estrictamente necesarios para cada tarea, lo que reduce el daño posible ante un error o un uso indebido.
- **Administración simplificada con roles:** los permisos se otorgan al rol y los usuarios lo heredan, en lugar de configurar cada usuario por separado.
- **Acceso controlado a los datos:** se puede dar permiso para ejecutar un procedimiento sin dar acceso directo a las tablas que usa, y se pueden otorgar o revocar permisos a nivel de esquema.
- **Trazabilidad:** documentar quién tiene qué permisos facilita revisar y corregir la configuración.

**Aplicaciones habituales:** controlar quién ve datos sensibles, quién modifica la estructura de la base y quién puede agregar o borrar registros.

**Buenas prácticas y trampas a evitar:** gestionar los permisos mediante roles siempre que sea posible, documentar la configuración, no otorgar más permisos de los necesarios por comodidad y acordarse de revocar los permisos cuando un usuario cambia de función (UNNE, s. f.).

## 3. Implementación en SQL Server Express

### 3.1 Modos de autenticación

SQL Server ofrece dos modos de autenticación para el motor de base de datos (Microsoft, s. f.):

| Modo | Qué permite |
|---|---|
| Autenticación de Windows | Solo cuentas de Windows. La autenticación de SQL Server queda deshabilitada |
| Modo mixto | Cuentas de Windows y también inicios de sesión propios de SQL Server (usuario y contraseña almacenados en el servidor) |

La autenticación de Windows está siempre disponible y no se puede deshabilitar. Microsoft recomienda usarla siempre que sea posible, porque la identidad la confirma el sistema operativo y se aplican las directivas de contraseñas de Windows (complejidad, bloqueo y expiración). La autenticación de SQL Server resulta necesaria cuando no todos los usuarios pertenecen a un dominio de Windows o cuando una aplicación la requiere, y exige contraseñas seguras para cada inicio de sesión. Además, si el servidor se instaló en modo Windows, la cuenta administradora `sa` se crea deshabilitada; Microsoft aconseja no habilitarla salvo que sea imprescindible (Microsoft, s. f.).

Para este trabajo se necesita el **modo mixto**, porque los usuarios de demostración se crean como inicios de sesión de SQL Server (`CREATE LOGIN ... WITH PASSWORD`). El modo se consulta con una propiedad del servidor:

```sql
SELECT SERVERPROPERTY('IsIntegratedSecurityOnly') AS autenticacion_solo_windows;
-- 0 = modo mixto, 1 = solo Windows
```

Se trata de una configuración del servidor, no de una base de datos en particular.

### 3.2 Login, usuario y rol

SQL Server separa tres conceptos:

- **Login:** identidad a nivel de servidor; es la que se autentica. Se crea con `CREATE LOGIN`.
- **Usuario de base de datos:** representa al login dentro de una base concreta y es quien recibe los permisos. Se crea con `CREATE USER ... FOR LOGIN`.
- **Rol:** conjunto de permisos que se asigna a uno o varios usuarios. Se crea con `CREATE ROLE` y se asignan miembros con `ALTER ROLE ... ADD MEMBER`.

La guía de la cátedra muestra la asignación de un rol con la sintaxis estándar `GRANT rol TO usuario`, y aclara que la sintaxis varía entre motores (UNNE, s. f.). En SQL Server la pertenencia a un rol se maneja con `ALTER ROLE`.

```sql
CREATE LOGIN nombre_login WITH PASSWORD = '...';
CREATE USER nombre_usuario FOR LOGIN nombre_login;
CREATE ROLE nombre_rol;
ALTER ROLE nombre_rol ADD MEMBER nombre_usuario;
```

SQL Server también trae **roles fijos de base de datos** con permisos predefinidos. Se usan dos:

- `db_owner`: control total sobre la base de datos.
- `db_datareader`: lectura (`SELECT`) de todas las tablas y vistas de la base.

### 3.3 GRANT, DENY y REVOKE

```sql
GRANT  EXECUTE ON dbo.procedimiento TO usuario_o_rol;   -- otorga
DENY   INSERT  ON dbo.tabla         TO usuario_o_rol;   -- prohíbe
REVOKE EXECUTE ON dbo.procedimiento FROM usuario_o_rol; -- retira lo otorgado
```

Un permiso que nunca se otorgó tampoco se puede usar: `DENY` no es necesario para que algo falle, pero deja la prohibición explícita y documentada.

### 3.4 Cómo probar los permisos

La sentencia `EXECUTE AS USER = '...'` hace que las instrucciones siguientes se ejecuten con los permisos de ese usuario, y `REVERT` vuelve al usuario original. Así se prueba cada perfil sin abrir una conexión distinta. Para que el contexto se restablezca aunque la prueba falle, las pruebas de restricción se envuelven en `TRY...CATCH`.

### 3.5 Procedimientos y encadenamiento de propietarios

Cuando un procedimiento y las tablas que usa pertenecen al mismo propietario (aquí, el esquema `dbo`), SQL Server no vuelve a evaluar los permisos sobre las tablas dentro del procedimiento: alcanza con tener permiso de `EXECUTE`. Este mecanismo se conoce como *encadenamiento de propietarios* (ownership chaining). Por eso un usuario sin `INSERT` sobre `turno` puede igualmente registrar un turno a través de `usp_RegistrarTurno`.

## 4. Caso concreto aplicado al sistema de ventas (Venus Spa)

El script `seguridad.sql` se divide en dos partes, según lo pedido: permisos a nivel de **usuarios** y permisos a nivel de **roles**. Ambas usan el procedimiento `usp_RegistrarTurno` y la tabla `turno`.

### 4.1 Verificación del modo de autenticación

Se consulta `SERVERPROPERTY('IsIntegratedSecurityOnly')`. El valor `0` confirma el modo mixto, requisito para crear los inicios de sesión de SQL Server que se usan a continuación.

### 4.2 Permisos a nivel de usuarios

| Elemento | Nombre | Permisos |
|---|---|---|
| Login y usuario de administrador | `login_admin_spa` / `usuario_admin` | Rol fijo `db_owner` (en esta parte) |
| Login y usuario de solo lectura | `login_lectura_spa` / `usuario_lectura` | Rol fijo `db_datareader` y `EXECUTE` sobre `dbo.usp_RegistrarTurno` |

Pasos del script:

1. Crear los dos logins y los dos usuarios (con comprobación de existencia, para poder repetir el script).
2. Asignar `db_owner` al administrador y `db_datareader` al usuario de solo lectura.
3. Otorgar `EXECUTE` sobre `usp_RegistrarTurno` al usuario de solo lectura.
4. Probar cada usuario: lectura de `turno`, `INSERT` directo con ambos, y `INSERT` a través del procedimiento con el usuario de solo lectura.
5. Revocar el permiso de ejecución con `REVOKE` y comprobar que el usuario de solo lectura ya no puede usar el procedimiento.

**Por qué el usuario de solo lectura puede registrar un turno por el procedimiento:** el `INSERT` directo falla porque `db_datareader` solo concede lectura, pero el procedimiento sí funciona porque se ejecuta bajo el encadenamiento de propietarios: solo se verifica el permiso `EXECUTE`. El procedimiento actúa como una puerta controlada hacia la escritura.

### 4.3 Permisos a nivel de roles

Los tres perfiles surgen de los casos de uso del proyecto: recepcionista, dueño y administración. Se crea un login, un usuario y un rol para el recepcionista y el dueño; para administración se reutiliza `usuario_admin`.

| Rol | Usuario | `SELECT` en `turno` | `INSERT` directo en `turno` | `DELETE` directo en `turno` | `EXECUTE` de `usp_RegistrarTurno` |
|---|---|---|---|---|---|
| `rol_recepcionista` | `usuario_recepcionista` | No (no se le otorgó) | Denegado (`DENY`) | Denegado (`DENY`) | Sí |
| `rol_dueno` | `usuario_dueno` | Sí | No (no se le otorgó) | No (no se le otorgó) | No (no se le otorgó) |
| `rol_administracion` | `usuario_admin` | Sí | Sí | Sí | Sí |

Para `rol_administracion` se otorgan `SELECT`, `INSERT`, `UPDATE`, `DELETE` y `EXECUTE` sobre el esquema `dbo`. Al asociarlo a `usuario_admin` se le quita `db_owner`, porque ese rol concedía permisos superiores a los necesarios, en línea con el principio de mínimo privilegio. Como consecuencia, el administrador ya no puede crear ni modificar la estructura de la base (`CREATE`/`ALTER`).

**Por qué roles y no permisos directos:** si el spa incorpora un segundo recepcionista, alcanza con agregarlo al rol y hereda todos sus permisos, sin repetir los `GRANT` y `DENY`.

### 4.4 Observaciones de diseño

- **`usp_RegistrarVenta` queda fuera:** el grupo previó dar permisos de ejecución sobre `usp_RegistrarVenta`, pero ese procedimiento todavía no existe, por lo que no se pudo configurar. Cuando se cree, bastará con otorgar `EXECUTE` al rol que corresponda.
- **El dueño solo ve `turno`:** para sus informes probablemente necesite consultar otras tablas (ventas, servicios, clientes). Ampliar su permiso a otras tablas, o a un conjunto de vistas, no requiere cambiar la estructura de roles.
- **El recepcionista no puede leer `turno`:** en una aplicación real necesitaría consultar algunos datos para operar (por ejemplo, camillas libres). Eso se puede resolver con funciones o vistas específicas, sin darle acceso a la tabla completa.
- **Contraseñas en el script:** figuran en texto plano porque es un trabajo académico. En un entorno real no se guardarían dentro de un script versionado.

---

## 5. Script de demostración y resultados obtenidos

La demostración está en `sql/tecnico/seguridad.sql` y usa los datos ya cargados en la base. Se ejecuta en este orden:

**Parte 1: permisos a nivel de usuarios**

1. **Modo de autenticación:** consulta de `SERVERPROPERTY`.
2. **Creación y verificación de usuarios:** consulta de `sys.database_principals`.
3. **Acceso del administrador y del usuario de solo lectura:** `SELECT` sobre `turno` con cada uno.
4. **`INSERT` directo con el usuario de solo lectura:** debe rechazarse.
5. **`INSERT` directo con el administrador:** debe funcionar.
6. **`INSERT` por procedimiento con el usuario de solo lectura:** debe funcionar y registrar también la asignación del profesional.
7. **`REVOKE` y nuevo intento:** el usuario de solo lectura ya no puede ejecutar el procedimiento.

**Parte 2: permisos a nivel de roles**

8. **Dueño:** puede leer `turno` y no puede insertar.
9. **Recepcionista:** no puede insertar ni leer `turno`, y sí puede registrar un turno con el procedimiento.
10. **Administración:** puede leer e insertar.

### Resultados

| Prueba | Resultado esperado | Captura |
|---|---|---|
| 1. Modo de autenticación | El valor devuelto es `0` (modo mixto) | `evidencias/01_modo_autenticacion.png` |
| 2. Usuarios creados | Dos filas: `usuario_admin` y `usuario_lectura` | `evidencias/02_usuarios_creados.png` |
| 3. `SELECT` con administrador y con solo lectura | Ambos ven las filas de `turno` | `evidencias/03_select_usuarios.png` |
| 4. `INSERT` directo con solo lectura | Error 229: permiso `INSERT` denegado sobre `turno` | `evidencias/04_insert_lectura_error.png` |
| 5. `INSERT` directo con administrador | La fila se inserta y aparece en la verificación | `evidencias/05_insert_admin.png` |
| 6. `INSERT` por procedimiento con solo lectura | Se devuelve un `id_turno`; hay una fila en `turno` y otra en `se_asigna_turno` | `evidencias/06_procedimiento_lectura.png` |
| 7. Dueño | `SELECT` correcto; `INSERT` con error 229 | `evidencias/07_prueba_dueno.png` |
| 8a. Recepcionista, `INSERT` directo | Error 229: permiso `INSERT` denegado | `evidencias/08a_recepcionista_insert_error.png` |
| 8b. Recepcionista, `SELECT` | Error 229: permiso `SELECT` denegado | `evidencias/08b_recepcionista_select_error.png` |
| 8c. Recepcionista, procedimiento | Se devuelve un `id_turno` | `evidencias/08c_recepcionista_procedimiento.png` |
| 9. Administración | `SELECT` e `INSERT` correctos | `evidencias/9_prueba_administracion.png` |

---

## 6. Conclusiones

- **Los permisos se acumulan por separado y cada operación se controla por sí sola.** Un usuario con `db_datareader` lee todo y no puede escribir; el permiso `EXECUTE` sobre un procedimiento no le da acceso a las tablas, pero si le permite el efecto que el procedimiento produce.
- **Un procedimiento almacenado funciona como una puerta controlada.** El usuario de solo lectura y el recepcionista no pueden insertar en `turno`, pero si registrar un turno con `usp_RegistrarTurno`, porque el encadenamiento de propietarios evita revisar los permisos sobre las tablas dentro del procedimiento. Así se garantiza que cada turno pase por las validaciones del procedimiento y tenga profesional asignado (RN.07.1).
- **`REVOKE` y `DENY` no son lo mismo.** `REVOKE` retira un permiso otorgado y deja al usuario sin él; `DENY` lo prohíbe de forma explícita y prevalece aunque otro rol lo otorgue. El recepcionista tampoco puede leer `turno`, pero no porque este denegado: nunca se le concedió ese permiso.
- **Los roles simplifican la administración.** Los permisos se definen una vez en el rol y se heredan al agregar usuarios; la comparación entre el dueño (con el rol de lectura) y el recepcionista (sin el) muestra la diferencia al leer `turno`.
- **Se aplico el principio de minimo privilegio.** Al administrador se le quito `db_owner` y se le dio un rol propio con los permisos necesarios sobre el esquema `dbo`; a cambio, ya no puede modificar la estructura de la base.

## Bibliografía

- Universidad Nacional del Nordeste, FaCENA. (s. f.). *Unidad 5. SQL y SQL Avanzado, Tema 12: Autorización (Control)* [Guía de lectura]. Bases de Datos I, Lic. en Sistemas de Información. (También se consultaron los temas 10 y 14 de la misma guía).
- Microsoft. (s. f.). *Elección de un modo de autenticación*. Microsoft Learn. https://learn.microsoft.com/es-es/sql/relational-databases/security/choose-an-authentication-mode?view=sql-server-ver17