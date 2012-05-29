/* 
Isolation level
Auto create stats
Auto update stats
recovery model
default backup location
access mode
compat level
ansi nulls
ansi padding
ansi null default
*/


declare @ServerConfigXML xml
set @ServerConfigXML=N'
<database-config name="">
	<setting 
		name="Isolation Level" 
		value="10" 
		description="" />
	<setting 
		name="Auto Create Stats" 
		value="" 
		description="" />
	<setting 
		name="Auto Update Stats" 
		value="" 
		description="" />
	<setting 
		name="Auto Update Stats Async" 
		value="" 
		description="" />
	<setting 
		name="Recovery Model" 
		value="0" 
		description="" />
	<setting 
		name="Default Backup Location" 
		value="0" 
		description="" />
	<setting 
		name="Access Mode" 
		value="0" 
		description="" />
	<setting 
		name="Compatibility Level" 
		value="1" 
		description="" />
	<setting 
		name="Ansi Nulls" 
		value="1" 
		description="" />
	<setting 
		name="Ansi Null Default" 
		value="1" 
		description="" />
	<setting 
		name="Ansi Padding" 
		value="1" 
		description="" />
</database-config>
'
