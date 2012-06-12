-- Find single-use, ad-hoc queries that are bloating the plan cache  (Query 32)
SELECT TOP(20) 
    @@ServerName as [Server Name], getdate() as [Poll Date],
    [text] AS [QueryText], cp.size_in_bytes
FROM sys.dm_exec_cached_plans AS cp WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(plan_handle) 
WHERE cp.cacheobjtype = N'Compiled Plan' 
AND cp.objtype = N'Adhoc' 
AND cp.usecounts = 1
ORDER BY cp.size_in_bytes DESC OPTION (RECOMPILE);

-- Gives you the text and size of single-use ad-hoc queries that waste space in the plan cache
-- Enabling 'optimize for ad hoc workloads' for the instance can help (SQL Server 2008 and above only)
-- Enabling forced parameterization for the database can help, but test first!
