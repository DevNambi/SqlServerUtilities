-- Windows information (SQL Server 2008 R2 SP1 or greater)
SELECT 
	[Poll Time]=getdate(), [Server Name]=@@ServerName,
		windows_release, windows_service_pack_level, 
       windows_sku, os_language_version
FROM sys.dm_os_windows_info OPTION (RECOMPILE);

-- Gives you major OS version, Service Pack, Edition, and language info for the operating system
