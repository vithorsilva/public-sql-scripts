-- 1) Configurando a retenção e o destino para os backups (todos bds)
USE msdb;  
GO  
EXEC sp_MSforeachdb N'EXEC msdb.managed_backup.sp_backup_config_basic   
 @enable_backup = 1,
 @database_name = ''?'',  
 @container_url = ''https://nomedasuastorageaccount.blob.core.windows.net/nomedoseucontainer'', @retention_days = 25';
 GO
 
 SELECT * FROM managed_backup.fn_backup_instance_config();

-- 2) Configurando o agendamento dos backups (todos bds)
EXEC sp_MSforeachdb N'
EXEC managed_backup.sp_backup_config_schedule   
     @database_name = ''?''
    ,@scheduling_option = ''Custom'' 
    ,@full_backup_freq_type = ''Daily''
    ,@backup_begin_time =  ''22:54'', @backup_duration = ''01:00'', @log_backup_freq = ''00:10'''

-- 3) Validação das Configurações
SELECT * FROM managed_backup.fn_backup_db_config(null);

-- 4) Backups disponíveis
SELECT * FROM msdb.managed_backup.fn_available_backups('master')

-- 5) Desabilitar configuração automática
USE msdb;
EXEC sp_MSforeachdb N'EXEC msdb.managed_backup.sp_backup_config_basic @enable_backup = 0, @database_name = ''?'';'
GO
