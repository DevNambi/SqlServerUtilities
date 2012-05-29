if OBJECT_ID('dbo._TestUpdateStats') is not null
begin
	exec ('drop procedure dbo._TestUpdateStats');
end
go

create procedure dbo._TestUpdateStats
	@RowModCounterThreshold bigint=50000
	,@RowModPercentagethreshold decimal(3,2)=0.05
	,@StatsSamplingPercentage tinyint=0
as
begin
	set nocount on;
	declare 
		@Msg nvarchar(max)
		,@Cmd nvarchar(max)
		,@QualifiedTableName nvarchar(256)
		,@DoUpdateStats bit
		,@Description nvarchar(max)
		,@CurrentRowModCounter bigint
		
	/* 
	User options:
	@RowModCounterThreshold -- if a table gets more than this many rows inserted/updated/deleted, update its statistics
	@RowModPercentageThreshold -- if a table gets more than this percentage of rows inserted/updated/deleted, update its statistics
	@StatsSamplingPercentage:
		--set to 0 to update stats in RESAMPLE mode. 
		--set to null to update statistics in their default configuration
		--set to a value between 1 and 100 to update statistics by scanning that percentage of the table's rows
	*/


	/* First, create the temporary tables we'll be using to query the system DMVs
	Querying them directly in the cursor will not scale in systems with large numbers of tables & indexes
	*/
	if object_id('tempdb..#TableList') is null
	begin
		create table #TableList
		(SchemaName sysname not null
		,TableName sysname not null
		,ObjectID bigint not null
		,EstimatedTableRowcount bigint not null
		,primary key clustered (SchemaName,TableName))
	end
	truncate table #TableLIst

	if object_id('tempdb..#IndexList') is null
	begin
		create table #IndexList
		(SchemaName sysname not null
		,TableName sysname not null
		,IndexName sysname not null
		,IndexRowModCounter bigint not null
		,IndexPercentageOfTable decimal(5,4) not null
		,primary key clustered (SchemaName,TableName,IndexName))
	end
	truncate table #IndexList

	if object_id('tempdb..#StatsList') is null
	begin
		create table #StatsList
		(TableObjectID bigint not null
		,QualifiedTableName nvarchar(256) not null 
		,DoUpdateStats bit not null
		,Description nvarchar(500) --This should be above the maximum description size
		)
		
		create clustered index NonUniquePK on #StatsList (TableObjectID)
	end
	truncate table #StatsList

	-- Get the list of tables & indexed views and their estimated rowcounts
	insert into #TableList
	(SchemaName
	,TableName
	,ObjectID
	,EstimatedTableRowcount)
	select
		s.name as SchemaName
		,t.name as TableName
		,t.object_id as ObjectID
		,sum(p.rows) as EstimatedTableRowcount
	from sys.objects t
	inner join sys.schemas s
	on s.schema_id=t.schema_id
	inner join sys.partitions p
	on t.object_id=p.object_id
	where p.index_id in (0,1) --look at the base table only
	and t.type in ('U','V') --only look at tables and views
	group by s.name
			,t.name
			,t.object_id

	/*
	Get the list of indexes for each table or indexed view, the rowmodcounter for each index,
	and the percentage of the table's rows the index covers (to account for filtered indexes)
	 */
	insert into #IndexList
	(SchemaName
	,TableName
	,IndexName
	,IndexPercentageOfTable
	,IndexRowModCounter)
	select
		s.name as SchemaName
		,t.name as TableName
		,si.name as IndexName
		,cast(SUM(p.rows)*1.0
			/(SUM(p.rows)+1)*1.0 as decimal(5,4)) as IndexPercentageOfTable
		,max(si.rowmodctr) as IndexRowModCounter
	from sysindexes si
	inner join sys.objects t
	on si.id=t.object_id
	inner join sys.schemas s
	on t.schema_id=s.schema_id
	inner join sys.partitions p
	on p.object_id=t.object_id
	and p.index_id=si.indid
	where si.name is not null
	group by s.name, t.name, si.name

	/* 
	This big query has all of the logic.
	It takes index information, table information, and compares
	it to the parameters passed in above to determine whether
	each index is valid for having its stats updated.

	This is a little tricky because indexes are checked
	to see whether they are out of date. However, statistics are updated
	at the table level. 
	*/
	insert into #StatsList
	(TableObjectID
	,QualifiedTableName
	,DoUpdateStats
	,Description)
	select
		 src.TableObjectID
		,src.QualifiedTableName
		,DoUpdateStats=
			case when src.IsRowModCounterAboveThreshold=1
					or src.IsPercentageChangedAboveThreshold=1
				then 1 else 0 end
		,Description=
		  'Index ['+src.IndexName+N']: '
		  +case when src.IsRowModCounterAboveThreshold=1
			then 'Rowmodcounter ('
				+convert(nvarchar,src.IndexRowModCounter)
				+') is greater than the threshold ('
				+convert(nvarchar,@RowModCounterThreshold)+N') '
			else N'' end
		  +case when src.IndexRowModCounter / (src.EstimatedTableRowcount * src.IndexPercentageOfTable) > @RowModPercentageThreshold
			then N'Percentage changed ('
				+convert(nvarchar(9),convert(decimal(8,4),src.AdjustedPercentageChanged*100))
				+N'%) is above threshold ('
				+convert(nvarchar(9),convert(decimal(8,4),@RowModPercentageThreshold*100))
				+N'%) '
			else N'' end
		  +case when src.IsRowModCounterAboveThreshold=0
					and src.IsPercentageChangedAboveThreshold=0
			then 'Neither rowmodcounter or percentage changed is above threshold for index '+src.IndexName
			else N'' end
		  +N' '
	from
	(	
		select
			TableObjectID=t.ObjectID
			,QualifiedTableName=N'['+t.SchemaName+N'].['+t.TableName+N']'
			,IsRowModCounterAboveThreshold=case 
				when i.IndexRowModCounter > @RowModCounterThreshold
				then 1 else 0 end
			,IsPercentageChangedAboveThreshold=case
				when i.IndexRowModCounter / (t.EstimatedTableRowcount * i.IndexPercentageOfTable) > @RowModPercentageThreshold
				then 1 else 0 end
			,AdjustedPercentageChanged=i.IndexRowModCounter / (t.EstimatedTableRowcount * i.IndexPercentageOfTable)
			,i.IndexRowModCounter
			,t.EstimatedTableRowcount
			,i.IndexName
			,i.IndexPercentageOfTable
		from #TableList t
		inner join #IndexList i
		on t.SchemaName=i.SchemaName
		and t.TableName=i.TableName
		where t.EstimatedTableRowcount>0
	) as src

	/* Use the cursor to get information at a table level
	This includes aggregating the descriptions up from the various indexes
	to the table
	*/
	declare Csr cursor local read_only for 
	select
		s.QualifiedTableName
		,MAX(case when s.DoUpdateStats=1 then 1 else 0 end) as DoUpdateStats
		,(
			select +N', '+s2.Description
			from #StatsList s2
			where s2.TableObjectID=s.TableObjectID
			for xml path ('')
		) as DescriptionList
	from #StatsList s
	group by s.QualifiedTableName, s.TableObjectID

	open Csr

	fetch next from Csr into 
		@QualifiedTableName
		,@DoUpdateStats
		,@Description
	begin
		-- if the table is valid to have its stats updated, update the statistics
		if @DoUpdateStats=1
		begin
			set @cmd='update statistics '+@QualifiedTableName
				+case 
					when @StatsSamplingPercentage=0 
						then ' with resample'
					when @StatsSamplingPercentage is not null
						then ' with sample '+convert(nvarchar,@StatsSamplingPercentage)+' percent'
					else N'' end
				
				print (@cmd) --print the command to execute
				exec (@Cmd) --execute the command
		end
		
		-- print the message regardless of whether we update stats
		set @Msg=
			case when @DoUpdateStats=1
				then N'--Updating stats on '
				else N'--Do not update stats on ' 
				end
			+@QualifiedTableName+' because '+@Description
		
		print @Msg
		
		fetch next from Csr into 
			@QualifiedTableName
			,@DoUpdateStats
			,@Description
	end

	close Csr
	deallocate Csr
