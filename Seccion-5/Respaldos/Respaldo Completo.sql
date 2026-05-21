USE master;
GO

BACKUP DATABASE BAMI
TO DISK = 'C:\bami\backups\BAMI_FULL.bak'
WITH 
    FORMAT,
    INIT,
    NAME = 'Respaldo Completo BAMI',
    DESCRIPTION = 'Respaldo completo de la base de datos BAMI',
    CHECKSUM,
    STATS = 10;
GO