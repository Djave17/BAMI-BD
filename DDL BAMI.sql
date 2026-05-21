/* ============================================================
   BASE DE DATOS: Sistema de Rutas y Donaciones
   Motor: SQL Server
   Basado en el diagrama UML proporcionado
   ============================================================ */

IF DB_ID(N'BAMI') IS NULL
BEGIN
    CREATE DATABASE BAMI;
END
GO

USE BAMI;
GO



/* ============================================================
   LIMPIEZA DE OBJETOS
   ============================================================ */

DROP VIEW IF EXISTS dbo.vw_DonacionTotal;
DROP VIEW IF EXISTS dbo.vw_RutaProgreso;
GO

DROP TABLE IF EXISTS dbo.DonacionDetalle;
DROP TABLE IF EXISTS dbo.DonacionHeader;
DROP TABLE IF EXISTS dbo.RutaDetalle;
DROP TABLE IF EXISTS dbo.RutaHeader;
DROP TABLE IF EXISTS dbo.Recolector;
DROP TABLE IF EXISTS dbo.Usuario;
DROP TABLE IF EXISTS dbo.Sucursal;
DROP TABLE IF EXISTS dbo.CategoriaDonacion;
DROP TABLE IF EXISTS dbo.EstadoParada;
GO

/* ============================================================
   TABLA: Usuario
   Clase padre del Recolector
   ============================================================ */

CREATE TABLE dbo.Usuario
(
    id_usuario INT IDENTITY(1,1) NOT NULL,
    correo NVARCHAR(120) NOT NULL,
    nombre_usuario NVARCHAR(100) NOT NULL,
    telefono NVARCHAR(20) NULL,
    activo BIT NOT NULL CONSTRAINT DF_Usuario_Activo DEFAULT (1),

    CONSTRAINT PK_Usuario PRIMARY KEY (id_usuario),
    CONSTRAINT UQ_Usuario_Correo UNIQUE (correo),
    CONSTRAINT CK_Usuario_Correo CHECK (correo LIKE '%@%.%'),
    CONSTRAINT CK_Usuario_Telefono CHECK (
        telefono IS NULL OR LEN(LTRIM(RTRIM(telefono))) BETWEEN 7 AND 20
    )
);
GO

/* ============================================================
   TABLA: Recolector
   Hereda de Usuario
   ============================================================ */

CREATE TABLE dbo.Recolector
(
    codigo_recolector INT IDENTITY(1,1) NOT NULL,
    id_usuario INT NOT NULL,

    CONSTRAINT PK_Recolector PRIMARY KEY (codigo_recolector),
    CONSTRAINT UQ_Recolector_Usuario UNIQUE (id_usuario),

    CONSTRAINT FK_Recolector_Usuario
        FOREIGN KEY (id_usuario)
        REFERENCES dbo.Usuario(id_usuario)
);
GO

/* ============================================================
   TABLA: CategoriaDonacion
   ============================================================ */

CREATE TABLE dbo.CategoriaDonacion
(
    id_categoria INT IDENTITY(1,1) NOT NULL,
    nombre NVARCHAR(80) NOT NULL,
    descripcion NVARCHAR(250) NULL,
    activo BIT NOT NULL CONSTRAINT DF_CategoriaDonacion_Activo DEFAULT (1),

    CONSTRAINT PK_CategoriaDonacion PRIMARY KEY (id_categoria),
    CONSTRAINT UQ_CategoriaDonacion_Nombre UNIQUE (nombre)
);
GO

/* ============================================================
   TABLA: Sucursal
   ============================================================ */

CREATE TABLE dbo.Sucursal
(
    id_sucursal INT IDENTITY(1,1) NOT NULL,
    nombre NVARCHAR(120) NOT NULL,
    correo NVARCHAR(120) NULL,
    telefono NVARCHAR(20) NULL,
    activo BIT NOT NULL CONSTRAINT DF_Sucursal_Activo DEFAULT (1),

    CONSTRAINT PK_Sucursal PRIMARY KEY (id_sucursal),
    CONSTRAINT CK_Sucursal_Correo CHECK (
        correo IS NULL OR correo LIKE '%@%.%'
    ),
    CONSTRAINT CK_Sucursal_Telefono CHECK (
        telefono IS NULL OR LEN(LTRIM(RTRIM(telefono))) BETWEEN 7 AND 20
    )
);
GO

