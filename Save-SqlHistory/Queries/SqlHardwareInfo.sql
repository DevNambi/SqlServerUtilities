-- Hardware information from SQL Server 2008 and 2008 R2
-- (Cannot distinguish between HT and multi-core)
SELECT 
	[Poll Time]=getdate(), [Server Name]=@@ServerName,
	cpu_count AS [Logical CPU Count], hyperthread_ratio AS [Hyperthread Ratio],
cpu_count/hyperthread_ratio AS [Physical CPU Count], 
physical_memory_in_bytes/1048576 AS [Physical Memory (MB)], 
sqlserver_start_time --, affinity_type_desc -- (affinity_type_desc is only in 2008 R2)
FROM sys.dm_os_sys_info OPTION (RECOMPILE);

-- Gives you some good basic hardware information about your database server
