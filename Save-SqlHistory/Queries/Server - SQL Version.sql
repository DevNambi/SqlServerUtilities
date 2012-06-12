-- SQL and OS Version information for current instance  (Query 1)
SELECT @@ServerName as [Server Name], getdate() as [Poll Date], @@VERSION AS [SQL Server and OS Version Info];

-- SQL Server 2012 RTM Branch Builds
-- Build			Description
-- 11.00.1055		CTP0
-- 11.00.1103		CTP1
-- 11.00.1440		CTP3
-- 11.00.1515		CTP3 plus Test Update
-- 11.00.1750		RC0
-- 11.00.1913		RC1
-- 11.00.2300		RTM
-- 11.00.2316		RTM CU1

-- The SQL Server 2012 builds that were released after SQL Server 2012 was released
-- http://support.microsoft.com/kb/2692828