USE master;
GO

BACKUP DATABASE BAMI
TO DISK = 'C:\bami\backups\BAMI_DIFF.bak'
WITH 
    DIFFERENTIAL,
    INIT,
    NAME = 'Respaldo Diferencial BAMI',
    DESCRIPTION = 'Respaldo diferencial de la base de datos BAMI',
    CHECKSUM,
    STATS = 10;
GO