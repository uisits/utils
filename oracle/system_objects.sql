/* 
File:	utils/oracle/system_objects.sql 
 
Desc:	Objects commonly needed by folks and/or utilities involving the [system] ac count.
		
		Defined in [uis_utils]
		
Utilities:	
		get_storage_metrics( send_to ) => generates usage and sends the results in email.
		
See:	./system_utils.sql
	
Author:	Vern Huber - May 16, 2022

Enhancements:
		TBD
		
*/
-- Privileges needing granted by SYS to UIS_UTILS
--
grant select on  DBA_FREE_SPACE  to uis_utils;
grant select on  DBA_DATA_FILES  to uis_utils;
grant select on  V_$PARAMETER  to uis_utils;
grant select on  V_$INSTANCE  to uis_utils;

--
create or replace view  uis_utils.STORAGE_METRICS
as
select f.tablespace_name, to_char ( ( t.total_space - f.free_space),'999,999')	as used_space
, to_char ( f.free_space, '999,999' )  as free_space,  to_char ( t.total_space, '999,999' )  as total_space
, to_char ( ( round( ( f.free_space / t.total_space ) *100 ) ),'999') ||' %'  as percent_free
from   (
   select  TABLESPACE_NAME, round( SUM( BLOCKS * ( select value/1024    from  V$PARAMETER  where name = 'db_block_size') / 1024 ) 
   ) free_space
   from DBA_FREE_SPACE  group by TABLESPACE_NAME
) F
inner join (
   select TABLESPACE_NAME, round( SUM( BYTES / 1048576 ) ) as total_space
   from DBA_DATA_FILES  group by TABLESPACE_NAME
) T
   on f.TABLESPACE_NAME = t.TABLESPACE_NAME
;