/* ============================================================
   TABLA: EstadoParada
   Representa la enumeración EstadoParada del UML
   ============================================================ */

CREATE TABLE dbo.EstadoParada
(
    id_estado_parada TINYINT NOT NULL,
    nombre NVARCHAR(30) NOT NULL,

    CONSTRAINT PK_EstadoParada PRIMARY KEY (id_estado_parada),
    CONSTRAINT UQ_EstadoParada_Nombre UNIQUE (nombre)
);
GO

INSERT INTO dbo.EstadoParada (id_estado_parada, nombre)
VALUES
    (1, N'Aprobada'),
    (2, N'Rechazada'),
    (3, N'Completada'),
    (4, N'Entrega'),
    (5, N'EnEspera'),
    (6, N'EsperaVencida');
GO

/* ============================================================
   TABLA: RutaHeader
   Cabecera de la ruta asignada a un recolector
   ============================================================ */

CREATE TABLE dbo.RutaHeader
(
    id_ruta INT IDENTITY(1,1) NOT NULL,
    codigo_recolector INT NOT NULL,
    fecha_ruta DATE NOT NULL CONSTRAINT DF_RutaHeader_FechaRuta DEFAULT (CAST(GETDATE() AS DATE)),
    activo BIT NOT NULL CONSTRAINT DF_RutaHeader_Activo DEFAULT (1),

    CONSTRAINT PK_RutaHeader PRIMARY KEY (id_ruta),

    CONSTRAINT FK_RutaHeader_Recolector
        FOREIGN KEY (codigo_recolector)
        REFERENCES dbo.Recolector(codigo_recolector)
);
GO

/* ============================================================
   TABLA: RutaDetalle
   Detalle de paradas de una ruta
   Nota: La sucursal se coloca aquí porque la visita,
   check-in y check-out ocurren en una parada específica.
   ============================================================ */

CREATE TABLE dbo.RutaDetalle
(
    id_ruta_detalle INT IDENTITY(1,1) NOT NULL,
    id_ruta INT NOT NULL,
    id_sucursal INT NOT NULL,
    id_estado_parada TINYINT NOT NULL CONSTRAINT DF_RutaDetalle_Estado DEFAULT (5),

    hora_visita DATETIME2(0) NOT NULL,
    check_in DATETIME2(0) NULL,
    check_out DATETIME2(0) NULL,

    CONSTRAINT PK_RutaDetalle PRIMARY KEY (id_ruta_detalle),

    CONSTRAINT FK_RutaDetalle_RutaHeader
        FOREIGN KEY (id_ruta)
        REFERENCES dbo.RutaHeader(id_ruta)
        ON DELETE CASCADE,

    CONSTRAINT FK_RutaDetalle_Sucursal
        FOREIGN KEY (id_sucursal)
        REFERENCES dbo.Sucursal(id_sucursal),

    CONSTRAINT FK_RutaDetalle_EstadoParada
        FOREIGN KEY (id_estado_parada)
        REFERENCES dbo.EstadoParada(id_estado_parada),

    CONSTRAINT CK_RutaDetalle_CheckOut CHECK (
        check_out IS NULL OR check_in IS NULL OR check_out >= check_in
    )
);
GO

/* ============================================================
   TABLA: DonacionHeader
   Cabecera de la donación
   Relación: una parada puede tener 0 o 1 donación
   ============================================================ */

