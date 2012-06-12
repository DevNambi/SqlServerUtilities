-- Memory Grants Outstanding value for current instance
SELECT [Poll Time]=getdate(), [Server Name]=@@ServerName,
[object_name], cntr_value AS [Memory Grants Outstanding]                                                                                                      
FROM sys.dm_os_performance_counters WITH (NOLOCK)
WHERE [object_name] LIKE N'%Memory Manager%' -- Handles named instances
AND counter_name = N'Memory Grants Outstanding' OPTION (RECOMPILE);

-- Memory Grants Outstanding above zero for a sustained period is a very strong indicator of memory pressure
