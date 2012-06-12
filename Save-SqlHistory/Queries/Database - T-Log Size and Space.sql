-- Get transaction log size and space information for the current database  (Query 34)
SELECT @@ServerName as [Server Name], getdate() as [Poll Date],
DB_NAME(database_id) AS [Database Name], database_id,
CAST((total_log_size_in_bytes/1048576.0) AS DECIMAL(10,1)) AS [Total_log_size(MB)],
CAST((used_log_space_in_bytes/1048576.0) AS DECIMAL(10,1)) AS [Used_log_space(MB)],
CAST(used_log_space_in_percent AS DECIMAL(10,1)) AS [Used_log_space(%)]
FROM sys.dm_db_log_space_usage WITH (NOLOCK) OPTION (RECOMPILE);

-- Another way to look at log file size and space
