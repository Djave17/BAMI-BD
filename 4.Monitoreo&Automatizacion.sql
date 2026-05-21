
-------------- 4. Monitoreo y automatización ----------------

/*
Por favor asegurarse de tener estas carpetas asi:

En el disco C:

>bami [C:\bami]
>>backups [C:\bami\backups]
>>logs [C:\bami\logs]

*/

---- 1. Uso de logs y eventos extendidos.

-- Si la sesión ya existe y está activa, se detiene y se elimina
IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = 'Monitoreo_Rendimiento_BAMI')
BEGIN
    -- Nota: Si no está encendida puede dar una advertencia, pero el DROP funcionará
    BEGIN TRY
        ALTER EVENT SESSION [Monitoreo_Rendimiento_BAMI] ON SERVER STATE = STOP;
    END TRY
    BEGIN CATCH
        -- Se ignora el error si la sesión ya estaba apagada
    END CATCH;
    
    DROP EVENT SESSION [Monitoreo_Rendimiento_BAMI] ON SERVER;
END
GO

-- Creación de la sesión de monitoreo a nivel de servidor << estamos capturando eventos como:>>
CREATE EVENT SESSION [Monitoreo_Rendimiento_BAMI] ON SERVER 
ADD EVENT sqlserver.error_reported(
    ACTION(sqlserver.client_app_name, sqlserver.database_name, sqlserver.sql_text)
    WHERE ([sqlserver].[database_name]=N'BAMI' AND [severity]>=(16))), -- Errores del sistema o bloqueos
ADD EVENT sqlserver.sql_statement_completed(
    ACTION(sqlserver.database_name, sqlserver.sql_text)
    WHERE ([sqlserver].[database_name]=N'BAMI' AND [duration]>(3000000))) -- Consultas > 3 segundos
ADD TARGET package0.event_file(SET filename=N'C:\bami\logs');
GO

-- Activación del estado de la sesión de eventos
ALTER EVENT SESSION [Monitoreo_Rendimiento_BAMI] ON SERVER STATE = START;
GO







---- 2. Configuración de jobs y mantenimiento & Automatización de tareas administrativas.



-- ***** Job de Respaldo Automatizado con Nombres Dinámicos
USE msdb;
GO

-- 1. LIMPIEZA: Si el Job ya existe, se elimina
IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = N'BAMI_Backup_Log_Transacciones')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = N'BAMI_Backup_Log_Transacciones', @delete_unused_schedule = 1;
END
GO

-- 2. CREACIÓN DEL JOB Y CAPTURA DEL ID EN VARIABLE
DECLARE @ReturnCode INT = 0;
DECLARE @MyJobId BINARY(16);

EXEC @ReturnCode = msdb.dbo.sp_add_job 
    @job_name = N'BAMI_Backup_Log_Transacciones', 
    @enabled = 1, 
    @description = N'Job automatizado para el respaldo por horas del Log de Transacciones de BAMI.', 
    @category_name = N'[Uncategorized (Local)]', 
    @owner_login_name = N'sa',
    @job_id = @MyJobId OUTPUT; -- Guardamos el ID generado aquí

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

-- 3. CREACIÓN DEL PASO 1 (Usando la variable @MyJobId)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
    @job_id = @MyJobId, 
    @step_name = N'Ejecutar Respaldo Dinamico', 
    @step_id = 1, 
    @cmdexec_success_code = 0, 
    @on_success_action = 1, 
    @on_fail_action = 2,    
    @retry_attempts = 1, 
    @retry_interval = 5, 
    @os_run_priority = 0, 
    @subsystem = N'TSQL', 
    @command = N'
DECLARE @NombreArchivo NVARCHAR(255);
DECLARE @FechaId NVARCHAR(20);

