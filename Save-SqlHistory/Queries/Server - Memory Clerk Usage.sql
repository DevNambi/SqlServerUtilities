-- Memory Clerk Usage for instance  (Query 31)
-- Look for high value for CACHESTORE_SQLCP (Ad-hoc query plans)
SELECT TOP(10) @@ServerName as [Server Name], getdate() as [Poll Date],
       [type] AS [Memory Clerk Type], 
       SUM(pages_kb) AS [SPA Mem, Kb] 
FROM sys.dm_os_memory_clerks WITH (NOLOCK)
GROUP BY [type]  
ORDER BY SUM(pages_kb) DESC OPTION (RECOMPILE);

-- CACHESTORE_SQLCP  SQL Plans         
-- These are cached SQL statements or batches that 
-- aren't in stored procedures, functions and triggers
--
-- CACHESTORE_OBJCP  Object Plans      
-- These are compiled plans for 
-- stored procedures, functions and triggers
--
-- CACHESTORE_PHDR   Algebrizer Trees  
-- An algebrizer tree is the parsed SQL text 
-- that resolves the table and column names
