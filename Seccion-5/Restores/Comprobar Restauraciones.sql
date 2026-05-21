USE master;
GO

SELECT 
    name AS BaseDatos,
    state_desc AS Estado,
    recovery_model_desc AS ModeloRecuperacion
FROM sys.databases
WHERE name IN 
(
    'BAMI_RestoreFull',
    'BAMI_RestoreDiff',
    'BAMI_RestoreLog'
);
GO