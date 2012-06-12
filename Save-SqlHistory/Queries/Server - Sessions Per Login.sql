--  Get logins that are connected and how many sessions they have (Query 23)
SELECT 
@@ServerName as [Server Name], getdate() as [Poll Date],
login_name, COUNT(session_id) AS [session_count] 
FROM sys.dm_exec_sessions WITH (NOLOCK)
GROUP BY login_name
ORDER BY COUNT(session_id) DESC OPTION (RECOMPILE);

-- This can help characterize your workload and
-- determine whether you are seeing a normal level of activity
