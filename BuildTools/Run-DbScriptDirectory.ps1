param (
[ValidateNotNullorEmpty()]
[string] $Server
,[ValidateNotNullorEmpty()]
[string] $Database
,[ValidateNotNullorEmpty()]
[string] $Directory
,[ValidateNotNullorEmpty()]
[string] $Match=".*"
,[int] $ConnectionTimeout=30
)

if ($Match -eq "") {
    $Match='.*'
}

$matchCount = 0;
<# Invoke-SqlCmd 
    -ServerInstance $Server 
    -Database $Database 
    -ConnectionTimeout $ConnectionTimeout
    -InputFile $_.Name; #>
    
Get-ChildItem $Directory |
Where-Object { $_.Name -match $Match} |
Foreach-Object { Write-Host $_.Name; 
    [string]$fileContent = Get-Content $_.FullName;
    if ($fileContent.Length -ge 2)
    {
        Write-Host "Now applying $_";
        Set-SqlData -sqlserver $Server -dbname $Database -qry $fileContent;
    }
    else
    {
        Write-Warning "File $_ has no content, skipping";
    }
    $matchCount++; 
}

if ($matchCount -eq 0)
{
    Write-Host "Unable to find matching files in directory $Directory";
}
else
{
    Write-Host "$matchCount matching files found and applied";
}