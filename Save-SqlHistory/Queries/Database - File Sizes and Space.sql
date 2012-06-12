-- Individual File Sizes and space available for current database  (Query 33)
SELECT @@ServerName as [Server Name], getdate() as [Poll Date],
DB_NAME() AS [Database Name],
name AS [File Name] , physical_name AS [Physical Name], size/128.0 AS [Total Size in MB],
size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 AS [Available Space In MB], [file_id]
FROM sys.database_files WITH (NOLOCK) OPTION (RECOMPILE);

-- Look at how large and how full the files are and where they are located
-- Make sure the transaction log is not full!!