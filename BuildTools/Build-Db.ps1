param (
[string] $Server
,[string] $Database
,[string] $Directory
,[switch] $DropDatabase
)

New-Database -Server $Server -Database $Database -Force:$DropDatabase

Run-DbScriptDirectory -Server $Server -Database $Database -Directory $Directory -Match ".tab"
<#
run scripts as following
- table\.tab
- table\.idx
- table\.fky
- table\.viw
- sproc \ .fnc
- sproc \ .sql
- script \ .sq1
- script\ .sql
- script \ .sqx
#>
}