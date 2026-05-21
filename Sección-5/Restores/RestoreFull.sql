USE master;
GO

RESTORE DATABASE BAMI_RestoreFull
FROM DISK = 'C:\bami\backups\BAMI_FULL.bak'
WITH 
    MOVE 'BAMI' TO 'C:\bami\restore\BAMI_RestoreFull.mdf',
    MOVE 'BAMI_log' TO 'C:\bami\restore\BAMI_RestoreFull_log.ldf',
    RECOVERY,
    STATS = 10;
GO  