CREATE TABLE dbo.DonacionHeader
(
    id_donacion INT IDENTITY(1,1) NOT NULL,
    id_ruta_detalle INT NOT NULL,

    fecha_ingresa DATETIME2(0) NOT NULL CONSTRAINT DF_DonacionHeader_Fecha DEFAULT (SYSDATETIME()),
    num_recibo NVARCHAR(40) NOT NULL,
    num_requisicion NVARCHAR(40) NULL,
    estado_bodega NVARCHAR(30) NOT NULL CONSTRAINT DF_DonacionHeader_EstadoBodega DEFAULT (N'Pendiente'),

    CONSTRAINT PK_DonacionHeader PRIMARY KEY (id_donacion),
    CONSTRAINT UQ_DonacionHeader_RutaDetalle UNIQUE (id_ruta_detalle),
    CONSTRAINT UQ_DonacionHeader_NumRecibo UNIQUE (num_recibo),

    CONSTRAINT FK_DonacionHeader_RutaDetalle
        FOREIGN KEY (id_ruta_detalle)
        REFERENCES dbo.RutaDetalle(id_ruta_detalle),

    CONSTRAINT CK_DonacionHeader_EstadoBodega CHECK (
        estado_bodega IN (N'Pendiente', N'Recibida', N'Validada', N'Rechazada')
    )
);
GO

CREATE UNIQUE INDEX UX_DonacionHeader_NumRequisicion
ON dbo.DonacionHeader(num_requisicion)
WHERE num_requisicion IS NOT NULL;
GO

/* ============================================================
   TABLA: DonacionDetalle
   Detalle de categorías, peso y monto de la donación
   Relación: una donación tiene uno o varios detalles
   ============================================================ */

CREATE TABLE dbo.DonacionDetalle
(
    id_donacion_detalle INT IDENTITY(1,1) NOT NULL,
    id_donacion INT NOT NULL,
    id_categoria INT NOT NULL,

    monto DECIMAL(12,2) NOT NULL CONSTRAINT DF_DonacionDetalle_Monto DEFAULT (0),
    peso DECIMAL(10,3) NOT NULL,

    CONSTRAINT PK_DonacionDetalle PRIMARY KEY (id_donacion_detalle),

    CONSTRAINT FK_DonacionDetalle_DonacionHeader
        FOREIGN KEY (id_donacion)
        REFERENCES dbo.DonacionHeader(id_donacion)
        ON DELETE CASCADE,

    CONSTRAINT FK_DonacionDetalle_CategoriaDonacion
        FOREIGN KEY (id_categoria)
        REFERENCES dbo.CategoriaDonacion(id_categoria),

    CONSTRAINT CK_DonacionDetalle_Monto CHECK (monto >= 0),
    CONSTRAINT CK_DonacionDetalle_Peso CHECK (peso > 0)
);
GO

/* ============================================================
   ÍNDICES PARA CLAVES FORÁNEAS
   ============================================================ */

CREATE INDEX IX_Recolector_Usuario
ON dbo.Recolector(id_usuario);

CREATE INDEX IX_RutaHeader_Recolector
ON dbo.RutaHeader(codigo_recolector);

CREATE INDEX IX_RutaDetalle_Ruta
ON dbo.RutaDetalle(id_ruta);

CREATE INDEX IX_RutaDetalle_Sucursal
ON dbo.RutaDetalle(id_sucursal);

CREATE INDEX IX_DonacionHeader_RutaDetalle
ON dbo.DonacionHeader(id_ruta_detalle);

CREATE INDEX IX_DonacionDetalle_Donacion
ON dbo.DonacionDetalle(id_donacion);

CREATE INDEX IX_DonacionDetalle_Categoria
ON dbo.DonacionDetalle(id_categoria);
GO

/* ============================================================
   VISTA: Total de donación
   Representa la operación calcularTotal()
   ============================================================ */

CREATE VIEW dbo.vw_DonacionTotal
AS
SELECT
    dh.id_donacion,
    dh.num_recibo,
    dh.num_requisicion,
    dh.fecha_ingresa,
    SUM(dd.monto) AS total_monto,
    SUM(dd.peso) AS total_peso,
    COUNT(dd.id_donacion_detalle) AS cantidad_detalles
