function Invoke-DatabaseBackup {
	param ([string] $Server, 
           [string] $Database, 
           [string] $BackupDirectory,
           [string] $BackupParameters,
           [string] $BackupJobName="",
           [string] $BackupType="FULL")
    if ($BackpJobName.Length -gt 3)
    {
        Write-Verbose "Calling backup job $BackupJobName";
        
		$JobQuery = "select * from msdb.dbo.sysjobs"
		Invoke-SqlCmd -ServerInstance $Server -Database $Database -Query $JobQuery;
        
        Write-Error "Fix me, I don't work yet";
        
        Write-Verbose "Skipping manual backup call because -BackupJobName was passed";
    }
    else
    {
        Write-Verbose "Building manual backup command";
        $BackupCommand = "exec [dbo].[DatabaseBackup]
@Databases='$Database'
,@Directory='$BackupDirectory'
,@BackupType='$BackupType'
,$BackupParameters
";
        
        Invoke-SqlCmd -ServerInstance $Server -Database 'master' -Query $BackupCommand -Verbose
    }
}

function Invoke-DatabaseRestore {
	param ([string] $Server, 
           [string] $Database, 
           [string] $BackupDirectory="",
           [string] $RestoreParameters)
    
    $RestoreCommand = "exec [dbo].[DatabaseRestore]
@";
    
    Invoke-SqlCmd -ServerInstance $Server -Database $Database -Query $BackupCommand -Verbose
}

function Invoke-CheckDb {
	param ([string] $Server, 
           [string] $Database,
           [string] $CheckDbParameters=""
           )

    $CheckDbQuery = "DBCC CHECKDB $CheckDbParameters";
    Write-Verbose "Now running $CheckDbQuery";
    Invoke-SqlCmd -ServerInstance $Server -Database $Database -Query $CheckDbQuery -Verbose
}

function Invoke-DropDb {
    param ([string] $Server, 
           [string] $Database)
    
    #DROP THE DB
}

function Get-IndexDefinitions {
	param ([string] $Server, 
           [string] $Database, 
           [string] $Directory="",
           [string] $Table="")

}

function Invoke-BackupAndRestore {
    param([string] $SourceServer,
          [string] $SourceDatabase,
          [string] $RestoreServer,
          [string] $RestoreDatabase,
          [string] $BackupDirectory,
          [string] $BackupParameters,
          [string] $BackupJobName,
          [string] $RestoreParameters,
          [string] $CheckDbParameters)

    Invoke-DatabaseBackup -Server $SourceServer -Database $SourceDatabase -BackupDirectory $BackupDirectory -BackupParameters $BackupParameters
    Invoke-DatabaseRestore -Server $RestoreServer -Database $RestoreDatabase -BackupDirectory $BackupDirectory -RestoreParameters $RestoreParameters
    Invoke-CheckDb -Server $RestoreServer -Database $RestoreDatabase -CheckDbParameters $CheckDbParameters
}

function Invoke-IndexScriptAndDrop {
    param([string] $Server, 
          [string] $Database,
          [switch] $ScriptToDb,
          [switch] $ScriptToFile,
          [string] $ScriptDirectory,
          [string] $ScriptTableName
    )
    
}

<# This function is DONE on 12-14-2011 #>
function Get-IndexSpaceSavings {
    param([string] $Server, 
          [string] $Database)
    
    $EstimateQuery = "select
o.name as ObjectName
,i.name as IndexName
,i.type_desc as IndexType
,sum(p.rows) as rows
,sum(au.total_pages) as total_pages
,sum(au.used_pages) as used_pages
,SUM(au.total_pages) * 8.0 / 1024.0 as total_space_mb
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
,i.type_desc";
    
    $SpaceSavingData = Invoke-SqlCmd -ServerInstance $Server -Database $Database -Query $EstimateQuery;
	
	$TotalRows = 0;
	$TotalPages = 0;
	$TotalSpaceMB = 0;
	
	$SpaceSavingData | Foreach-Object {
		$TotalRows += $_.rows;
		$TotalPages += $_.total_pages;
		$TotalSpaceMB += $_.total_space_mb;
	}
	
	Write-Host "Dropping nonclustered indexes will make your DB $TotalSpaceMB MB smaller  ($TotalPages pages, $TotalRows rows)";
    
    $SpaceSavingData
}

function Invoke-IndexRecreate {
    param([string] $Server, 
          [string] $Database,
          [switch] $ScriptFromDb,
          [string] $ScriptDirectory,
          [string] $ScriptTableName
    )

}


function Invoke-BackupAndRestoreWithIndexDrops {
    param([string] $SourceServer,
          [string] $SourceDatabase,
          [string] $RestoreServer,
          [string] $RestoreDatabase,
          [string] $BackupDirectory,
          [string] $BackupParameters,
          [string] $BackupJobName,
          [string] $RestoreParameters,
          [string] $CheckDbParameters,
          [switch] $DropIndexes,
          [switch] $ScriptIndexesToFile,
          [switch] $ScriptIndexesToDb,
          [string] $ScriptDirectory,
          [string] $ScriptTableName,
          [switch] $DropDatabaseWhenDone)

    #First, back up and restore the DB from our source system. Do a CheckDB as well.
    <#
	Invoke-BackupAndRestore -SourceServer $SourceServer -SourceDatabase $SourceDatabase 
        -RestoreServer $RestoreServer -RestoreDatabase $RestoreDatabase 
        -BackupDirectory $BackupDirectory -BackupParameters $BackupParameters
        -BackupJobName $BackupJobName -RestoreParameters $RestoreParameters
        -CheckDbParameters $CheckDbParameters
	#>
    #Next, script out all of the indexes
    if ($ScriptIndexesToFile -or $ScriptIndexesToDb)
    {
        Write-Verbose "Scripting out indexes because -ScriptIndexesToFile or -ScriptIndexesToDb was specified";
        <#Invoke-IndexScriptAndDrop -Server $RestoreServer -Database $RestoreDatabase
            -ScriptDirectory $ScriptDirectory -ScriptTableName $ScriptTableName 
            -ScriptToDb ? $ScriptToDb -ScriptToFile ? $ScriptToFile
        #>
        Write-Verbose "Indexes scripted out and dropped. Now doing another backup";
        Invoke-DatabaseBackup -Server $RestoreServer -Database $RestoreDatabase -BackupDirectory $BackupDirectory -BackupParameters $BackupParameters #YIKES

        Invoke-DropDatabase -Server $RestoreServer -Database $RestoreDatabase 
        
        Invoke-DatabaseRestore -Server $RestoreServer -Database $RestoreDatabase -BackupDirectory $BackupDirectory -RestoreParameters $RestoreParameters
        
        Invoke-CheckDb -Server $RestoreServer -Database $RestoreDatabase -CheckDbParameters $CheckDbParameters
        
        if ($DropDatabaseWhenDone)
        {
            Invoke-DropDatabase -Server $RestoreServer -Database $RestoreDatabase 
        }
    }
    else {
        Write-Warning "Neither -ScriptIndexesToFile or -ScriptIndexesToDb was passed, so no index drops will be done";
    }
}