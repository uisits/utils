/*
From: https://asktom.oracle.com/pls/apex/asktom.search?tag=how-can-i-track-the-execution-of-plsql-and-sql

I use the script at the bottom. It shows everyone logged in and if they are active, what they are doing and how long they've been doing it.

If someone is executing PLSQL, what you will see will depend on what the plsql is currently doing. If the plsql is doing SQL, you'll see the SQL. if the plsql is doing lots of PLSQL work -- you'll see that code. What I like to do is have everyone "instrument" their code with calls to dbms_application_info which can fill in the client_info, action, and module columns in v$session. In this fashion, you can see where in a procedure someone is based on the values in these columns. showsql exposes this information to you as well. sqlplus uses it to show you what script someone is running for example...

...yields output like:

SYSTEM(393,48920) ospid = 14136 program = oracle@oraprod.uisad.uis.edu (J001)
 Wednesday 06:00  Wednesday 10:20 last et = 15576
insert /*+ append */ into  uis_edw.Z_2_NETID ("EMPEE_HOME_CAMPUS_IND", "NETID_POST_DT", "NETID_EFF_DT", "ENTRP_ID_IND", "NETID_PRINCIPAL", "EDW_PERS_ID", "NETID_DOMAIN")  select  "EMPEE_HOME_CAMPUS_IND", "NETID_POST_DT", "NETID_EFF_DT", "ENTRP_ID_IND"

...so you can kill offending session:  
alter system kill session '393,48920,@1';  -- SYSTEM(393,48920)  <username( sid, session )>

...then re-ran:

*/
---------------- showsql.sql --------------------------
column status format a10
set feedback off
set serveroutput on

select username, sid, serial#, process, status
from v$session
where username is not null
/

column username format a20
column sql_text format a55 word_wrapped

set serveroutput on size 1000000
declare
x number;
begin
for x in
( select username||'('||sid||','||serial#||
') ospid = ' || process ||
' program = ' || program username,
to_char(LOGON_TIME,' Day HH24:MI') logon_time,
to_char(sysdate,' Day HH24:MI') current_time,
sql_address, LAST_CALL_ET
from v$session
where status = 'ACTIVE'
and rawtohex(sql_address) <> '00'
and username is not null order by last_call_et )
loop
for y in ( select max(decode(piece,0,sql_text,null)) ||
max(decode(piece,1,sql_text,null)) ||
max(decode(piece,2,sql_text,null)) ||
max(decode(piece,3,sql_text,null))
sql_text
from v$sqltext_with_newlines
where address = x.sql_address
and piece < 4)
loop
if ( y.sql_text not like '%listener.get_cmd%' and
y.sql_text not like '%RAWTOHEX(SQL_ADDRESS)%')
then
dbms_output.put_line( '--------------------' );
dbms_output.put_line( x.username );
dbms_output.put_line( x.logon_time || ' ' ||
x.current_time||
' last et = ' ||
x.LAST_CALL_ET);
dbms_output.put_line(
substr( y.sql_text, 1, 250 ) );
end if;
end loop;
end loop;
end;
/

column username format a15 word_wrapped
column module format a15 word_wrapped
column action format a15 word_wrapped
column client_info format a30 word_wrapped

select username||'('||sid||','||serial#||')' username,
module,
action,
client_info
from v$session
where module||action||client_info is not null; 
