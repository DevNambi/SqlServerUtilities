-- Get information about your cluster nodes and their status  (Query 11) 
-- (if your database server is in a cluster)
SELECT @@ServerName as [Server Name], getdate() as [Poll Date], 
    NodeName, status_description, is_current_owner
FROM sys.dm_os_cluster_nodes WITH (NOLOCK) OPTION (RECOMPILE);

-- Knowing which node owns the cluster resources is critical
-- Especially when you are installing Windows or SQL Server updates
-- You will see no results if your instance is not clustered
