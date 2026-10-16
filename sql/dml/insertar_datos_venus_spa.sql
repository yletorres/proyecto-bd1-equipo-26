USE Venus_Spa;
GO

-- =============================================================================
-- Inserción de datos de prueba para Venus Spa
-- =============================================================================

-- =============================================================================
-- 1. Tabla: persona
-- =============================================================================

INSERT INTO persona (dni_persona, nombre_completo, telefono_persona) VALUES
(28456123, 'Valeria Romero',        '3794112233'),
(30987456, 'Esteban Benitez',       '3794223344'),
(32112233, 'Camila Fernandez',      '3794334455'),
(34556677, 'Gonzalo Morales',       '3794445566'),
(36778899, 'Florencia Gimenez',     '3794556677'),
(38123456, 'Mariano Acosta',        '3794667788'),
(29456789, 'Lucia Navarro',         '3794778899'),
(31567890, 'Rodrigo Duarte',        '3794889900'),
(33678901, 'Martina Sosa',          '3794990011'),
(35789012, 'Joaquin Paredes',       '3794123456'),
(27123987, 'Beatriz Almirón',       '3794234567'),
(39876543, 'Lautaro Rivas',         '3794345678'),
(40112233, 'Sofia Maidana',         '3794456789'),
(41223344, 'Emiliano Castillo',     '3794567890'),
(42334455, 'Agustina Ibañez',       '3794678901'),
(43445566, 'Nicolas Vera',          '3794789012'),
(44556677, 'Julieta Cardozo',       '3794890123'),
(45667788, 'Franco Ortiz',          '3794901234'),
(26998877, 'Patricia Cabrera',      '3794012345'),
(37889900, 'Ignacio Ramirez',       '3794111222');
GO

-- =============================================================================
-- 2. Tabla: profesional
-- Algunos profesionales tienen matrícula y otros no (NULL)
-- =============================================================================

INSERT INTO profesional (dni_profesional, fecha_ingreso, matricula) VALUES
(28456123, '2021-03-01', 'MN-45892'),
(30987456, '2021-06-15', 'MN-51204'),
(32112233, '2022-02-01', NULL),
(34556677, '2022-08-10', 'MN-60311'),
(36778899, '2023-01-20', NULL),
(38123456, '2023-05-12', 'MN-72840'),
(29456789, '2023-09-01', 'MN-48901'),
(31567890, '2024-02-15', NULL),
(33678901, '2024-04-10', 'MN-81230'),
(35789012, '2024-07-01', NULL);
GO

-- =============================================================================
-- 3. Tabla: cliente
-- Valeria Romero (DNI 28456123) es tanto profesional como cliente
-- =============================================================================

INSERT INTO cliente (dni_cliente, direccion, fecha_nacimiento) VALUES
(28456123, 'Av. 3 de Abril 1240, Corrientes', '1981-05-14'),
(27123987, 'Junín 850, Corrientes',             '1979-11-23'),
(39876543, 'San Martín 1520, Resistencia',      '1996-08-04'),
(40112233, 'Pellegrini 430, Corrientes',        '1997-03-19'),
(41223344, 'Av. Alberdi 620, Resistencia',      '1998-10-30'),
(42334455, '9 de Julio 1890, Corrientes',       '1999-12-15'),
(43445566, 'Av. Sarmiento 310, Resistencia',    '2001-04-22'),
(44556677, 'Córdoba 750, Corrientes',           '2002-07-09'),
(45667788, 'Av. Castelli 1400, Resistencia',    '2003-09-18'),
(26998877, 'Mendoza 1120, Corrientes',          '1978-02-27'),
(37889900, 'Santa Fe 980, Corrientes',          '1993-06-11');
GO

-- =============================================================================
-- 4. Tabla: camilla
-- =============================================================================

INSERT INTO camilla (nombre) VALUES
('Camilla 01 - Facial Premium'),
('Camilla 02 - Masajes Relajantes'),
('Camilla 03 - Estética Corporal'),
('Camilla 04 - Drenaje y Postoperatorio'),
('Camilla 05 - Tratamientos Láser'),
('Camilla 06 - Cosmiatría Avanzada'),
('Camilla 07 - Ozonoterapia y Spa'),
('Camilla 08 - Radiofrecuencia'),
('Camilla 09 - Sueroterapia'),
('Camilla 10 - Peeling y Cuidados');
GO

-- =============================================================================
-- 5. Tabla: servicio
-- =============================================================================

INSERT INTO servicio (denominacion, precio_unitario) VALUES
('PRP Facial (Plasma Rico en Plaquetas)',              25000.00),
('Limpieza Facial Profunda con Punta de Diamante',     12000.00),
('Masaje Descontracturante Integral',                  15000.00),
('Drenaje Linfático Manual',                           14000.00),
('Peeling Químico Renovador',                          16500.00),
('Radiofrecuencia Tripolar Facial',                    18000.00),
('Depilación Definitiva Láser Diodo',                  22000.00),
('Tratamiento Antiacné y Descongestivo',               13500.00),
('Exfoliación e Hidratación Corporal',                 17000.00),
('Ozonoterapia Revitalizante',                         20000.00);
GO

