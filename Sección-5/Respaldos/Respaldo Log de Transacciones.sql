USE master;
GO

BACKUP LOG BAMI
TO DISK = 'C:\bami\backups\BAMI_LOG.trn'
WITH 
    INIT,
    NAME = 'Respaldo Log de Transacciones BAMI',
    DESCRIPTION = 'Respaldo del log de transacciones de la base de datos BAMI',
    CHECKSUM,
    STATS = 10;
GO