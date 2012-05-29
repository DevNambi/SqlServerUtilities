param([string]$Database = "", # Must be passed
      [string]$Server   = "$SQLServer",
      [switch]$Force,      # Required to delete an existing database.
      [switch]$Simple      # Set this database to use the "Simple" RecoveryModel and other things like like in DEV
     )


# Initializations
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null

$SMOServer = New-Object "Microsoft.SqlServer.Management.SMO.Server" $Server

$SMODatabase = $SMOServer.Databases | where-object {$_.Name -eq $Database}

if ($SMODatabase) {
   if ($Force -and $SMODatabase.IsSystemObject -eq $false) {
      $SMOServer.KillDatabase($Database)
   } else {
      Write-Warning "Database $Server.Database already exists. Pass -Force to drop and recreate database."
   }
}

# Create the database if it doesn't exist
$SMODatabase = $SMOServer.Databases[$Database]

if (-not $SMODatabase) {
   # Create the new database
   $SMODatabase =  New-Object "Microsoft.SqlServer.Management.SMO.Database"
   $SMODatabase.Name = $Database
   $SMODatabase.Parent = $SMOServer
   $SMODatabase.Create()
   Write-Host "Database $Database created"
}

if ($Simple -and $SMODatabase.IsSystemObject -eq $false) {
   $SMODatabase.SetOwner("sa")
   
   $SMODatabase.DatabaseOptions.RecoveryModel = [Microsoft.SqlServer.Management.Smo.RecoveryModel]::Simple
   
   $SMODatabase.Alter()
   Write-Verbose "Settings changed for simple usage"
}
