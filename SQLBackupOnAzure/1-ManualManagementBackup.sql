DROP CREDENTIAL [AzureBackup];
GO
CREATE CREDENTIAL [AzureBackup]
WITH IDENTITY = 'nomedasuastorageaccount', 
SECRET = '<Cole aqui a chave 1 ou 2 da Storage Account>' 
-- '<Access keys da storage account>'
-- Copiar a Primary Key ou Secondary Key da Storage Container;
GO

BACKUP DATABASE [AdventureWorks2016CTP3] 
	TO  URL = 'https://nomedasuastorageaccount.blob.core.windows.net/producao/AdventureWorks.bak' WITH  COPY_ONLY, 
	NOFORMAT, INIT,  NAME = N'AdventureWorks2016CTP3-Full Database Backup', NOSKIP, NOREWIND, NOUNLOAD, 
	COMPRESSION,  STATS = 10,
	CREDENTIAL = N'AzureBackup'
GO

-- Demonstrar o Plano de Manutenção com Backups para a Nuvem;

-- ***********************************************************************************
-- DEMONSTRAÇÃO - DB TESTE
USE master
DECLARE @backup_name varchar(100), @URL varchar(200);
SET @URL = 'https://nomedasuastorageaccount.blob.core.windows.net/producao/'
SET @backup_name = @URL + 'dbTeste' + FORMAT(GETDATE(), 'dd-mm-yyy-hh-mm-ss') + '.bak';
SELECT @backup_name;
BACKUP DATABASE [dbTeste] 
	TO  URL = @backup_name WITH 
	NOFORMAT, NOINIT,  NAME = N'dbTeste-Full Database Backup', NOSKIP, NOREWIND, NOUNLOAD, 
	COMPRESSION,  STATS = 10,
	CREDENTIAL = N'AzureBackup'
GO
-- https://nomedasuastorageaccount.blob.core.windows.net/producao/dbTeste20-04-2017-02-04-59.bak

USE dbTeste
GO
SELECT COUNT(*) FROM dbo.tblVendas; -- 8.388.608
GO
--Horário Inicio: 14:05
DELETE TOP (388608) FROM dbo.tblVendas;
GO
SELECT COUNT(*) FROM dbo.tblVendas; -- 8000000
GO

--Horário Inicio: 14:06
DELETE TOP (50000) FROM dbo.tblVendas;
GO
SELECT COUNT(*) FROM dbo.tblVendas; -- 7995000
GO

USE master
DECLARE @backup_name varchar(100), @URL varchar(200);
SET @URL = 'https://nomedasuastorageaccount.blob.core.windows.net/producao/'
SET @backup_name = @URL + 'dbTeste' + FORMAT(GETDATE(), 'dd-mm-yyy-hh-mm-ss') + '.trn';
SELECT @backup_name;
BACKUP LOG [dbTeste] 
	TO  URL = @backup_name WITH 
	NOFORMAT, NOINIT,  NAME = N'dbTeste-Log Database Backup', NOSKIP, NOREWIND, NOUNLOAD, 
	COMPRESSION,  STATS = 10,
	CREDENTIAL = N'AzureBackup'
GO
-- https://nomedasuastorageaccount.blob.core.windows.net/producao/dbTeste20-07-2017-02-07-57.trn

USE [master]
RESTORE DATABASE [dbTeste] 
	FROM  URL = N'https://nomedasuastorageaccount.blob.core.windows.net/producao/dbTeste20-04-2017-02-04-59.bak' WITH  FILE = 1,  
	NORECOVERY,  NOUNLOAD,  STATS = 50, REPLACE,
	CREDENTIAL = N'AzureBackup'
RESTORE LOG [dbTeste] FROM  URL = N'https://nomedasuastorageaccount.blob.core.windows.net/producao/dbTeste20-07-2017-02-07-57.trn' WITH  FILE = 1,  
	NOUNLOAD,  STATS = 50,  STOPAT = N'2017-04-20T14:06:50', REPLACE,
	CREDENTIAL = N'AzureBackup'
GO
-- Conferência dos registros (Restore Point-in-time)
SELECT COUNT(*) FROM [dbTeste].dbo.tblVendas; -- 8000000
GO

USE [master]
RESTORE DATABASE [dbTeste] 
	FROM  URL = N'https://nomedasuastorageaccount.blob.core.windows.net/producao/dbTeste20-04-2017-02-04-59.bak' WITH  FILE = 1,  
	RECOVERY,  NOUNLOAD,  STATS = 50, REPLACE,
	CREDENTIAL = N'AzureBackup';

-- Conferência dos registros (Restore Full)
SELECT COUNT(*) FROM [dbTeste].dbo.tblVendas; -- 8000000
GO

--Demonstrar o Plano de Manutenção



