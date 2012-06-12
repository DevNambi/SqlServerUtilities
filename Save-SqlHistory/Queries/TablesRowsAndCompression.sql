-- Get Table names, row counts, and compression status for clustered index or heap
SELECT [Poll Time]=getdate(), [Server Name]=@@ServerName,
OBJECT_NAME(object_id) AS [ObjectName], 
SUM(Rows) AS [RowCount], data_compression_desc AS [CompressionType]
FROM sys.partitions WITH (NOLOCK)
WHERE index_id < 2 --ignore the partitions from the non-clustered index if any
AND OBJECT_NAME(object_id) NOT LIKE N'sys%'
AND OBJECT_NAME(object_id) NOT LIKE N'queue_%' 
AND OBJECT_NAME(object_id) NOT LIKE N'filestream_tombstone%' 
AND OBJECT_NAME(object_id) NOT LIKE N'fulltext%'
AND OBJECT_NAME(object_id) NOT LIKE N'ifts_comp_fragment%'
GROUP BY object_id, data_compression_desc
ORDER BY SUM(Rows) DESC OPTION (RECOMPILE);

-- Gives you an idea of table sizes, and possible data compression opportunities
