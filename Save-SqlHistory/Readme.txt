This is the Save-SqlHistory utility. It allows you to query dozens or hundreds of SQL Servers and collect the same information from all of them, for monitoring, logging, and trending purposes. 


Getting started:
- You must be running Powershell 2.0 or later
- You must have the SQL Server cmdlets, provider, or mini-shell installed. A quick way to test this is to run Invoke-SqlCmd at a powershell window, to see if you get an error. If you don't get an error, you're good to go.
- You must have your execution policy set to RemoteSigned
- You must be running under an account that has Windows login permissions to your SQL servers. This tool does not support the ability to store SQL logins in text files for security reasons, and you shouldn't have the same SQL auth username/password for all of your servers anyways.

WARNING:
- Make sure the queries you run are safe for your environment. Vet the queries yourself, and test them out against a development or test instance first.


How to use the tool:
- Open a Powershell window.
- Navigate to the folder where the Save-SqlHistory module is stored
- Dot source the file: > . .\Save-SqlHistory.ps1
- Make a CSV file with the list of servers & databases you want to query. Use the example provided to get started.
- Make a CSV file with the list of script files or raw queries you want to use. Use the example provided to get yourself started.
- Run Save-SqlHistory -ServerListCsv <location of CSV with the list of servers/databases> -QueryListCsv <location of CSV with queries or paths to queries> -OutputDelimiter <delimiter, defaults to tab>
    Use the Queries.csv and Servers.csv files to get a idea of how these CSV files should be configured.

Servers.csv:
- This CSV file has 2 columns, Server and Database. 
- The server is the name of the SQL Server. For clusters, it is the cluster name. For named instances, include the name of the instance, for example MyTestServer\TestInstance.
- The name of the database is just the physical database name.

Queries.csv
- This CSV has 2 columns, CsvLocation and QueryOrFile
- The CsvLocation is the name and location you want the CSV results written to. It can be either a relative path (.\Output\Results.csv) or an absolute path (C:\SqlServerUtilities\Save-SqlHistory\Output\Results.csv). 
- The QueryOrFile column contains either a query to run ("select getdate(), SomeMoreInformation from sys.databases") or the location of a script to run (.\Queries\Server - Wait Stats.sql). The Save-SqlHistory will automatically detect which is which. If you specify a file name, you can use either a relative or absolute path.