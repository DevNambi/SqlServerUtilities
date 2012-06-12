--- Index Read/Write stats (all tables in current DB) ordered by Reads
SELECT [Poll Time]=getdate(), [Server Name]=@@ServerName,
OBJECT_NAME(s.[object_id]) AS [ObjectName], i.name AS [IndexName], i.index_id,
	   user_seeks + user_scans + user_lookups AS [Reads], s.user_updates AS [Writes],  
	   i.type_desc AS [IndexType], i.fill_factor AS [FillFactor]
FROM sys.dm_db_index_usage_stats AS s WITH (NOLOCK)
INNER JOIN sys.indexes AS i WITH (NOLOCK)
ON s.[object_id] = i.[object_id]
WHERE OBJECTPROPERTY(s.[object_id],'IsUserTable') = 1
AND i.index_id = s.index_id
AND s.database_id = DB_ID()
ORDER BY user_seeks + user_scans + user_lookups DESC OPTION (RECOMPILE); -- Order by reads

-- Show which indexes in the current database are most active for Reads