end
go

--Update Statistics Script Test
declare @RowsToRun int
	,@PercentageToInsert decimal(2,2)
	,@PercentageToDelete decimal(2,2)
	,@RowsToInsert int
	,@RowsToDelete int
	,@InitialInsertRunDate datetime
	,@DeleteRunDate datetime
	,@StatsUpdateDateAfterInsert datetime
	,@StatsUpdateDateAfterDelete datetime
	
-- Parameters
set @RowsToRun=1000000
set @PercentageToInsert=.1
set @PercentageToDelete=.1
set @RowsToInsert=@RowsToRun*@PercentageToInsert*1.0
set @RowsToDelete=@RowsToRun*@PercentageToDelete*1.0

if exists
(
	select
		is_auto_update_stats_on
		,is_auto_create_stats_on
	from sys.databases
	where database_id=DB_ID()
	and 
		(is_auto_create_stats_on=0
		or is_auto_update_stats_on=0)
)
begin
	raiserror('Error! Auto Update stats and auto create stats need to be turned on',16,1);
end

-- Create the test table and load it with sample data
if object_id('dbo._TestData') is not null
begin
	exec ('drop table dbo._TestData');
end

create table [dbo].[_TestData]
(
IntColumn int not null
,GuidColumn uniqueidentifier
,BitColumn bit not null
,BigIntColumn bigint not null
,NumericColumn numeric(16,8) not null
,BinaryColumn varbinary(max) not null
,CharColumn nvarchar(128) not null
,CharColumn2 nvarchar(max) not null
,FloatColumn float not null
,LastUpdateDate datetime not null
,constraint [_TestDataPK] primary key clustered (IntColumn)
);

