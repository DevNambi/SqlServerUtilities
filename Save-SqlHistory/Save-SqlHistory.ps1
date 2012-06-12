function QueryTo-Csv {
    param ([string] $CsvLocation
        ,[string] $Query
        ,[string] $FileLocation
        ,[string] $Server
        ,[string] $Database
        ,[string] $Delimiter="`t")
    
    $RowsToSkip = 1;
    if (-not (Test-Path $CsvLocation))
    {
        Write-Host "Creating file at $CsvLocation because it does not yet exist";
        "" | Out-File $CsvLocation;

        #The $RowsToSkip is normally set to 1 because we don't want to keep writing out headers
        #The exception to that is the first time we create the file.
         $RowsToSkip = 0;
    }

    #Note: we use `t (tab) delimiters because Excel opens those natively.

    if ($Query.Length -gt 8)
    {
        #The $Query parameter was passed in, use it
        Write-Host "Running get query on $Server . $Database ,Query: $Query";
        Invoke-SqlCmd -ServerInstance $Server -Database $Database -Query $Query | ConvertTo-Csv -NoTypeInformation -Delimiter $Delimiter | Select-Object -Skip $RowsToSkip | Out-File $CsvLocation -Append;
    }
    else
    {
        #The $Query parameter wasn't passed in, use the $FileLocation instead
        Write-Host "Running get query on $Server . $Database ,Input file: $FileLocation";
        
        #We get the query via Invoke-SqlCmd, convert it to CSV, optionally skip the header row, and append the data to the specified .csv file
        Invoke-SqlCmd -ServerInstance $Server -Database $Database -InputFile $FileLocation | ConvertTo-Csv -NoTypeInformation -Delimiter $Delimiter | Select-Object -Skip $RowsToSkip | Out-File $CsvLocation -Append;
    }
}

function Save-SqlHistory {
    param([string] $ServerListCsv
        ,[string] $QueryListCsv
        ,[string] $OutputDelimiter="`t"
    )

    if (-not (Test-Path $ServerListCsv))
    {
        Write-Error "Cannot find server list at $ServerListCsv";
    }

    if (-not (Test-Path $QueryListCsv))
    {
        Write-Error "Cannot find query list at $ServerListCsv";
    }

    Import-Csv $ServerListCsv | Foreach-Object {
        $Server = $_.Server;
        $Database = $_.Database;

        Write-Verbose "Now querying $Server . $Database";

        Import-Csv $QueryListCsv | Foreach-Object {
            $QueryOrFile = $_.QueryOrFile;
            $CsvLocation = $_.CsvLocation;

            $Query = "";
            $FileLocation = "";

            if (Test-Path $QueryOrFile)
            {
                $FileLocation = $QueryOrFile;
            }
            else
            {
                $Query = $QueryOrFile;
            }
            
            Write-Verbose "Calling Query-ToCsv for $Server . $Database";

            QueryTo-Csv -Server $Server -Database $Database -Query $Query -CsvLocation $CsvLocation -Delimiter $OutputDelimiter -FileLocation $FileLocation;
        }
    }

}