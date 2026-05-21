USE master;
GO

-- Primero se restaura el backup completo
RESTORE DATABASE BAMI_RestoreLog
FROM DISK = 'C:\bami\backups\BAMI_FULL.bak'
WITH 
    MOVE 'BAMI' TO 'C:\bami\restore\BAMI_RestoreLog.mdf',
    MOVE 'BAMI_log' TO 'C:\bami\restore\BAMI_RestoreLog_log.ldf',
    NORECOVERY,
    STATS = 10;
GO

-- Luego se restaura el backup diferencial
RESTORE DATABASE BAMI_RestoreLog
FROM DISK = 'C:\bami\backups\BAMI_DIFF.bak'
WITH 
    NORECOVERY,
    STATS = 10;
GO

-- Finalmente se restaura el backup del log de transacciones
RESTORE LOG BAMI_RestoreLog
FROM DISK = 'C:\bami\backups\BAMI_LOG.trn'
WITH 
    RECOVERY,
    STATS = 10;
GO