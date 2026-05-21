
-- IDENTIFICACIONDE PROBLEMAS DE RENDIMIENTO

USE BAMI;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- Consulta de prueba: rutas asignadas a un recolector
SELECT 
    RH.id_ruta AS IdRuta,
    RH.fecha_ruta AS FechaRuta,
    RD.id_ruta_detalle AS IdParada,
    S.nombre AS NombreSucursal,
    EP.nombre AS EstadoParada
FROM dbo.RutaHeader RH
INNER JOIN dbo.RutaDetalle RD 
    ON RH.id_ruta = RD.id_ruta
INNER JOIN dbo.Sucursal S 
    ON RD.id_sucursal = S.id_sucursal
INNER JOIN dbo.EstadoParada EP
    ON RD.id_estado_parada = EP.id_estado_parada
WHERE RH.codigo_recolector = 1
  AND RH.fecha_ruta = CAST(GETDATE() AS DATE);
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO



--IMPLEMENTACION DE INDICES Y PTIMIZACIOND DE CONSULTAS

USE BAMI;
GO

-- Índice extra para buscar rutas por recolector y fecha
IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IX_RutaHeader_Recolector_Fecha'
      AND object_id = OBJECT_ID('dbo.RutaHeader')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_RutaHeader_Recolector_Fecha
    ON dbo.RutaHeader (codigo_recolector, fecha_ruta);
END
GO



--REVISIONES DE CONFIGIRACIONES CRITICAS
USE master;
GO

-- Revisar estado y configuración de la base de datos
SELECT 
    name AS NombreBaseDatos,
    state_desc AS Estado,
    recovery_model_desc AS ModeloRecuperacion,
    compatibility_level AS NivelCompatibilidad
FROM sys.databases
WHERE name = 'BAMI';
GO

-- Revisar tamaño y crecimiento de archivos
SELECT 
    name AS NombreArchivo,
    type_desc AS TipoArchivo,
    size * 8 / 1024 AS TamañoMB,
    growth AS CrecimientoConfigurado,
    is_percent_growth AS CrecimientoPorcentaje
FROM sys.master_files
WHERE database_id = DB_ID('BAMI');
GO

-- Revisar estadísticas automáticas
SELECT 
    name,
    is_auto_create_stats_on AS AutoCreateStats,
    is_auto_update_stats_on AS AutoUpdateStats
FROM sys.databases
WHERE name = 'BAMI';
GO



--MANTENIMIENTO RPECVENTIVO

USE BAMI;
GO

-- Verificar que se está usando la base correcta
SELECT DB_NAME() AS BaseActual;
GO

-- Actualizar estadísticas
EXEC sp_updatestats;
GO

-- Reorganizar índices
ALTER INDEX ALL ON dbo.Usuario REORGANIZE;
ALTER INDEX ALL ON dbo.Recolector REORGANIZE;
ALTER INDEX ALL ON dbo.Sucursal REORGANIZE;
ALTER INDEX ALL ON dbo.CategoriaDonacion REORGANIZE;
ALTER INDEX ALL ON dbo.EstadoParada REORGANIZE;
ALTER INDEX ALL ON dbo.RutaHeader REORGANIZE;
ALTER INDEX ALL ON dbo.RutaDetalle REORGANIZE;
ALTER INDEX ALL ON dbo.DonacionHeader REORGANIZE;
ALTER INDEX ALL ON dbo.DonacionDetalle REORGANIZE;
GO

-- Verificar integridad de la base de datos
DBCC CHECKDB ('BAMI') WITH NO_INFOMSGS;
GO