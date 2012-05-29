<#
.SYNOPSIS
Executes a SQL query, returning the first table in the returned data set

.DESCRIPTION
Executes a SQL query, returning the first table in the returned data set. 
Queries can either be files on disk, or a string query to execute

.PARAMETER Server
Target database server

.PARAMETER Database
Target database

.PARAMETER CommandTimeout
Time out for command execution in seconds.  Defaults to 90 seconds.

.PARAMETER File
The file path to the SQL to execute

.PARAMETER Query
The SQL string to execute

.INPUTS
None. You cannot pipe objects to Execute-SQLQuery.

.OUTPUTS
The first table in the returned data set (if any).

.EXAMPLE
C:\PS> Execute-SQLQuery -Server localhost -Database AtlasFactStage -File sqlToExecute.sql
Executes the contents of sqlToExecute.sql against localhost's AtlasFactStage database. 

C:\PS> Execute-SQLQuery -Server DbMachine01 -Database SearchReport -Query "Select * from [Evt].[log]"
Executes the select statement shown against DbMachine01's SearchReport database.
#>

#requires -version 2.0

[CmdletBinding(DefaultParameterSetName="Query")]        
param(
	[string]$Server,
	[string]$Database,
	[int]$CommandTimeout = 90,
	
	[Parameter(Mandatory=$true, ParameterSetName="File")] 
	[string]$File,
	
	[Parameter(Mandatory=$true, ParameterSetName="Query")] 
	[string]$Query
)		


begin {
	switch ($psCmdlet.ParameterSetName) {
		File { $sqlQuery = [string]::Join("`n", $(Get-Content $File)) }
		Query { $sqlQuery = $Query }
	}
	$dataSet= new-object "System.Data.DataSet" "Results"
	$da = new-object "System.Data.SqlClient.SqlDataAdapter" ($sqlQuery, "Server=$server;Database=$database;Trusted_Connection=yes;")
	$da.SelectCommand.CommandTimeout = $CommandTimeout
}
process {
	[void] $da.Fill($dataSet)
	if ($dataSet.Tables.Count -gt 0) 
	{ 
		$dataSet.Tables[0]
	}
}
end {
	$da.Dispose()
}
