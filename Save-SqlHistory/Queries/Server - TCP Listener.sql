-- Get information about TCP Listener for SQL Server  (Query 13)
SELECT @@ServerName as [Server Name], getdate() as [Poll Date],
listener_id, ip_address, is_ipv4, port, type_desc, state_desc, start_time
FROM sys.dm_tcp_listener_states WITH (NOLOCK) OPTION (RECOMPILE);

-- Helpful for network and connectivity troubleshooting
