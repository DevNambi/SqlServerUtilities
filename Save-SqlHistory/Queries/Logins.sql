--  Get logins that are connected and how many sessions they have 
SELECT [Poll Time]=getdate(), [Server Name]=@@ServerName,
login_name, COUNT(session_id) AS [session_count] 
FROM sys.dm_exec_sessions WITH (NOLOCK)
WHERE session_id > 50	-- filter out system SPIDs
GROUP BY login_name
ORDER BY COUNT(session_id) DESC OPTION (RECOMPILE);

-- This can help characterize your workload and
-- determine whether you are seeing a normal level of activity
