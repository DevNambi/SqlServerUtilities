
-- Windows information (SQL Server 2012)  (Query 4)
SELECT @@ServerName as [Server Name], getdate() as [Poll Date],
       windows_release, windows_service_pack_level, 
       windows_sku, os_language_version
FROM sys.dm_os_windows_info WITH (NOLOCK) OPTION (RECOMPILE);

-- Gives you major OS version, Service Pack, Edition, and language info for the operating system