SET @FechaId = CONVERT(NVARCHAR(8), GETDATE(), 112) + N''_'' + 
               REPLACE(CONVERT(NVARCHAR(8), GETDATE(), 108), N'':'', N'''');

SET @NombreArchivo = N''C:\bami\backups\BAMI_Log_'' + @FechaId + N''.trn'';

BACKUP LOG BAMI 
TO DISK = @NombreArchivo
WITH NOINIT, CHECKSUM, STATS = 10;', 
    @database_name = N'master';

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

-- 4. CONFIGURACIÓN DE LA PROGRAMACIÓN (Usando la variable @MyJobId)
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule 
    @job_id = @MyJobId, 
    @name = N'Frecuencia_Por_Horas_BAMI', 
    @enabled = 1, 
    @freq_type = 4,          
    @freq_interval = 1,      
    @freq_subday_type = 8,   
    @freq_subday_interval = 1, 
    @active_start_date = 20260101, 
    @active_end_date = 99991231, 
    @active_start_time = 60000,  
    @active_end_time = 220000;   

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

-- 5. ASIGNACIÓN AL SERVIDOR LOCAL
EXEC msdb.dbo.sp_add_jobserver 
    @job_id = @MyJobId, 
    @server_name = N'(local)';

QuitWithRollback:
GO






-- ***** Job de Mantenimiento Preventivo de Índices y Estadísticas

USE msdb;
GO

-- 1. LIMPIEZA: Si el Job ya existe, se elimina
IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = N'BAMI_Mantenimiento_Indices')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = N'BAMI_Mantenimiento_Indices', @delete_unused_schedule = 1;
END
GO

-- 2. CREACIÓN DEL JOB Y CAPTURA DEL ID EN VARIABLE
DECLARE @ReturnCode INT = 0;
DECLARE @MyJobId BINARY(16);

EXEC @ReturnCode = msdb.dbo.sp_add_job 
    @job_name = N'BAMI_Mantenimiento_Indices', 
    @enabled = 1, 
    @description = N'Job automatizado diario para la desfragmentación de índices de BAMI.', 
    @category_name = N'[Uncategorized (Local)]', 
    @owner_login_name = N'sa',
    @job_id = @MyJobId OUTPUT; -- Guardamos el ID generado aquí

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

-- 3. CREACIÓN DEL PASO 1 (Usando la variable @MyJobId)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
    @job_id = @MyJobId, 
    @step_name = N'Reorganizar Indices y Estadisticas', 
    @step_id = 1, 
    @cmdexec_success_code = 0, 
    @on_success_action = 1, 
    @on_fail_action = 2, 
    @retry_attempts = 1, 
    @retry_interval = 5, 
    @os_run_priority = 0, 
    @subsystem = N'TSQL', 
    @command = N'
ALTER INDEX ALL ON dbo.RutaDetalle REORGANIZE;
ALTER INDEX ALL ON dbo.DonacionDetalle REORGANIZE;
UPDATE STATISTICS dbo.RutaDetalle;
UPDATE STATISTICS dbo.DonacionDetalle;', 
    @database_name = N'BAMI';

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

-- 4. CONFIGURACIÓN DE LA PROGRAMACIÓN (Usando la variable @MyJobId)
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule 
    @job_id = @MyJobId, 
    @name = N'Horario_Nocturno_BAMI', 
    @enabled = 1, 
    @freq_type = 4,          
    @freq_interval = 1,      
    @freq_subday_type = 1,   
    @freq_subday_interval = 0, 
    @active_start_date = 20260101, 
    @active_end_date = 99991231, 
    @active_start_time = 20000; 

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

-- 5. ASIGNACIÓN AL SERVIDOR LOCAL
EXEC msdb.dbo.sp_add_jobserver 
    @job_id = @MyJobId, 
    @server_name = N'(local)';

QuitWithRollback:
GO







-- 3. Monitoreo proactivo.

--- ***** Vista Administrativa de Concurrencia y Bloqueos
USE BAMI;
GO

CREATE VIEW dbo.vw_AlertaBloqueosActivos AS
SELECT 
    blocking_session_id AS Sesion_Bloqueadora_ID,
    session_id AS Sesion_Bloqueada_ID,
    wait_time AS Tiempo_Espera_MS,
    wait_type AS Tipo_Espera_SGBD,
    (SELECT text FROM sys.dm_exec_sql_text(sql_handle)) AS Query_Trabado
FROM sys.dm_exec_requests
WHERE blocking_session_id <> 0; -- Filtra únicamente procesos en estado de bloqueo activo
GO


--- ***** Tabla de Historial de Salud (Log_Rendimiento_BAMI)
USE BAMI;
GO

CREATE TABLE dbo.Log_Rendimiento_BAMI (
    id_log INT IDENTITY(1,1) NOT NULL,
    fecha_registro DATETIME2(0) NOT NULL CONSTRAINT DF_LogRendimiento_Fecha DEFAULT (SYSDATETIME()),
    sesiones_activas_bloqueadas INT NOT NULL,
    descripcion_alerta NVARCHAR(500) NULL,
    
    CONSTRAINT PK_Log_Rendimiento_BAMI PRIMARY KEY (id_log)
);
GO