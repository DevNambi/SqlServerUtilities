-- Get information on location, time and size of any memory dumps from SQL Server  (Query 15)
SELECT @@ServerName as [Server Name], getdate() as [Poll Date],
[filename], creation_time, size_in_bytes
FROM sys.dm_server_memory_dumps WITH (NOLOCK) OPTION (RECOMPILE);

-- This will not return any rows if you have 
-- not had any memory dumps (which is a good thing)
