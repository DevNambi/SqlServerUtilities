
-- Shows you where the SQL Server error log is located and how it is configured  (Query 9)
SELECT @@ServerName as [Server Name], getdate() as [Poll Date],
is_enabled, [path], max_size, max_files
FROM sys.dm_os_server_diagnostics_log_configurations WITH (NOLOCK) OPTION (RECOMPILE);

-- Knowing this information is important for troubleshooting purposes