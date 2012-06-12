function Query-ToCsv {
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

         $RowsToSkip = 0;
    }

    #Note: we use `t (tab) delimiters because Excel opens those natively.
    

	if ($Query.Length -gt 8)
	{
		Write-Host "Running get query on $Server . $Database ,Query: $Query";
		Invoke-SqlCmd -ServerInstance $Server -Database $Database -Query $Query | ConvertTo-Csv -NoTypeInformation -Delimiter $Delimiter | Select-Object -Skip $RowsToSkip | Out-File $CsvLocation -Append;
	}
	else
	{
		Write-Host "Running get query on $Server . $Database ,Input file: $FileLocation";
		Invoke-SqlCmd -ServerInstance $Server -Database $Database -InputFile $FileLocation | ConvertTo-Csv -NoTypeInformation -Delimiter $Delimiter | Select-Object -Skip $RowsToSkip | Out-File $CsvLocation -Append;
	}
}

function Queryier {
    param([string] $ServerListCsv
        ,[string] $QueryListCsv
        ,[string] $OutputDelimiter="`t"
    )

    if (-not (Test-Path $ServerListCsv))
    {
        Write-Error "Cannot find file $ServerListCsv";
    }

    if (-not (Test-Path $QueryListCsv))
    {
        Write-Error "Cannot find file $ServerListCsv";
    }

    Import-Csv $ServerListCsv | Foreach-Object {
        $Server = $_.Server;
        $Database = $_.Database;

        Write-Verbose "Now querying $Server . $Database";

        Import-Csv $QueryListCsv | Foreach-Object {
            $QueryOrFile = $_.QueryOrFile;
            $CsvLocation = $_.CsvLocation;
			$Name = $_.Name;
			$Group = $_.Group;

			$Query = "";
			$FileLocation = "";

            if (Test-Path $QueryOrFile)
            {
                $FileLocation = $QueryOrFile;
				#$Query = $null;
            }
            else
            {
                $Query = $QueryOrFile;
				#$FileLocation = $null;
            }
			
			Write-Host "Calling Query-ToCsv for $Server . $Database";

            Query-ToCsv -Server $Server -Database $Database -Query $Query -CsvLocation $CsvLocation -Delimiter $OutputDelimiter -FileLocation $FileLocation;
        }
    }

}