FROM dbo.DonacionHeader dh
INNER JOIN dbo.DonacionDetalle dd
    ON dh.id_donacion = dd.id_donacion
GROUP BY
    dh.id_donacion,
    dh.num_recibo,
    dh.num_requisicion,
    dh.fecha_ingresa;
GO

/* ============================================================
   VISTA: Progreso de ruta
   Representa la operación calcularProgreso()
   ============================================================ */

CREATE VIEW dbo.vw_RutaProgreso
AS
SELECT
    rh.id_ruta,
    rh.codigo_recolector,
    rh.fecha_ruta,
    COUNT(rd.id_ruta_detalle) AS total_paradas,
    SUM(CASE WHEN ep.nombre = N'Completada' THEN 1 ELSE 0 END) AS paradas_completadas,
    CAST(
        CASE 
            WHEN COUNT(rd.id_ruta_detalle) = 0 THEN 0
            ELSE 
                100.0 * SUM(CASE WHEN ep.nombre = N'Completada' THEN 1 ELSE 0 END)
                / COUNT(rd.id_ruta_detalle)
        END AS DECIMAL(5,2)
    ) AS porcentaje_progreso
FROM dbo.RutaHeader rh
LEFT JOIN dbo.RutaDetalle rd
    ON rh.id_ruta = rd.id_ruta
LEFT JOIN dbo.EstadoParada ep
    ON rd.id_estado_parada = ep.id_estado_parada
GROUP BY
    rh.id_ruta,
    rh.codigo_recolector,
    rh.fecha_ruta;
GO

/* ============================================================
   ============================================================
   INSERCIONES DE DATOS DE EJEMPLO
   ============================================================
   ============================================================ */

PRINT 'Insertando datos de ejemplo...';
GO

-- 1. Insertar usuarios (recolectores)
INSERT INTO dbo.Usuario (correo, nombre_usuario, telefono, activo) VALUES
('carlos.martinez@recoleccion.com', 'Carlos Martínez', '5551234567', 1),
('ana.rodriguez@recoleccion.com', 'Ana Rodríguez', '5552345678', 1),
('luis.fernandez@recoleccion.com', 'Luis Fernández', '5553456789', 1),
('maria.lopez@recoleccion.com', 'María López', '5554567890', 1),
('jorge.ramirez@recoleccion.com', 'Jorge Ramírez', '5555678901', 1);
GO

-- 2. Insertar recolectores
INSERT INTO dbo.Recolector (id_usuario) VALUES
(1), (2), (3), (4), (5);
GO

-- 3. Insertar categorías de donación
INSERT INTO dbo.CategoriaDonacion (nombre, descripcion, activo) VALUES
(N'Alimentos No Perecibles', N'Arroz, frijoles, pasta, enlatados, etc.', 1),
(N'Ropa y Calzado', N'Prendas de vestir en buen estado, zapatos', 1),
(N'Juguetes', N'Juguetes educativos y en buen estado', 1),
(N'Medicinas', N'Medicamentos no vencidos', 1),
(N'Artículos de Limpieza', N'Jabón, cloro, detergentes, etc.', 1),
(N'Equipo Médico', N'Sillas de ruedas, muletas, andaderas', 1),
(N'Útiles Escolares', N'Cuadernos, lápices, mochilas', 1),
(N'Electrodomésticos', N'Licuadoras, microondas, estufas', 1);
GO

-- 4. Insertar sucursales (puntos de recolección)
INSERT INTO dbo.Sucursal (nombre, correo, telefono, activo) VALUES
(N'Sucursal Centro', 'centro@donaciones.org', '5551112233', 1),
(N'Sucursal Norte', 'norte@donaciones.org', '5551113344', 1),
(N'Sucursal Sur', 'sur@donaciones.org', '5551114455', 1),
(N'Sucursal Este', 'este@donaciones.org', '5551115566', 1),
(N'Sucursal Oeste', 'oeste@donaciones.org', '5551116677', 1),
(N'Sucursal Universidad', 'universidad@donaciones.org', '5551117788', 1),
(N'Sucursal Industrial', 'industrial@donaciones.org', '5551118899', 1),
(N'Sucursal Comercial', 'comercial@donaciones.org', '5551119900', 1);
GO