-- =============================================================================
-- 6. Tabla: turno
-- =============================================================================

INSERT INTO turno (
    fecha_turno,
    franja_horaria,
    estado,
    metodo_pago_turno,
    precio_historico,
    dni_cliente,
    id_camilla,
    id_servicio
) VALUES
('2026-09-01', '08:00:00', 'realizado',  'transferencia',      25000.00, 27123987, 1,  1),
('2026-09-01', '09:00:00', 'realizado',  'efectivo',           12000.00, 39876543, 2,  2),
('2026-09-01', '10:00:00', 'realizado',  'tarjeta de debito',  15000.00, 40112233, 3,  3),
('2026-09-02', '15:00:00', 'realizado',  'tarjeta de credito', 14000.00, 41223344, 4,  4),
('2026-09-02', '16:00:00', 'realizado',  'transferencia',      16500.00, 42334455, 5,  5),
('2026-09-03', '08:00:00', 'confirmado', 'efectivo',           18000.00, 43445566, 6,  6),
('2026-09-03', '11:00:00', 'confirmado', 'tarjeta de debito',  22000.00, 44556677, 7,  7),
('2026-09-04', '17:00:00', 'pendiente',  'transferencia',      13500.00, 45667788, 8,  8),
('2026-09-04', '18:00:00', 'cancelado',  'efectivo',           17000.00, 26998877, 9,  9),
('2026-09-05', '09:00:00', 'confirmado', 'tarjeta de credito', 20000.00, 37889900, 10, 10),
('2026-09-05', '10:00:00', 'realizado',  'transferencia',      25000.00, 28456123, 1,  1);
GO

-- =============================================================================
-- 7. Tabla: se_asigna_turno
-- En el turno 1 se asignan dos profesionales
-- =============================================================================

INSERT INTO se_asigna_turno (dni_profesional, id_turno) VALUES
(28456123, 1),
(30987456, 1),
(32112233, 2),
(34556677, 3),
(36778899, 4),
(38123456, 5),
(29456789, 6),
(31567890, 7),
(33678901, 8),
(35789012, 9),
(28456123, 10),
(30987456, 11);
GO

-- =============================================================================
-- 8. Tabla: venta
-- =============================================================================

INSERT INTO venta (fecha_venta, metodo_pago_venta, dni_cliente) VALUES
('2026-09-01', 'efectivo',           27123987),
('2026-09-01', 'tarjeta de debito',  39876543),
('2026-09-02', 'transferencia',      40112233),
('2026-09-02', 'tarjeta de credito', 41223344),
('2026-09-03', 'efectivo',           42334455),
('2026-09-03', 'transferencia',      43445566),
('2026-09-04', 'tarjeta de debito',  44556677),
('2026-09-04', 'efectivo',           45667788),
('2026-09-05', 'transferencia',      26998877),
('2026-09-05', 'tarjeta de credito', 37889900),
('2026-09-05', 'efectivo',           28456123);
GO

-- =============================================================================
-- 9. Tabla: producto
-- =============================================================================

INSERT INTO producto (nombre_producto, precio_vigente, stock_disponible) VALUES
('Crema Hidratante Facial con Ácido Hialurónico',  8500.00, 35),
('Serum Antioxidante con Vitamina C al 15%',      12500.00, 20),
('Protector Solar Facial FPS 50+ Toque Seco',     14200.00, 50),
('Espuma Limpiadora Purificante',                  6800.00, 40),
('Loción Tónica Calmante con Manzanilla',          5900.00, 25),
('Gel Exfoliante Microgránulos',                   7400.00, 30),
('Máscara Facial Reparadora Nocturna',            11000.00, 18),
('Shampoo Fortalecedor con Biotina y Keratina',    9300.00, 22),
('Bálsamo Labial Regenerador con Filtro UV',       3200.00, 60),
('Emulsión Corporal Nutritiva con Rosa Mosqueta', 10500.00, 15);
GO

-- =============================================================================
-- 10. Tabla: contiene
-- Productos dentro de cada venta
-- =============================================================================

INSERT INTO contiene (id_venta, id_producto, cantidad, precio) VALUES
(1,  1, 2,  8500.00),
(1,  3, 1, 14200.00),
(2,  2, 1, 12500.00),
(3,  4, 2,  6800.00),
(3,  5, 1,  5900.00),
(4,  6, 1,  7400.00),
(5,  7, 1, 11000.00),
(6,  8, 2,  9300.00),
(7,  9, 3,  3200.00),
(8, 10, 1, 10500.00),
(9,  1, 1,  8500.00),
(9,  2, 1, 12500.00),
(10, 3, 2, 14200.00),
(11, 8, 1,  9300.00);
GO

