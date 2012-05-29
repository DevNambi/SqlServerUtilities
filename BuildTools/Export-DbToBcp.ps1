#Example: Write-BcpFormatFiles -Server localhost -Database model 
#                                               -Directory C:\
function Write-TableSchemas {
	param ([string] $Server, 
           [string] $Database, 
           [string] $Directory="",
           [string] $Table="")

    if (-not ($Directory -eq ""))
    { $Directory = $Directory+"\"; }
    
    if ($Table -eq "")
    { $Table = ".*" }
    
    $SmoDb = $(Get-SqlDatabase -sqlserver $Server -dbName $Database)
    Write-Host "Querying $Server.$Database";
    
    #Get-SqlTable gets the SMO SQL table. We then loop through each table
	Get-SqlTable $SmoDb | Where-Object {$_.Name -match $Table} | Foreach-Object {
        #The file name is the directory, plus the schema and table name
        $fileName=$Directory+$_.Schema.Replace("\","")+"."+$_.Name+".sql"; 
        #The .Script() method does the work for us. 
        Write-Host "Writing create table statement for $_"; 
        $_.Script() | Out-File -FilePath $fileName;
        };
}

#Example: Write-BcpFormatFiles -Server localhost -Database model 
#                               -Directory C:\ -BcpFlags "-T -N -x"
function Write-BcpFormatFiles {
    param ([string] $Server, 
           [string] $Database, 
           [string] $Directory="", 
           [string] $Table="",
           [string] $BcpFlags="-T -x -N")
    
    #if the directory is specified, add a \ to its location
    if (-not ($Directory -eq ""))
    { $Directory = $Directory+"\"; }
    
    if ($Table -eq "")
    { $Table = ".*" }
    
    $SmoDb = $(Get-SqlDatabase -sqlserver $Server -dbName $Database)
    Write-Host "Querying $Server.$Database";
    
    Get-SqlTable $SmoDb | Where-Object {$_.Name -match $Table} | Foreach-Object { 
    $tableName="["+$Database+"].["+$_.Schema+"].["+$_.Name+"]"; 
    $fileName=$Directory+$Database+"."+$_.Schema.Replace("\","")+"."
        +$_.Name+".format.xml"; 
    $bcpCall = "bcp.exe "+$tableName+" format nul "+$BcpFlags+" -S "+$Server
        +" -f "+$fileName; 
    Write-Host "Now calling $bcpCall";
    Invoke-Expression $bcpCall; }
}


#Example: Export-TablesToBcpFiles -Server localhost -Database model 
#                                   -Directory C:\ -BcpFlags "-T -N"

function Export-TablesToBcpFiles {
    param ([string] $Server, 
           [string] $Database, 
           [string] $Directory="", 
           [string] $Table="",
           [string] $BcpFlags="-T -N")    
    
    #if the directory is specified, add a \ to its location
    if (-not ($Directory -eq ""))
    { $Directory = $Directory+"\"; }
    
    if ($Table -eq "")
    { $Table = ".*" }
    
    $SmoDb = Get-SqlDatabase $Server $Database;
    
    Get-SqlTable $SmoDb | Where-Object {$_.Name -match $Table} | Foreach-Object { 
    $tableName="["+$Database+"].["+$_.Schema+"].["+$_.Name+"]"; 
    $fileName='"'+$Directory+$Database+"."+$_.Schema.Replace("\","")
        +"."+$_.Name+'.bcp"'; 
    $bcpCall = "bcp.exe "+$tableName+" out "+$fileName+" -S "+$Server
        +" "+$BcpFlags; 
    Write-Host "Now calling $bcpCall";
    Invoke-Expression $bcpCall; }
}


function Invoke-TableSchemas {
	param ([string] $Server, 
           [string] $Database, 
           [string] $Directory="",
           [string] $Table="")

    if (-not ($Directory -eq ""))
    { $Directory = $Directory+"\"; }
    else
    { $Directory = Get-Location; }
    
    if ($Table -eq "")
    { $Table = ".*" }
    
    Get-ChildItem -Path $Directory | Where-Object { $_.Extension -eq ".txt" } | Foreach-Object {
        Write-Host "Running create table statement for $_";
        Invoke-SqlCmd -ServerInstance $Server -Database $Database -InputFile $_.FullName;   
    }
}

function Import-TablesFromBcpFiles {
    param ([string] $Server, 
           [string] $Database, 
           [string] $Directory="", 
           [string] $Table="",
           [string] $BcpFlags="-T -N")    
    
    #if the directory is specified, add a \ to its location
    if (-not ($Directory -eq ""))
    { $Directory = $Directory+"\"; }
    
    if ($Table -eq "")
    { $Table = ".*" }
    
    Get-ChildItem -Path $Directory | Where-Object { $_.Extension -eq ".bcp" } | Foreach-Object {
        $tableName=$_.Name.Replace($_.Extension,"");
        $formatFile=$tableName+".format.xml";
        $bcpCall="bcp.exe $tableName in "+$_.FullName+" -T -S $Server -f $formatFile -N";
        Write-Host "Now loading $tableName";
        Invoke-Expression $bcpCall;
    } 
}

function Copy-DatabaseViaBcp {
    param ([string] $SourceServer, 
           [string] $SourceDatabase, 
           [string] $DestinationServer,
           [string] $DestinationDatabase,
           [string] $StagingDirectory="", 
           [string] $Table="",
           [string] $BcpFlags="-T -N")    
    
   #this is just a wrapper call
   Write-TableSchemas -Server $SourceServer -Database $SourceDatabase -Directory $StagingDirectory -Table $Table;
   
   $formatFileFlags = "$BcpFlags -x"
   Write-BcpFormatFiles -Server $SourceServer -Database $SourceDatabase -Directory $StagingDirectory -Table $Table -BcpFlags $formatFileFlags
   
   Export-TablesToBcpFiles -Server $SourceServer -Database $SourceDatabase -Directory $StagingDirectory -Table $Table -BcpFlags $BcpFlags;
   
   Invoke-TableSchemas -Server $DestinationServer -Database $DestinationDatabase -Directory $StagingDirectory -Table $Table;

   Import-TablesFromBcpFiles -Server $DestinationServer -Database $DestinationDatabase -Directory $StagingDirectory -Table $Table -BcpFlags $BcpFlags;
}