-- 5. Insertar rutas (cabeceras)
INSERT INTO dbo.RutaHeader (codigo_recolector, fecha_ruta, activo) VALUES
(1, '2024-01-15', 1),
(1, '2024-01-20', 1),
(2, '2024-01-18', 1),
(2, '2024-01-25', 1),
(3, '2024-01-22', 1),
(1, '2024-02-01', 1),
(2, '2024-02-05', 1),
(4, '2024-02-10', 1),
(5, '2024-02-15', 1);
GO

-- 6. Insertar detalles de ruta (paradas)
INSERT INTO dbo.RutaDetalle (id_ruta, id_sucursal, id_estado_parada, hora_visita, check_in, check_out) VALUES
-- Ruta 1 (Recolector 1, 15/01/2024)
(1, 1, 3, '2024-01-15 09:00:00', '2024-01-15 09:05:00', '2024-01-15 09:45:00'),
(1, 2, 3, '2024-01-15 10:00:00', '2024-01-15 10:10:00', '2024-01-15 10:50:00'),
(1, 3, 3, '2024-01-15 11:00:00', '2024-01-15 11:05:00', '2024-01-15 11:40:00'),
(1, 4, 2, '2024-01-15 12:00:00', '2024-01-15 12:05:00', '2024-01-15 12:15:00'), -- Rechazada
-- Ruta 2 (Recolector 1, 20/01/2024)
(2, 5, 3, '2024-01-20 09:30:00', '2024-01-20 09:35:00', '2024-01-20 10:20:00'),
(2, 6, 3, '2024-01-20 10:45:00', '2024-01-20 10:50:00', '2024-01-20 11:35:00'),
(2, 7, 1, '2024-01-20 11:50:00', NULL, NULL), -- Aprobada pendiente
-- Ruta 3 (Recolector 2, 18/01/2024)
(3, 8, 3, '2024-01-18 08:30:00', '2024-01-18 08:35:00', '2024-01-18 09:15:00'),
(3, 1, 3, '2024-01-18 09:30:00', '2024-01-18 09:40:00', '2024-01-18 10:20:00'),
(3, 2, 3, '2024-01-18 10:45:00', '2024-01-18 10:50:00', '2024-01-18 11:30:00'),
-- Ruta 4 (Recolector 2, 25/01/2024)
(4, 3, 3, '2024-01-25 14:00:00', '2024-01-25 14:05:00', '2024-01-25 14:50:00'),
(4, 4, 4, '2024-01-25 15:00:00', '2024-01-25 15:10:00', '2024-01-25 15:45:00'), -- Entrega
-- Ruta 5 (Recolector 3, 22/01/2024)
(5, 5, 3, '2024-01-22 10:00:00', '2024-01-22 10:05:00', '2024-01-22 10:50:00'),
(5, 6, 2, '2024-01-22 11:00:00', '2024-01-22 11:05:00', '2024-01-22 11:15:00'), -- Rechazada
(5, 7, 5, '2024-01-22 11:30:00', NULL, NULL), -- En espera
-- Ruta 6 (Recolector 1, 01/02/2024)
(6, 8, 3, '2024-02-01 09:00:00', '2024-02-01 09:10:00', '2024-02-01 09:55:00'),
(6, 1, 3, '2024-02-01 10:15:00', '2024-02-01 10:20:00', '2024-02-01 11:00:00'),
-- Ruta 7 (Recolector 2, 05/02/2024)
(7, 2, 3, '2024-02-05 13:00:00', '2024-02-05 13:05:00', '2024-02-05 13:45:00'),
(7, 3, 3, '2024-02-05 14:00:00', '2024-02-05 14:10:00', '2024-02-05 14:50:00');
GO

