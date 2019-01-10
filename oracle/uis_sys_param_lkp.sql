-- !!!!!!!!!!!!!!!!!!! DEPRECATED - see [GIT: TEAM/app_param_lkp.sql ]  !!!!!!!!!!!!!!!!!!!

create or replace view uis_utils.UIS_SYS_PARAM_LKP as 
select 
   PARAM_SEQ_NO, PARAM_ID, PARAM_CD, PARAM_NAME, PARAM_TYPE, PARAM_DESC, PARAM_VALUE
   , created_by as UIS_CREATED_BY,  created_dt as UIS_CREATED_DT,  delete_flg as UIS_DELETE_FLG
   , modified_by as UIS_MODIFIED_BY,  modified_dt as UIS_MODIFIED_DT,  source_sys_id as UIS_SOURCE_SYS_ID
from team.APP_PARAM_LKP  
;
grant select on team.APP_PARAM_LKP to DEPT_PRIVATE with grant option;
grant select on team.APP_PARAM_LKP to UIS_UTILS with grant option;
grant select on team.APP_PARAM_LKP to UIS_EDW with grant option;
--
grant select on UIS_UTILS.UIS_SYS_PARAM_LKP to dept_private;

-- For Oracle instances other than ORAPROD - e.g. ORADEPT;
--
create or replace  synonym  dept_private.UIS_SYS_PARAM_LKP  for uis_utils.UIS_SYS_PARAM_LKP;
