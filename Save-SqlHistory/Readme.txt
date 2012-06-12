This is the PS_SqlHistory module. It does the following

Getting started:
- You must be running Powershell 2.0 or later
- You must have the SQL Server cmdlets, provider, or mini-shell installed. A quick way to test this is to run Invoke-SqlCmd at a powershell window, to see if you get an error
- You must have your execution policy set to RemoteSigned
- You must be running under an account that has Windows login permissions to your SQL servers. This tool does not support the ability to store SQL logins in text files for security reasons,
and you shouldn't have the same SQL auth username/password for all of your servers.

WARNINGS:
- Make sure the queries you run are safe for your environment. Vet the queries yourself, and test them out against a development or test instance first.


How to use the tool:
- Open a Powershell window.
- Navigate to the folder where the PS_SqlHistory module is stored
- Dot source the file: > . .\PS_SqlHistory.ps1
- Make a CSV file with the list of servers & databases you want to query. Use the example provided to get started.
- Make a CSV file with the list of script files or raw queries you want to use. Use the example provided to get yourself started.
- Run Export-SqlHistory -ServerCsv <> -QueryListCsv <> -OutputDelimiter <>