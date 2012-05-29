/* 
Author: Dev Nambi
Website: www.devnambi.com 
Version: 1.0
You are welcome to use this script for any of your own purposes, but please
do not publish it as your own work. See the website for full copyright details 
(Creative Commons).
*/

--Create a stored procedure
if OBJECT_ID('dbo._ManuallyCreateStats') is not null
begin
	exec ('drop procedure dbo._ManuallyCreateStats')
end
go
create procedure dbo._ManuallyCreateStats
as
begin
	set nocount on;
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
end
go



--Now, create the test table and load it
declare @RowsToRun int
set @RowsToRun=1000000

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
go

/* 
This is the key part of the test. Uncomment the line below to manually create
stats on all columns
*/
--exec dbo._ManuallyCreateStats

declare @Cmd nvarchar(4000)
select @Cmd='ALTER DATABASE '+DB_NAME()+' SET READ_ONLY'
exec (@Cmd)
go

-- now, run a series of queries and store their query times
if object_id('tempdb..#Results') is null
begin
	create table #Results
	(TestDescription varchar(256) not null primary key clustered
	,TestRowsReturned int not null
	,TestStartDate datetime not null
	,TestEndDate datetime not null)
end
truncate table #Results

declare  @StartTime datetime
		,@EndTime datetime
		,@RowCount int

DBCC FREEPROCCACHE WITH NO_INFOMSGS;
DBCC DROPCLEANBUFFERS;

select @StartTime=getdate()

select *
from [dbo].[_TestData]
where LastUpdateDate < '2010-01-01' --this should return no values

select @EndTime=getdate()
	,@RowCount=@@ROWCOUNT

insert into #Results
(TestDescription
,TestRowsReturned
,TestStartDate
,TestEndDate)
values
('Query w/ LastUpdateDate'
,@RowCount
,@StartTime
,@EndTime)

-- Query #2
DBCC FREEPROCCACHE WITH NO_INFOMSGS;
DBCC DROPCLEANBUFFERS;

select @StartTime=getdate()

select *
from [dbo].[_TestData]
where BigIntColumn < 0 --this should be half the values

select @EndTime=getdate()
	,@RowCount=@@ROWCOUNT

insert into #Results
(TestDescription
,TestRowsReturned
,TestStartDate
,TestEndDate)
values
('Query w/ BigintColumn'
,@RowCount
,@StartTime
,@EndTime)

-- Query #3
DBCC FREEPROCCACHE WITH NO_INFOMSGS;
DBCC DROPCLEANBUFFERS;

select @StartTime=getdate()

select *
from [dbo].[_TestData]
where NumericColumn < 0 --this should half the values

select @EndTime=getdate()
	,@RowCount=@@ROWCOUNT

insert into #Results
(TestDescription
,TestRowsReturned
,TestStartDate
,TestEndDate)
values
('Query w/ NumericColumn'
,@RowCount
,@StartTime
,@EndTime)

-- Query #4
DBCC FREEPROCCACHE WITH NO_INFOMSGS;
DBCC DROPCLEANBUFFERS;

select @StartTime=getdate()

select *
from [dbo].[_TestData]
where FloatColumn < 0 --this should half the values

select @EndTime=getdate()
	,@RowCount=@@ROWCOUNT

insert into #Results
(TestDescription
,TestRowsReturned
,TestStartDate
,TestEndDate)
values
('Query w/ FloatColumn'
,@RowCount
,@StartTime
,@EndTime)

-- Now that we've run the queries, return the results
select
	TestDescription
	,DATEDIFF(ms, TestStartDate, TestEndDate) as RunTimeInMs
	,TestRowsReturned
	,TestStartDate
	,TestEndDate
from #Results


declare @Cmd nvarchar(4000)
select @Cmd='ALTER DATABASE '+DB_NAME()+' SET READ_WRITE'
exec (@Cmd)
go