-- 7. Insertar encabezados de donación
INSERT INTO dbo.DonacionHeader (id_ruta_detalle, fecha_ingresa, num_recibo, num_requisicion, estado_bodega) VALUES
(1, '2024-01-15 09:50:00', 'REC-2024-0001', 'REQ-001', 'Validada'),
(2, '2024-01-15 11:00:00', 'REC-2024-0002', 'REQ-002', 'Validada'),
(3, '2024-01-15 11:50:00', 'REC-2024-0003', NULL, 'Pendiente'),
(5, '2024-01-20 10:30:00', 'REC-2024-0004', 'REQ-003', 'Recibida'),
(6, '2024-01-20 11:45:00', 'REC-2024-0005', 'REQ-004', 'Validada'),
(8, '2024-01-18 09:25:00', 'REC-2024-0006', 'REQ-005', 'Recibida'),
(9, '2024-01-18 10:30:00', 'REC-2024-0007', 'REQ-006', 'Validada'),
(10, '2024-01-18 11:45:00', 'REC-2024-0008', NULL, 'Pendiente'),
(11, '2024-01-25 15:00:00', 'REC-2024-0009', 'REQ-007', 'Validada'),
(12, '2024-01-25 15:55:00', 'REC-2024-0010', 'REQ-008', 'Recibida'),
(13, '2024-01-22 11:00:00', 'REC-2024-0011', 'REQ-009', 'Validada'),
(16, '2024-02-01 10:05:00', 'REC-2024-0012', 'REQ-010', 'Recibida'),
(17, '2024-02-01 11:10:00', 'REC-2024-0013', NULL, 'Pendiente'),
(18, '2024-02-05 13:55:00', 'REC-2024-0014', 'REQ-011', 'Validada'),
(19, '2024-02-05 15:00:00', 'REC-2024-0015', 'REQ-012', 'Recibida');
GO

-- 8. Insertar detalles de donación
INSERT INTO dbo.DonacionDetalle (id_donacion, id_categoria, monto, peso) VALUES
-- Donación 1 (Alimentos + Ropa)
(1, 1, 1500.00, 45.500),
(1, 2, 800.00, 12.000),
-- Donación 2 (Juguetes + Útiles)
(2, 3, 600.00, 8.500),
(2, 7, 350.00, 5.000),
-- Donación 3 (Solo Alimentos)
(3, 1, 2000.00, 60.000),
-- Donación 4 (Limpieza + Alimentos)
(4, 5, 450.00, 15.000),
(4, 1, 1200.00, 35.000),
-- Donación 5 (Medicinas + Equipo Médico)
(5, 4, 3500.00, 2.500),
(5, 6, 5000.00, 25.000),
-- Donación 6 (Ropa)
(6, 2, 1200.00, 18.000),
-- Donación 7 (Alimentos + Limpieza + Útiles)
(7, 1, 1800.00, 50.000),
(7, 5, 320.00, 10.000),
(7, 7, 280.00, 4.000),
-- Donación 8 (Juguetes)
(8, 3, 750.00, 12.000),
-- Donación 9 (Electrodomésticos)
(9, 8, 3500.00, 45.000),
-- Donación 10 (Alimentos + Ropa)
(10, 1, 950.00, 28.000),
(10, 2, 450.00, 7.000),
-- Donación 11 (Medicinas)
(11, 4, 2800.00, 1.800),
-- Donación 12 (Útiles + Juguetes)
(12, 7, 420.00, 6.000),
(12, 3, 380.00, 5.500),
-- Donación 13 (Solo Alimentos)
(13, 1, 1600.00, 48.000),
-- Donación 14 (Limpieza)
(14, 5, 280.00, 9.000),
-- Donación 15 (Electrodomésticos + Equipo Médico)
(15, 8, 4200.00, 52.000),
(15, 6, 1800.00, 12.000);
GO

/* ============================================================
   CONSULTAS DE VERIFICACIÓN
   ============================================================ */

