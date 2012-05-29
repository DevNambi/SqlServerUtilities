/* 
Author: Dev Nambi
Website: www.devnambi.com 
Version: 1.0
You are welcome to use this script for any of your own purposes, but please
do not publish it as your own work. See the website for full copyright details 
(Creative Commons).
*/
declare @Cmd nvarchar(max)
	,@Msg nvarchar(512)
	,@TableName nvarchar(256)
	,@ColumnName nvarchar(128)
	
declare statsCursor cursor local read_only
for
	select
		'['+sch.name+'].['+object_name(c.object_id)+']' as TableName
		,c.name as ColumnName
		--,s.*
	from sys.columns c
	inner join sys.objects o
	on c.object_id=o.object_id
	and 
	(
	o.type = 'U' 
	or (o.type = 'V' and objectproperty(o.object_id,'IsIndexed')=1)
	)
	inner join sys.schemas sch
	on sch.schema_id=o.schema_id
	left outer join
	(
		select
			s.object_id
			,s.name
			,s.stats_id
			,s.auto_created
			,s.user_created
			,s.no_recompute
			,sc.stats_column_id
			,sc.column_id
		from sys.stats s
		inner join sys.stats_columns sc
		on s.object_id=sc.object_id
		and s.stats_id=sc.stats_id
		where sc.stats_column_id =1 --only look at stats where the statistic is on the first column
	) s
	on c.object_id=s.object_id
	and c.column_id=s.column_id
	where s.stats_id is null --only find columns where there are no stats
	and c.user_type_id not in (241) -- ignore XML columns

	
open statsCursor

fetch next from statsCursor into @TableName,@ColumnName

while @@fetch_status=0
begin
	begin
	
	set @Cmd='create statistics CustomStat_'+@ColumnName+' on '+@TableName + '('+@ColumnName+')'
	set @Msg='-- creating stats on '+@TableName+'('+@ColumnName+')'

	print @Msg
	print @Cmd
	exec (@Cmd)
	
	end
	fetch next from statsCursor into @TableName,@ColumnName
end

close statsCursor
deallocate statsCursor