if not exists
(
select * 
from sys.indexes
where object_id=object_id('dbo._TestData')
and name='FilteredIdx'
)
begin
	create index FilteredIdx
	on [dbo].[_TestData] (NumericColumn,CharColumn,FloatColumn)
	where GuidColumn > '00000000-0000-0000-0000-000000000000' and
	GuidColumn <= '00000000-0000-0000-0000-A00000000000'
end;

with
L0 as (select 0 as c union all select 1),
L1 as (select 0 as c from L0 cross join L0 as b),
L2 as (select 0 as c from L1 cross join L1 as b),
L3 as (select 0 as c from L2 cross join L2 as b),
L4 as (select 0 as c from L3 cross join L3 as b),
L5 as (select 0 as c from L4 cross join L3 as b),
nums as (select row_number() OVER (ORDER BY (select null)) as n from L5)

insert [dbo].[_TestData]
(
 IntColumn
,GuidColumn
,BitColumn
,BigintColumn
,NumericColumn
,BinaryColumn
,CharColumn
,CharColumn2
,FloatColumn
,LastUpdateDate
)
select 
	x.IntSeed as [IntColumn]
	,x.GuidSeed as [GuidColumn]
	,case when x.RandSeed > 0.500 then 1 else 0 end as [BitColumn]
	,convert(bigint,x.RandSeed * 10000000000000000 * rand()) as [BigintColumn]
	,convert(numeric(16,8),x.RandSeed * 100000 * rand()) as [NumericColumn]
	,convert(varbinary(max),x.RandSeed * 100000 * rand()) as [BinaryColumn]
	,convert(varchar(128),(convert(varbinary(max),x.RandSeed * 1000))) as [CharColumn]
	,convert(varchar(max),(convert(varbinary(max),x.RandSeed * 1000))) as [CharColumn2]
	,x.RandSeed as [FloatColumn]
	,GETDATE()
from 
(
select top (@RowsToRun)
		newid() as [GuidSeed]
		,rand(binary_checksum(newid())) as [RandSeed]
		,n as [IntSeed]
from nums
order by n
) x;  

-- Now run an insert on 10% of the table
insert [dbo].[_TestData]
(
 IntColumn
,GuidColumn
,BitColumn
,BigintColumn
,NumericColumn
,BinaryColumn
,CharColumn
,CharColumn2
,FloatColumn
,LastUpdateDate
)
select 
	x.IntSeed as [IntColumn]
	,x.GuidSeed as [GuidColumn]
	,case when x.RandSeed > 0.500 then 1 else 0 end as [BitColumn]
	,convert(bigint,x.RandSeed * 10000000000000000 * rand()) as [BigintColumn]
	,convert(numeric(16,8),x.RandSeed * 100000 * rand()) as [NumericColumn]
	,convert(varbinary(max),x.RandSeed * 100000 * rand()) as [BinaryColumn]
	,convert(varchar(128),(convert(varbinary(max),x.RandSeed * 1000))) as [CharColumn]
	,convert(varchar(max),(convert(varbinary(max),x.RandSeed * 1000))) as [CharColumn2]
	,x.RandSeed as [FloatColumn]
	,GETDATE()
from 
(
select top (@RowsToInsert)
		newid() as [GuidSeed]
		,rand(binary_checksum(newid())) as [RandSeed]
		,IntColumn+@RowsToRun as [IntSeed]
from dbo._TestData
order by IntColumn
) x;  


select 
	@StatsUpdateDateAfterInsert=max(STATS_DATE(object_id, stats_id))
	,@InitialInsertRunDate=GETDATE()
from sys.stats
where object_id=object_id('dbo._TestData')

exec dbo._TestUpdateStats @RowModCounterThreshold=50000


-- Now delete 10% of the table
delete from dbo._TestData
where IntColumn <= @RowsToDelete


select 
	@StatsUpdateDateAfterDelete=max(STATS_DATE(object_id, stats_id))
	,@DeleteRunDate=GETDATE()
from sys.stats
where object_id=object_id('dbo._TestData')

exec dbo._TestUpdateStats @RowModPercentageThreshold=0.05

select
	case when @StatsUpdateDateAfterInsert < @InitialInsertRunDate
	and @StatsUpdateDateAfterDelete < @InitialInsertRunDate
	and @StatsUpdateDateAfterInsert = @StatsUpdateDateAfterDelete
	then 'Stats are not being Updated automatically according to the newer thresholds'
	else N'Stats are being updated according to the newer thresholds. Hooray!' end as Description
	,case when @InitialInsertRunDate < @InitialInsertRunDate
		then 'Second Update did not get stats Updated'
		else 'Second Update did get stats Updated. Hooray!'
		end as SecondInsertDescription
	,case when @StatsUpdateDateAfterDelete < @InitialInsertRunDate
		then 'Delete did not Update statistics'
		else 'Delete Updated statistics. Hooray!'
		end as DeleteDescription
	,@InitialInsertRunDate as 'Run time of the first Insert command'
	,@StatsUpdateDateAfterInsert as 'After the first Insert, when were stats last Updated?'
	,@DeleteRunDate as 'Run time of the third command, a delete'
	,@StatsUpdateDateAfterDelete as 'After the third command, when were stats last Updated?'