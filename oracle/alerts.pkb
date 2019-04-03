/* 
File:	uis_utils/oracle/alerts.pkb
 
Desc:	Code supporting DB alert notices (e.g., security violations).
		
NOTE:	Some schemas to remove when trying to identifty targeted set:
 
		select * from uis_edw.ALL_VALID_PRIVS  
		where grantee NOT IN ('UIS_CDM','UIS_CDM_PVT','UIS_EDW') and is_display = 'Y'
		...or
		where grantee IN ( 'F3A', 'BB4ALL' )
		
NOTE2:	Changes should be applied across the following DBs:
		OraProd, OraTest, OraDept
		
See:	na

Author:	Vern Huber

Enhancements:
		
 */
 
-- ==========================  JOBs =====================================================

-- Run job:		exec DBMS_SCHEDULER.run_job('uis_utils.UTILS_RPT_VERIFY_PERMS');
-- Drop job:	exec DBMS_SCHEDULER.drop_job('uis_utils.UTILS_RPT_VERIFY_PERMS');
BEGIN
   DBMS_SCHEDULER.CREATE_JOB (
      job_name => 'uis_utils.UTILS_RPT_VERIFY_PERMS', job_type => 'PLSQL_BLOCK'
      , job_action		=> 'begin  uis_utils.alerts.VERIFY_PERMISSIONS;  end;'
      , start_date           => '11-FEB-19 6.31.00PM'
      , repeat_interval      => 'FREQ=DAILY' 
      , end_date             => NULL						-- '15-JAN-99 1.00.00AM US/Pacific',
      , enabled =>  TRUE,  comments => 'UTILS: alerts.VERIFY_PERMISSIONS'
   );
END;


-- Run job:		exec DBMS_SCHEDULER.run_job('uis_utils.UTILS_RPT_PWD_EXPIRING');
-- Drop job:	exec DBMS_SCHEDULER.drop_job('uis_utils.UTILS_RPT_PWD_EXPIRING');
BEGIN
   DBMS_SCHEDULER.CREATE_JOB (
      job_name => 'uis_utils.UTILS_RPT_PWD_EXPIRING', job_type => 'PLSQL_BLOCK'
      , job_action		=> 'begin  uis_utils.alerts.RPT_EXPIRING_PASSWORDS;  end;'
      , start_date           => '11-FEB-19 6.31.00AM'
      , repeat_interval      => 'FREQ=DAILY; BYDAY=FRI' 
      , end_date             => NULL						-- '15-JAN-99 1.00.00AM US/Pacific',
      , enabled =>  TRUE,  comments => 'UTILS: alerts.RPT_EXPIRING_PASSWORDS'
   );
END;


-- ==========================  Code =====================================================

-- Define supporting objects here (since there is only 1 initially)
--
-- Bring together privileges granted via ROLEs and then directly via a SCHEMA grant;
-- ...used to initially populate uis_edw.ALL_TAB_PRIVS
--
grant select on dba_tab_privs to uis_utils;
grant select on role_tab_privs to uis_utils;
grant select on dba_role_privs to uis_utils;
grant select on dba_users to uis_utils;

-- create table uis_utils.ALL_VALID_PRIVS
--
create or replace view uis_utils.CUR_ALL_VALID_PRIVS
as
select  distinct  drp.grantee, rtp.owner, rtp.table_name, rtp.role as grantor, rtp.privilege, rtp.grantable, rtp.common
   , 'unknown' as obj_type, rtp.inherited, 'ROLE' as grant_type
from  ROLE_TAB_PRIVS  RTP  inner join  DBA_ROLE_PRIVS  DRP  on rtp.role = drp.granted_role
union
select  distinct  dtp.grantee, dtp.owner, dtp.table_name, dtp.grantor, dtp.privilege, dtp.grantable, dtp.common
   , dtp.type as obj_type, dtp.inherited, 'SCHEMA' as grant_type
from  DBA_TAB_PRIVS  DTP 
;
--
alter table uis_utils.ALL_VALID_PRIVS  add created_dt DATE default sysdate;
alter table uis_utils.ALL_VALID_PRIVS  add is_display varchar2( 1 ) default 'Y';

