-- When was SQL Server installed   
SELECT 
	[Poll Time]=getdate(), [Server Name]=@@ServerName,
	createdate AS [SQL Server Install Date] 
FROM sys.syslogins 
WHERE [sid] = 0x010100000000000512000000;

-- Tells you the date and time that SQL Server was installed
-- It is a good idea to know how old your instance is
