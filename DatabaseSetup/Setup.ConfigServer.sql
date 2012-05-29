
declare 
	@Mode varchar(12)='' --audit, apply, test apply
	,@ConfigXML xml
	
	set @Mode='audit '
	set @ConfigXML=N'<server-config name="">
	<setting 
		name="cost threshold for parallelism" 
		value="5" 
		description="" />
	<setting 
		name="min server memory (MB)" 
		value="10" 
		description="" />
	<setting 
		name="max server memory (MB)" 
		value="1024" 
		description="" />
	<setting 
		name="min memory per query (KB)" 
		value="768" 
		description="" />
	<setting 
		name="optimize for ad hoc workloads" 
		value="1" 
		description="1=turn on ad hoc workload optimization, 0=turn off adhoc workload optimization. See [] for details" />
	<setting 
		name="cross db ownership chaining" 
		value="0" 
		description="" />
	<setting 
		name="ad hoc distributed queries" 
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
</server-config>'

	set nocount on;

	declare @Message nvarchar(max)
		,@MessageXML xml
	/* 
	First, input validation
	Second, get the existing configuration
	Third, compare the input to existing.
	Fourth, do whatever the mode says
		If audit, print what matches and what doesn't
		If test apply, print the commands
		If apply, execute the commands
	*/
	
	-- first, do an input validation
	if @Mode not in
	('audit'
	,'apply'
	,'test apply')
	begin
		set @Message='Invalid @mode passed in: '
			+@Mode+'. Only audit, apply, and test apply modes are supported'
		raiserror(@Message, 16,1);
	end
	
	declare @SupportedConfigSettings xml
		
	set @SupportedConfigSettings=N'
	<supported-config>
		<setting name="cost threshold for parallelism" is-advanced-option="1" />
		<setting name="min server memory (MB)" is-advanced-option="1" />
		<setting name="max server memory (MB)" is-advanced-option="1" />
		<setting name="min memory per query (KB)" is-advanced-option="1" />
		<setting name="optimize for ad hoc workloads" is-advanced-option="1" />
		<setting name="cross db ownership chaining" />
		<setting name="ad hoc distributed queries" is-advanced-option="1" />
		<setting name="backup compression default" />
		<setting name="Database Mail XPs" is-advanced-option="1" />
	</supported-config>'
	
	set @MessageXML=
	(
	select
		'Unsupported config setting: '
			+n.i.value('@name','nvarchar(128)')
			+', '
	from @ConfigXML.nodes('server-config/setting') n(i)
	left outer join @SupportedConfigSettings.nodes('supported-config/setting') s(i)
	on s.i.value('@name','nvarchar(128)')=n.i.value('@name','nvarchar(128)')
	where s.i.value('@name','nvarchar(128)') is null
	for xml path ('')
	)
	if len(convert(nvarchar(max),@MessageXML))>2
	begin
		set @Message=convert(nvarchar(4000),@MessageXML)
		raiserror(@Message,16,1);
	end
	
	-- first, retrieve all configuration settings
	declare @ConfigChanges table
	(SettingName nvarchar(128) not null
	,OldValue bigint null
	,NewValue bigint not null
	,MaxSupportedValue bigint null
	,MinSupportedValue bigint null)
	
	insert into @ConfigChanges
	(SettingName
	,NewValue)
	select
		n.i.value('@name','nvarchar(128)')
		,n.i.value('@value','bigint')
	from @ConfigXML.nodes('server-config/setting') n(i)
		
	-- second, check on the existing configuration
	declare @configvalues table
	(name nvarchar(128)
	,minimum bigint
	,maximum bigint
	,config_value bigint
	,run_value bigint)

	insert into @configvalues
	exec sp_configure

	update cc
	set OldValue=cv.run_value
	,MaxSupportedValue=cv.maximum
	,MinSupportedValue=cv.minimum
	from @ConfigChanges cc
	inner join @configvalues cv
	on cc.SettingName=cv.name
	
	if @Mode in ('audit','apply','test apply')
	begin
		select
			SettingName
			,OldValue
			,NewValue
			,ActionDescription=case when OldValue=NewValue 
					then 'No change, staying at '
					+CONVERT(nvarchar,OldValue)
				when NewValue between MinSupportedValue and MaxSupportedValue
					then  'Changing from '
					+CONVERT(nvarchar,OldValue)
					+' to ' 
					+CONVERT(nvarchar,NewValue)
				else 'Cannot change value because new value ('
					+CONVERT(nvarchar,NewValue)
					+') is not between supported values of '
					+CONVERT(nvarchar,MinSupportedValue)
					+' and '
					+CONVERT(nvarchar,MaxSupportedValue)
				end
		from @ConfigChanges
		
		set @MessageXML=(
			select
				'Setting: '
				+SettingName
				+' - '
				+case when OldValue=NewValue 
						then 'not changing, staying at '
						+CONVERT(nvarchar,OldValue)
					when NewValue between MinSupportedValue and MaxSupportedValue
						then  'changing from '
						+CONVERT(nvarchar,OldValue)
						+' to ' 
						+CONVERT(nvarchar,NewValue)
					else ' cannot change value because new value ('
						+CONVERT(nvarchar,NewValue)
						+') is not between supported values of '
						+CONVERT(nvarchar,MinSupportedValue)
						+' and '
						+CONVERT(nvarchar,MaxSupportedValue)
					end
					+NCHAR(10) --line break
			from @ConfigChanges
			order by 
				case when OldValue=NewValue then 3
				when NewValue between MinSupportedValue and MaxSupportedValue then 2
				else 1 end
				asc
				,SettingName
			FOR xml path ('')
		)
		set @Message=CONVERT(nvarchar(max),@MessageXML)
		print @Message --this only supports 4K characters, and right now it is printing 617-700
	end
	
	-- third, create the list of commands to run
	if @Mode in ('test apply')
	begin
		set @MessageXML=
		(
		select 'exec sp_configure '''
			+SettingName
			+N''', '
			+CONVERT(nvarchar,NewValue)
			+NCHAR(10)
			+'go'
			+NCHAR(10)
			+'reconfigure'
			+NCHAR(10)
			+'go'
			+nchar(10)
		from @ConfigChanges
		where NewValue<>OldValue
		and NewValue between MinSupportedValue and MaxSupportedValue
		for xml path ('')
		)
		set @Message=CONVERT(Nvarchar(max),@MessageXML)
		
		print N'-- test apply settings'
			print @Message
	end
	
	if @Mode in ('apply')
	begin
		set @MessageXML=
		(
		select 'exec sp_configure '''
			+SettingName
			+N''', '
			+CONVERT(nvarchar,NewValue)
			+';'
			+NCHAR(10)
		from @ConfigChanges
		where NewValue<>OldValue
		and NewValue between MinSupportedValue and MaxSupportedValue
		for xml path ('')
		)
		set @Message=CONVERT(Nvarchar(max),@MessageXML)
		
		exec (@Message)
		exec ('RECONFIGURE') --run reconfigure to apply the commands
	end
	
	