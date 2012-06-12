-- Individual File Sizes and space available for current database
SELECT [Poll Time]=getdate(), [Server Name]=@@ServerName,
name AS [File Name], [file_id], physical_name AS [Physical Name], size/128.0 AS [Total Size in MB],
size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 AS [Available Space In MB] 
FROM sys.database_files WITH (NOLOCK) OPTION (RECOMPILE);

-- Look at how large and how full the files are and where they are located
-- Make sure the transaction log is not full!!
