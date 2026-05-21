USE master;
GO

ALTER DATABASE BAMI 
SET RECOVERY FULL;
GO

SELECT 
    name AS BaseDatos,
    recovery_model_desc AS ModeloRecuperacion
FROM sys.databases
WHERE name = 'BAMI';
GO