PRINT '';
PRINT '=== VERIFICACIÓN DE DATOS INSERTADOS ===';
PRINT '';

-- Ver usuarios
PRINT '1. USUARIOS:';
SELECT id_usuario, correo, nombre_usuario, telefono FROM dbo.Usuario;
PRINT '';

-- Ver recolectores
PRINT '2. RECOLECTORES:';
SELECT r.codigo_recolector, u.nombre_usuario, u.correo 
FROM dbo.Recolector r
INNER JOIN dbo.Usuario u ON r.id_usuario = u.id_usuario;
PRINT '';

-- Ver categorías
PRINT '3. CATEGORÍAS:';
SELECT id_categoria, nombre, descripcion FROM dbo.CategoriaDonacion WHERE activo = 1;
PRINT '';

-- Ver sucursales
PRINT '4. SUCURSALES:';
SELECT id_sucursal, nombre, telefono FROM dbo.Sucursal WHERE activo = 1;
PRINT '';

-- Ver rutas
PRINT '5. RUTAS (CABECERAS):';
SELECT rh.id_ruta, u.nombre_usuario AS recolector, rh.fecha_ruta 
FROM dbo.RutaHeader rh
INNER JOIN dbo.Recolector r ON rh.codigo_recolector = r.codigo_recolector
INNER JOIN dbo.Usuario u ON r.id_usuario = u.id_usuario;
PRINT '';

-- Ver detalles de ruta
PRINT '6. DETALLES DE RUTA (primeros 10):';
SELECT TOP 10 rd.id_ruta_detalle, rd.id_ruta, s.nombre AS sucursal, 
       ep.nombre AS estado, rd.hora_visita
FROM dbo.RutaDetalle rd
INNER JOIN dbo.Sucursal s ON rd.id_sucursal = s.id_sucursal
INNER JOIN dbo.EstadoParada ep ON rd.id_estado_parada = ep.id_estado_parada
ORDER BY rd.id_ruta_detalle;
PRINT '';

-- Ver donaciones y sus totales (usando vista)
PRINT '7. DONACIONES CON TOTALES (vw_DonacionTotal):';
SELECT * FROM dbo.vw_DonacionTotal ORDER BY fecha_ingresa DESC;
PRINT '';

-- Ver progreso de rutas (usando vista)
PRINT '8. PROGRESO DE RUTAS (vw_RutaProgreso):';
SELECT * FROM dbo.vw_RutaProgreso ORDER BY fecha_ruta DESC;
PRINT '';

-- Estadísticas generales
PRINT '9. ESTADÍSTICAS GENERALES:';
SELECT 
    (SELECT COUNT(*) FROM dbo.Usuario) AS TotalUsuarios,
    (SELECT COUNT(*) FROM dbo.Recolector) AS TotalRecolectores,
    (SELECT COUNT(*) FROM dbo.Sucursal) AS TotalSucursales,
    (SELECT COUNT(*) FROM dbo.RutaHeader) AS TotalRutas,
    (SELECT COUNT(*) FROM dbo.RutaDetalle) AS TotalParadas,
    (SELECT COUNT(*) FROM dbo.DonacionHeader) AS TotalDonaciones,
    (SELECT COUNT(*) FROM dbo.DonacionDetalle) AS TotalDetallesDonacion;
PRINT '';

-- Resumen de donaciones por categoría
PRINT '10. DONACIONES POR CATEGORÍA:';
SELECT 
    c.nombre AS Categoria,
    COUNT(dd.id_donacion_detalle) AS CantidadDonaciones,
    SUM(dd.monto) AS MontoTotal,
    SUM(dd.peso) AS PesoTotal
FROM dbo.DonacionDetalle dd
INNER JOIN dbo.CategoriaDonacion c ON dd.id_categoria = c.id_categoria
GROUP BY c.nombre
ORDER BY MontoTotal DESC;
PRINT '';

PRINT '=== FIN DE LA CARGA DE DATOS ===';
PRINT '';
PRINT 'Script completado exitosamente.';
GO