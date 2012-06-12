-- Get information about your OS cluster (if your database server is in a cluster)  (Query 10)
SELECT @@ServerName as [Server Name], getdate() as [Poll Date],
       VerboseLogging, SqlDumperDumpFlags, SqlDumperDumpPath, 
       SqlDumperDumpTimeOut, FailureConditionLevel, HealthCheckTimeout
FROM sys.dm_os_cluster_properties WITH (NOLOCK) OPTION (RECOMPILE);

-- You will see no results if your instance is not clustered
