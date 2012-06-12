-- SQL Server Registry information  (Query 14) 
SELECT @@ServerName as [Server Name], getdate() as [Poll Date],
registry_key, value_name, value_data
FROM sys.dm_server_registry WITH (NOLOCK) OPTION (RECOMPILE);

-- This lets you safely read some SQL Server related 
-- information from the Windows Registry
