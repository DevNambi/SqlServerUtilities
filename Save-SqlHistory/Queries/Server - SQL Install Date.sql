-- When was SQL Server installed  (Query 2)   
SELECT @@ServerName as [Server Name], getdate() as [Poll Date], createdate AS [SQL Server Install Date] 
FROM sys.syslogins 
WHERE [sid] = 0x010100000000000512000000;

-- Tells you the date and time that SQL Server was installed
-- It is a good idea to know how old your instance is