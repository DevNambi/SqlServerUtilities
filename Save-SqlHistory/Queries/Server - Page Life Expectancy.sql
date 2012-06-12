-- Page Life Expectancy (PLE) value for current instance  (Query 28)
SELECT @@ServerName as [Server Name], getdate() as [Poll Date],
    [object_name], cntr_value AS [Page Life Expectancy]
FROM sys.dm_os_performance_counters WITH (NOLOCK)
WHERE [object_name] LIKE N'%Buffer Manager%' -- Handles named instances
AND counter_name = N'Page life expectancy' OPTION (RECOMPILE);

-- PLE is a good measurement of memory pressure.
-- Higher PLE is better. Watch the trend, not the absolute value.
