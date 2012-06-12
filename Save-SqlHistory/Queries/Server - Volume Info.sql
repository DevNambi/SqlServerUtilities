-- Volume info for all databases on the current instance (SQL Server 2008 R2 SP1 or greater)  (Query 16)
SELECT @@ServerName as [Server Name], getdate() as [Poll Date],
DB_NAME(f.database_id) AS [DatabaseName], f.file_id, 
vs.volume_mount_point, vs.total_bytes, vs.available_bytes, 
CAST(CAST(vs.available_bytes AS FLOAT)/ CAST(vs.total_bytes AS FLOAT) AS DECIMAL(18,3)) * 100 AS [Space Free %]
FROM sys.master_files AS f
CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.file_id) AS vs
ORDER BY f.database_id OPTION (RECOMPILE);

--Shows you the free space on the LUNs where you have database data or log files
