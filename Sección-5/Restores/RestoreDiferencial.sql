USE master;
GO

--se restaura el backup completo
RESTORE DATABASE BAMI_RestoreDiff
FROM DISK = 'C:\bami\backups\BAMI_FULL.bak'
WITH 
    MOVE 'BAMI' TO 'C:\bami\restore\BAMI_RestoreDiff.mdf',
    MOVE 'BAMI_log' TO 'C:\bami\restore\BAMI_RestoreDiff_log.ldf',
    NORECOVERY,
    STATS = 10;
GO

--se restaura el backup diferencial
RESTORE DATABASE BAMI_RestoreDiff
FROM DISK = 'C:\bami\backups\BAMI_DIFF.bak'
WITH 
    RECOVERY,
    STATS = 10;
GO