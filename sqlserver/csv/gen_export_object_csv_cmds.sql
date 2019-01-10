/*
File:	utils/sqlserver/csv/gen_export_object_csv_cmds.sql

Desc:	This script provides an example of iterating across a schema/db table set, and generating
		the command set for exporting tables to CSV.

		[gen_csv_export_cmds.sql] - generates the set of calls to [export_object_csv] - for each table.

		{ set of generated [export_object_csv ...] commands } - run from SQL, and this will give you the
		generated [bcp] command.
		
		{ set of generated [bcp ...] commands } - run this from CMD (DOS) in the directory you want the
		files to go to.
		
		You can also direct the output file to a specific location, if you don't want to be concerned
		with where to invoke the [bcp] commands from (which folder) in DOS.
		
Author:	Vern Huber
*/
begin
-- Generate the calls to [export_object_csv], whih will generate the [BCP] commands (for running from DOS).
--
print 'echo Remember: '
print 'echo (1) System tables for the targeted DB are also included, these should be filtered out.'
print 'echo'
print 'echo (2) the location from where you inovked this script, that is where your output will be.'
print
print 'echo (3) Ensure that [SVN: utils/sqlserver/export_object_csv.sql] has been applied to DB schema.'

/*  PREVIOUS version - no headers (columns), data only...
select 'bcp "select * from  pipp.dbo.'
+ table_name +' " queryout "'
+ table_name + '.csv" -c -T -S uisprodmssql\uisprodmssql  -U sa -P Mssql@08 -t,'
from pipp.INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'  order by table_name
*/

-- CMD needs to look like:    exec pipp.dbo.export_object_csv '<some_table_name>', 'C:\test.csv' 
--
select 'exec pipp.dbo.export_object_csv '''+ table_name +''', '''+ table_name + '.csv'''
from pipp.INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' 
and table_name != '__RefactorLog' and table_name != 'sysdiagrams' and table_name not like '%_BAK' 
order by table_name

print 'echo REMEMBER to review the prologue output.'
end;
