/* 
Cost threshold for parallelism
Optimize for adhoc
min server mem
max server mem
min memory per query
cross db ownership
Ad-hoc distributed
Backup comp default
Database mail xps

*/

declare @ServerConfigXML xml
set @ServerConfigXML=N'
<server-config name="">
	<setting 
		name="cost threshold for parallelism" 
		value="10" 
		description="" />
	<setting 
		name="min server memory" 
		value="" 
		description="" />
	<setting 
		name="max server memory" 
		value="" 
		description="" />
	<setting 
		name="min memory per query" 
		value="" 
		description="" />
	<setting 
		name="optimize for ad-hoc workloads" 
		value="0" 
		description="1=turn on ad-hoc workload optimization, 0=turn off adhoc workload optimization. See [] for details" />
	<setting 
		name="cross db ownership chaining" 
		value="0" 
		description="" />
	<setting 
		name="ad-hoc distributed queries" 
		value="0" 
		description="" />
	<setting 
		name="backup compression default" 
		value="1" 
		description="" />
	<setting 
		name="Database Mail XPs" 
		value="1" 
		description="" />
</server-config>
'

exec Setup.ConfigServer
	@Mode='' --audit, apply, test apply
	,@ConfigXML=@ServerConfigXML