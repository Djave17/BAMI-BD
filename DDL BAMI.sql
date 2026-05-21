/* ============================================================
   BASE DE DATOS: Sistema de Rutas y Donaciones
   Motor: SQL Server
   Basado en el diagrama UML proporcionado
   ============================================================ */

IF DB_ID(N'BD_Rutas_Donaciones') IS NULL
BEGIN
    CREATE DATABASE BAMI;
END
GO

USE BD_Rutas_Donaciones;
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