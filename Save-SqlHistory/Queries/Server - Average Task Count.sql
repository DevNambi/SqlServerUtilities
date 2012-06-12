-- Get Average Task Counts (run multiple times)  (Query 24)
SELECT @@ServerName as [Server Name], getdate() as [Poll Date],
AVG(current_tasks_count) AS [Avg Task Count], 
AVG(runnable_tasks_count) AS [Avg Runnable Task Count],
AVG(pending_disk_io_count) AS [Avg Pending DiskIO Count]
FROM sys.dm_os_schedulers WITH (NOLOCK)
WHERE scheduler_id < 255 OPTION (RECOMPILE);

-- Sustained values above 10 suggest further investigation in that area
-- High Avg Task Counts are often caused by blocking or other resource contention
-- High Avg Runnable Task Counts are a good sign of CPU pressure
-- High Avg Pending DiskIO Counts are a sign of disk pressure
