-- https://msdn.microsoft.com/library/dn449496.aspx

-- 1) Criando a credencial
CREATE CREDENTIAL [https://nomedasuastorageaccount.blob.core.windows.net/nomedoseucontainer]   
WITH IDENTITY = 'Shared Access Signature',  
SECRET = 'sv=2015-04-05&sr=c&sig=S8zschnfCmc8lV47xov%2FkAAgNDZbcYscnlGmrNid5Ig%3D&se=2018-05-03T23%3A52%3A26Z&sp=rwdl';

-- 2) Definindo o Recovery Model
USE [master]
GO
ALTER DATABASE [dbTeste] SET RECOVERY FULL WITH NO_WAIT;
GO

-- 3) Configurando a retenção e o destino para os backups
USE msdb;  
GO  
EXEC msdb.managed_backup.sp_backup_config_basic   
 @enable_backup = 1, @database_name = 'dbTeste', 
 @container_url = 'https://nomedasuastorageaccount.blob.core.windows.net/nomedoseucontainer', @retention_days = 30  
GO

-- 4) Configurando o agendamento dos backups
EXEC managed_backup.sp_backup_config_schedule   
     @database_name = 'dbTeste'  
    ,@scheduling_option = 'Custom'  
    ,@full_backup_freq_type = 'Daily'
    ,@backup_begin_time =  '21:05'  
    ,@backup_duration = '01:00'  
    ,@log_backup_freq = '00:10'  
GO

--USE msdb;  
--GO  
--EXEC managed_backup.sp_backup_config_schedule   
--     @database_name =  'MyDB'  
--    ,@scheduling_option = 'Custom'  
--    ,@full_backup_freq_type = 'Weekly'  
--    ,@days_of_week = 'Monday'  
--    ,@backup_begin_time =  '17:30'  
--    ,@backup_duration = '02:00'  
--    ,@log_backup_freq = '00:05'  
--GO  

-- 5) Validando as configurações do backup do banco de dados
SELECT * FROM managed_backup.fn_backup_db_config ('dbTeste') b;

-- 6) Simulando a perda de dados
USE dbTeste;
GO
SELECT count(*) qtd from tblVendas;
GO
TRUNCATE TABLE tblVendas;
GO
SELECT count(*) qtd from tblVendas;
GO

-- 7) Restaurando o banco de dados a partir do Azure
USE [master]
ALTER DATABASE [dbTeste] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE DATABASE [dbTeste] 
	FROM  URL = N'https://nomedasuastorageaccount.blob.core.windows.net/nomedoseucontainer/dbTeste_1e0ddb115dc248cdba2f3931a0218c03_20170503210735-03.bak' 
	WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,  REPLACE,  STATS = 20;
RESTORE LOG [dbTeste] 
	FROM  URL = N'https://nomedasuastorageaccount.blob.core.windows.net/nomedoseucontainer/dbTeste_1e0ddb115dc248cdba2f3931a0218c03_20170503211245-03.log' 
	WITH  FILE = 1,  RECOVERY,  NOUNLOAD,  STATS = 20;
--RESTORE LOG [dbTeste] 
--	FROM  URL = N'https://nomedasuastorageaccount.blob.core.windows.net/nomedoseucontainer/dbTeste_1e0ddb115dc248cdba2f3931a0218c03_20170503212305-03.log' 
--	WITH  FILE = 1,  NOUNLOAD,  STATS = 20;
ALTER DATABASE [dbTeste] SET MULTI_USER;
GO

-- 8) Validando Restore
USE dbTeste;
GO
SELECT count(*) qtd from tblVendas;
GO

-- 9) Desabilitando programação automática
EXEC msdb.managed_backup.sp_backup_config_basic @database_name = 'dbTeste', @enable_backup = 0;  
GO 

-- ==========================================================================================================
-- Querys de gerenciamento 
-- ==========================================================================================================
-- Visualizar os eventos administrativos
Use msdb;  
Go  
DECLARE @startofweek datetime, @endofweek datetime;
SET @startofweek = DATEADD(Day, 1-DATEPART(WEEKDAY, CURRENT_TIMESTAMP), CURRENT_TIMESTAMP);
SET @endofweek = DATEADD(Day, 7-DATEPART(WEEKDAY, CURRENT_TIMESTAMP), CURRENT_TIMESTAMP);

DECLARE @eventresult TABLE (event_type nvarchar(512), event nvarchar (512), timestamp datetime)  
INSERT INTO @eventresult  
EXEC managed_backup.sp_get_backup_diagnostics @begin_time = @startofweek, @end_time = @endofweek  
SELECT * from @eventresult WHERE event_type LIKE '%admin%';
GO

-- Visualizar eventos da semana corrente 
Use msdb;  
Go  
DECLARE @startofweek datetime  
DECLARE @endofweek datetime  
SET @startofweek = DATEADD(Day, 1-DATEPART(WEEKDAY, CURRENT_TIMESTAMP), CURRENT_TIMESTAMP)   
SET @endofweek = DATEADD(Day, 7-DATEPART(WEEKDAY, CURRENT_TIMESTAMP), CURRENT_TIMESTAMP)  
EXEC managed_backup.sp_get_backup_diagnostics @begin_time = @startofweek, @end_time = @endofweek;

-- Recupera os backups disponíveis para um banco de dados especificado 
SELECT * FROM msdb.managed_backup.fn_available_backups('dbTeste')