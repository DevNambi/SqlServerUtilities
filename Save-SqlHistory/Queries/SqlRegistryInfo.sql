-- SQL Server Registry information 
SELECT 
	[Poll Time]=getdate(), [Server Name]=@@ServerName,
	registry_key, value_name, value_data
FROM sys.dm_server_registry WITH (NOLOCK) OPTION (RECOMPILE);

-- This lets you safely read some SQL Server related 
-- information from the Windows Registry
