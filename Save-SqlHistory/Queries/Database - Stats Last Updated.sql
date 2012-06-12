-- When were Statistics last updated on all indexes?  (Query 51)
SELECT @@ServerName as [Server Name], getdate() as [Poll Date],
DB_NAME() AS [Database Name],
o.name, i.name AS [Index Name],  
      STATS_DATE(i.[object_id], i.index_id) AS [Statistics Date], 
      s.auto_created, s.no_recompute, s.user_created, st.row_count
FROM sys.objects AS o WITH (NOLOCK)
INNER JOIN sys.indexes AS i WITH (NOLOCK)
ON o.[object_id] = i.[object_id]
INNER JOIN sys.stats AS s WITH (NOLOCK)
ON i.[object_id] = s.[object_id] 
AND i.index_id = s.stats_id
INNER JOIN sys.dm_db_partition_stats AS st WITH (NOLOCK)
ON o.[object_id] = st.[object_id]
AND i.[index_id] = st.[index_id]
WHERE o.[type] = 'U'
ORDER BY STATS_DATE(i.[object_id], i.index_id) ASC OPTION (RECOMPILE);  

-- Helps discover possible problems with out-of-date statistics
-- Also gives you an idea which indexes are most active
