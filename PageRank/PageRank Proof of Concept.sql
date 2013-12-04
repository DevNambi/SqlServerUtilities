-- drop table dbo.Nodes

CREATE TABLE Nodes
(NodeId int not null
,NodeWeight decimal(10,5)
,NodeCount int not null default(0)
,HasConverged bit not null default(0)
,constraint NodesPK primary key clustered (NodeId)
)
go

CREATE TABLE Edges
(SourceNodeId int not null
,TargetNodeId int not null
,constraint EdgesPK primary key clustered (SourceNodeId, TargetNodeId)
)
go

delete from dbo.Nodes

delete from dbo.Edges
go


INSERT INTO dbo.Nodes
(NodeId
,NodeWeight
,HasConverged)
VALUES
(1,0.25,0)
,(2,0.25,0)
,(3,0.25,0)
,(4,0.25,0)

INSERT INTO dbo.Edges
(SourceNodeId
,TargetNodeId)
VALUES
(2,1) --page 2 links to pages 1 and 3
,(2,3)
,(3,1) --page 3 links to page 1
,(4,1) -- page 4 links to the 3 other pages
,(4,2)
,(4,3)




-- Running PageRank
declare @DampingFactor decimal(3,2) = 0.85
	,@MarginOfError decimal(10,5) = 0.001
	,@TotalNodeCount int

select @TotalNodeCount = count(*)
from dbo.Nodes

update n
set n.NodeCount = isnull(x.TargetNodeCount,@TotalNodeCount) --store the number of edges each node has pointing away from it.
	-- if a node has 0 edges going away (it's a sink), then its number is the total number of edges in the system.
from dbo.Nodes n
left outer join
(
	select SourceNodeID,
		TargetNodeCount = count(*)
	from dbo.Edges
	group by SourceNodeId
) as x
on x.SourceNodeID = n.NodeId
go
-- select * from dbo.Nodes


declare @DampingFactor decimal(3,2) = 0.85
	,@MarginOfError decimal(10,5) = 0.001
	,@TotalNodeCount int
	,@IterationCount int = 1

select @TotalNodeCount = count(*)
from dbo.Nodes

WHILE EXISTS
(
	SELECT *
	FROM dbo.Nodes
	WHERE HasConverged = 0
)
BEGIN

	UPDATE n
	SET 
	NodeWeight = 1.0 - @DampingFactor + isnull(x.TransferredNodeWeight, 0.0)
	,HasConverged = case when abs(n.NodeWeight - (1.0 - @DampingFactor + isnull(x.TransferredNodeWeight, 0.0))) < @MarginOfError then 1 else 0 end
	FROM Nodes n
	LEFT OUTER JOIN
	(
		-- Compute the PageRank each target node by the sum
		-- of the nodes' weights that point to it.
		SELECT
			e.TargetNodeId
			,TransferredNodeWeight = sum(n.NodeWeight / n.NodeCount) * @DampingFactor
		FROM Nodes n
		INNER JOIN Edges e
		  ON n.NodeId = e.SourceNodeId
		WHERE e.SourceNodeId <> e.TargetNodeId --self references are ignored
		GROUP BY e.TargetNodeId
	) as x
	on x.TargetNodeId = n.NodeId

	select
		@IterationCount as IterationCount
		,*
	from Nodes

	set @IterationCount += 1
END

