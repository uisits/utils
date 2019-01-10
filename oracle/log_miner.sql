-- https://docs.oracle.com/cd/B19306_01/server.102/b14215/logminer.htm#i1014720 

-- Data last only for the session you are in...
grant EXECUTE_CATALOG_ROLE  to system;  -- ...needed?

-- Need to enable supplemental logging...
--
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;
SELECT SUPPLEMENTAL_LOG_DATA_MIN FROM V$DATABASE;

-- 
-- Speficy LogMiner dictionary, to be stored in redo logs...vs flatfile
-- ...if the DB is not in ARCHIVE LOG mode, ORA-01325 will be thrown
--
exec DBMS_LOGMNR_D.BUILD( OPTIONS=> DBMS_LOGMNR_D.STORE_IN_REDO_LOGS);

-- DICT_FROM_ONLINE_CATALOG - use dictionaries in DB (online and archive mode);
-- CONTINUOUS_MINE for auto redo log creation for LogMiner;
--
ALTER SESSION SET nls_date_format='DD-MON-RRRR hh24:mi:ss';

exec dbms_logmnr.start_logmnr( starttime => '18-dec-2018 13:30:00', endtime => '18-dec-2018 14:05:00' \
   , OPTIONS => DBMS_LOGMNR.DICT_FROM_ONLINE_CATALOG + DBMS_LOGMNR.CONTINUOUS_MINE );

-- username = schema performing transaction;  seg_owner = owner of table;  os_username = OS user login
-- ...https://docs.oracle.com/cd/B28359_01/server.111/b28320/dynviews_2033.htm#REFRN30132 
--
select  distinct operation ||' : '|| username ||'.'|| table_name ||' ['||seg_owner||']'  from v$logmnr_contents
where seg_owner NOT IN ( 'SYS' );
--
select  count(0) ||' : '|| seg_owner ||'.'|| table_name  from v$logmnr_contents 
where seg_owner NOT IN ( 'SYS' )  group by seg_owner, table_name ;
--
exec sys.dbms_logmnr.end_logmnr();

-- Once you know you are through with the extra log data...
--
ALTER DATABASE DROP SUPPLEMENTAL LOG DATA;


-- Tables you will find:
-- ...prefaced with { wrh$ wri$ wrm$ sys } ...part of AWR: Automatic Workload Repository;
--
http://www.dba-oracle.com/oracle10g_tuning/t_awr_wri_wrm_wrh.htm

