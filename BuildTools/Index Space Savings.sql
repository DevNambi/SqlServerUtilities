select
	o.name as ObjectName
	,i.name as IndexName
	,i.type_desc as IndexType
	,sum(p.rows) as rows
	,sum(au.total_pages) as total_pages
	,sum(au.used_pages) as used_pages
	,SUM(au.total_pages) * 8.0 / 1024.0 as TotalSpaceInMB
from sys.indexes i
inner join sys.objects o
on o.object_id=i.object_id
inner join sys.partitions p
on p.object_id=o.object_id
and p.index_id=i.index_id
inner join sys.allocation_units au
on au.container_id = p.partition_id
inner join sys.data_spaces ds
on ds.data_space_id = i.data_space_id
where o.object_id > 10000
and i.type_desc <> 'CLUSTERED'
and i.is_primary_key=0
group by o.name
	,i.name
	,i.type_desc