-- Make it easier to peruse the data set ...is_display = 'Y'
update uis_utils.ALL_VALID_PRIVS    set is_display= 'N' where grantee IN (
   'SYS','DBA','DEVELOPER_DICT_ROLE','EM_EXPRESS_BASIC','EXP_FULL_DATABASE','CWM_USER'
) or grantee LIKE 'APEX%';


/*
Pass in a table to rebuild 
*/
create or replace package uis_utils.alerts
as
	-- Find users/schemas granting permissions to objects they should not be.
	procedure verify_permissions;
	
	-- Validates/approves all permission diffferences noted in [verify_permissions] - careful
	-- ...hint: Run and then remove the 1 or 2 you did not want added;
	procedure validate_permissions;
	
	-- Report on password expirations...
	procedure rpt_expiring_passwords;

end alerts;
--
-- show errors


/* 

*/
set define off
--
create or replace package body  uis_utils.alerts
as
	-- =====================================================================================
	-- Report on privileges granted that are new (to find illegal ones
	--
	procedure rpt_expiring_passwords
	is
		rec_cnt				number := 0;
		msg_body			CLOB;
		pwd_rows			CLOB;				
		i_name				varchar2( 50 );
	begin
		
		-- Define set of new objects with privileges granted on them
		--		
		declare
			cursor pwd_cur  is
			   select lower( du.username ) username, du.expiry_date, trunc (du.expiry_date) - trunc (sysdate) as days2expire 
			   from DBA_USERS  DU 
			   where  du.account_status IN ('OPEN', 'EXPIRED')  AND du.username NOT IN ('SYS', 'SYSTEM', 'DBSNMP')  
			   and trunc (du.expiry_date) between trunc (sysdate)  and  ( trunc (sysdate) + 330 ) --  INTERVAL '300' DAY
			   order by du.expiry_date, du.username;
			a_rec	pwd_cur%rowtype;
		begin
			open pwd_cur;
			loop	
				fetch pwd_cur into a_rec;
				exit when pwd_cur%NOTFOUND;
				
				-- Build html table row/record...
				pwd_rows := pwd_rows ||'<tr><td>&nbsp;'|| a_rec.username ||'</td><td align=center>&nbsp;'|| a_rec.expiry_date ||'</td>'
				   ||'<td align=center>&nbsp;'
				   || a_rec.days2expire ||'</td></tr>';
			end loop;
		end;

		select instance_name into i_name  from v$INSTANCE;
		
		-- Preface message and begin and end the table...
		--
		if ( pwd_rows is NULL )
		then
		   msg_body := '<p><br/>The are no DB accounts with passwords set for expiring on [ <b>'|| i_name ||'</b> ].</p>';	   
		else
		   msg_body := '<p>The following is an order list of users by password expiring time for the DB instance [ <b>'
		   || i_name ||'</b> ].</p>'
		   ||'<table cellpadding="2" cellspacing="2" border="1" >'
		   ||'<tr><th colspan="3" align="center">Users with Passwords Expiring<br/><br/> </th></tr>'
		   ||'<tr><th>User</th><th>Expiration Date</th><th>Days Remaining</th></tr>'
		   || pwd_rows 
		   ||'</table><p>Once the number of users grows to be "unmanageable", then consider a lookup table to derive the owner''s email address.</p>';		
		end if;
		
		uis_utils.uis_sendmail.send_html( to_list => 'vhube3@uis.edu'
		-- uis_utils.uis_sendmail.send_html( to_list => 'UISappDevDL@uis.edu'
		   , subject => 'Alert - Password Expiration (for '|| i_name ||' on '|| to_char( sysdate, 'MM/DD/YYYY' ) ||')'
		   , body_of_msg => msg_body, group_id => 1001
		);
		
		EXCEPTION
		when others then
		   rollback;
		   dbms_output.put_line( SQLERRM ||': '|| SQLERRM );
		   	
	end rpt_expiring_passwords;
	
	-- =====================================================================================
	-- Report on privileges granted that are new (to find illegal ones
	--
	procedure verify_permissions
	is
		rec_cnt				number := 0;
		msg_body			CLOB;
		new_privs			CLOB;				
		i_name				varchar2( 50 );
	begin

		-- Remove entries no longer present in dictionary...
		--
		delete from ALL_VALID_PRIVS  where ( owner, table_name, grantee ) NOT IN (
		   select owner, table_name, grantee  from cur_ALL_VALID_PRIVS
		);
		
		select instance_name into i_name  from v$INSTANCE;
		
		-- Define set of new objects with privileges granted on them
		--		
		declare
			cursor diff_cur  is
		      select owner, table_name, grantee, grantor, privilege  from cur_ALL_VALID_PRIVS 
			  where ( owner, table_name, grantee ) NOT IN (
				select owner, table_name, grantee  from ALL_VALID_PRIVS
			);
			a_rec	diff_cur%rowtype;
		begin
			open diff_cur;
			loop	
				fetch diff_cur into a_rec;
				exit when diff_cur%NOTFOUND;
				
				-- Build html table row/record...
				new_privs := new_privs ||'<tr><td>&nbsp;'|| a_rec.privilege ||'</td><td>&nbsp;'|| a_rec.owner ||'</td><td>&nbsp;'
				   || a_rec.table_name ||'</td><td>&nbsp;'|| a_rec.grantee ||'</td><td>&nbsp;'|| a_rec.grantor ||'</td></tr>';
			end loop;
		end;

		-- Preface message and begin and end the table...
		--
		
		if ( new_privs is NULL )
		then
		   msg_body := '<p><br/>The were no new privileges granted to report on for DB [ <b>'|| i_name ||'</b> ].</p>';	   
		else
		   msg_body := '<p>The following DB objects have had privileges granted to them that have not been blessed for DB instance [ <b>'
		   || i_name ||'</b> ].</p>'
		   ||'<table cellpadding="2" cellspacing="2" border="1" >'
		   ||'<tr><th colspan="5" align="center">New Privileges Needing Verified <br/><br/> </th></tr>'
		   ||'<tr><th>Privilege</th><th>Owner</th><th>Object</th><th>Grantee</th><th>Grantor</th></tr>'
		   || new_privs ||'</table><p>If these entries are OK, you can remove them (bless them) by running [exec uis_utils.alerts.validate_permissions;].</p>';
		   
		end if;

		uis_utils.uis_sendmail.send_html( to_list => 'vhube3@uis.edu'
		   , subject => 'Alert - Permission Verification ('|| i_name ||':'|| to_char( sysdate, 'MM/DD/YYYY' ) ||')'
		   , body_of_msg => msg_body, group_id => 1001
		);
		
		EXCEPTION
		when others then
		   rollback;
		   dbms_output.put_line( SQLERRM ||': '|| SQLERRM );
		   	
	end verify_permissions;
	
	-- =====================================================================================
	-- Validate/approve privileges showing up in [verify_permissions]...
	--
	procedure validate_permissions 
	is
		msg_body			CLOB;
		new_privs			CLOB;				
		
	begin
	
		-- Define set of new objects with privileges granted on them
		--		
		declare
			cursor diff_cur  is
		      select owner, table_name, grantee, grantor, privilege, obj_type, grant_type, grantable, common, inherited
			  from cur_ALL_VALID_PRIVS 
			  where ( owner, table_name, grantee ) NOT IN (
				select owner, table_name, grantee  from ALL_VALID_PRIVS
			);
			a_rec	diff_cur%rowtype;
		begin
			open diff_cur;
			loop	
				fetch diff_cur into a_rec;
				exit when diff_cur%NOTFOUND;
				
				-- Valdiate/approve the permission by adding it to [ALL_VALID_PRIVS]
				-- ...object type would need to be looked up, dobable but not that important;
				--
				insert into ALL_VALID_PRIVS( 
				   owner, table_name, grantee, grantor, privilege, obj_type, grant_type, grantable, common, inherited
				)
				values(
				   a_rec.owner, a_rec.table_name, a_rec.grantee, a_rec.grantor, a_rec.privilege, a_rec.obj_type
				   , a_rec.grant_type, a_rec.grantable, a_rec.common, a_rec.inherited
				);

			end loop;
		end;
		
		EXCEPTION
		when others then
		   rollback;
		   dbms_output.put_line( SQLERRM ||': '|| SQLERRM );
		   	
	end validate_permissions;
	
end alerts;

-- show errors
