-- Get configuration values for instance
SELECT
	[Poll Time]=getdate(), [Server Name]=@@ServerName,
	name, value, value_in_use, [description] 
FROM sys.configurations
ORDER BY name OPTION (RECOMPILE);

-- Focus on
-- backup compression default
-- clr enabled (only enable if it is needed)
-- lightweight pooling (should be zero)
-- max degree of parallelism (depends on your workload)
-- max server memory (MB) (set to an appropriate value)
-- optimize for ad hoc workloads (should be 1)
-- priority boost (should be zero)
