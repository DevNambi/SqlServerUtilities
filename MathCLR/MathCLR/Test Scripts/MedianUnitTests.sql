/* 
Instructions:
- Run this script after deploying the CLR assembly to a database. The tests are self-contained and will return 'Success' or 'Failure' for each test
*/

sp_configure 'clr enabled', 1
go
reconfigure
go
if object_id('dbo.MedianSource') is null
begin
	create table dbo.MedianSource
	(SourceNumber bigint null)
	
	create clustered index nonUniqueClu on dbo.MedianSource (SourceNumber)
end
go
-- Test cases
delete from dbo.MedianSource

select dbo.Median(m.SourceNumber)
	,case when dbo.Median(m.SourceNumber) is null
		then 'Success, 0 inputs returns null as expected'
		else 'False, 0 inputs should return NULL' end as TestResult
from dbo.MedianSource m
go

-- Basic median test, odd number of inputs
delete from dbo.MedianSource

insert into dbo.MedianSource (SourceNumber)
select 0 union all
select 1 union all
select 8 union all
select 43 union all
select 934 union all
select 873434 union all
select 82322

select dbo.Median(m.SourceNumber)
	,case when dbo.Median(m.SourceNumber) = 43
	then 'Success, returns median value of 43'
	else 'Failure, returns unexpected median value'
	end as TestResult
from dbo.MedianSource m
go
-- Basic median test, even number of inputs
delete from dbo.MedianSource

insert into dbo.MedianSource (SourceNumber)
select 0 union all
select 1 union all
select 3 union all
select 463 union all
select 2373 union all
select 8347 union all
select 87231 union all
select 234238

select dbo.Median(m.SourceNumber)
	,case when dbo.Median(m.SourceNumber) = 1418
	then 'Success, returns median value of 1418, which is the average of the middle two inputs'
	else 'Failure, returns unexpected median value'
	end as TestResult
from dbo.MedianSource m
go
-- Null test, make sure null values are excluded when doing median calculations
delete from dbo.MedianSource

insert into dbo.MedianSource (SourceNumber)
select 0 union all
select null union all
select null union all
select 1 union all
select 8 union all
select 43 union all
select null union all
select 934 union all
select 873434 union all
select 82322 union all
select null union all
select null


select dbo.Median(m.SourceNumber)
	,case when dbo.Median(m.SourceNumber) = 43
	then 'Success, returns median value of 43'
	else 'Failure, returns unexpected median value'
	end as TestResult
from dbo.MedianSource m
go

-- Test cleanup
if object_id('dbo.MedianSource') is not null
begin
	exec ('drop table dbo.MedianSource')
end