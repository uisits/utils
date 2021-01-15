/* 
File:	utils/oracle/misc_utils.sql 
 
Desc:	Oracle utilities commonly needed across applications;
		
Utilities:	
		uis_utils.term_to_semester( term_cd )
		uis_utils.semester_to_term( semester ) 
		uis_utils.is_online_crs( sched_type_cd )  ==> true, false
See:	
	
Author:	Vern Huber - Feb. 22, 2019  

Enhancements:
		TBD
		
*/

-- TERM_TO_SEMESTER: pass in a term_cd (6 digits) and get back a semester (5 ditits)
-- ...420198 --> 20193  (1: Spring;  2: Summer;  3: Fall;)
-- ...BB uses this format at times.
--
-- E.g.:   select   uis_utils.term_to_semester( '420195' )  as sem   from dual;
--
create or replace FUNCTION  uis_utils.term_to_semester( term_cd  IN VARCHAR2 ) 
   return VARCHAR2  AS semester  VARCHAR2( 5 ); 
BEGIN 
   semester := case 
      when substr( term_cd, 6,1 ) = '1'  then  substr( term_cd, 2,4 ) ||'1' 
  	  when substr( term_cd, 6,1 ) = '5'  then  substr( term_cd, 2,4 ) ||'2'
	  else  substr( term_cd, 2,4 ) ||'3'
   end;
    
  return semester; 
END;
--
grant execute on uis_utils.term_to_semester  to public;
				
-- SEMESTER_TO_TERM: pass in a semester (5 ditits) and get back a term_cd (6 digits)
-- ...20193 --> 420198  (1: Spring;  5: Summer;  8: Fall;)
--
-- E.g.:   select   uis_utils.semester_to_term( '20192' )  as term_cd   from dual;
--
create or replace FUNCTION  uis_utils.semester_to_term( semester  IN VARCHAR2 ) 
   return VARCHAR2  AS term_cd  VARCHAR2( 6 ); 
BEGIN 

   term_cd  := case   
      when ( substr( semester,5,1 ) = '2') then '4'|| substr( semester,1,4 )||'5'
      when ( substr( semester,5,1 ) = '3') then '4'|| substr( semester,1,4 )||'8' 
      else '4'|| semester    
   end;
  
  return term_cd; 
END;
--
grant execute on uis_utils.semester_to_term  to public;

			
-- IS_ONLINE_CRS: pass in a [SCHED_TYPE_CD](3 chars) and get back { true, false } literals
-- ...retrieved from (commonly): T_Sect_Base.sched_type_cd - and there are over 40 of them;
--
-- E.g.: select uis_utils.is_online_crs( 'ONL' ) from dual;
--
create or replace FUNCTION  uis_utils.is_online_crs( sched_type_cd  IN VARCHAR2 ) 
   return VARCHAR2  AS online_flag  VARCHAR2( 5 ); 
BEGIN 

   online_flag  := case   
      when (substr( sched_type_cd, 1, 1) = 'E')   then 'true'
	  when ( sched_type_cd = 'ONL')               then 'true'
      else 'false'
   end;
  
  return online_flag; 
END;
--
grant execute on uis_utils.is_online_crs  to public;
    
			
-- GET_SCHED_METHOD: pass in a [SCHED_TYPE_CD](3 chars) and get back { ONLINE, ONGROUND } literals
-- ...retrieved from (commonly): T_Sect_Base.sched_type_cd - and there are over 40 of them;
--
-- Course Evaluations was initial user of this scheme - maybe the only one, and was checking for sched_type_cd:
--    Online <== ONL,E8,E9,E7,E1,E5,E4,E3,E2,E6
--    Onground <== CLP,STA,DIS,N1,IND,N2,N3,N4,LAB,LBD,L1,LEC,S4,S5,S1,S2,S3,LCD,CNF,ST,Q,P2,P3,PR,P1,PKG
--
-- See: uis_utils.is_onlince_crs();
-- 		edw.T_SCHED_TYPE_CD
--
-- E.g.: select uis_utils.is_online_crs( 'ONL' ) from dual;
--
create or replace FUNCTION  uis_utils.get_sched_method( sched_type_cd  IN VARCHAR2 ) 
   return VARCHAR2  AS r_sched_method  VARCHAR2( 10 ); 
BEGIN 

   r_sched_method  := case   
      when (substr( sched_type_cd, 1, 1) = 'E')   then 'ONLINE'
	  when ( sched_type_cd = 'ONL')               then 'ONLINE'
      else 'ONGROUND'
   end;
  
  return r_sched_method; 
END;
--
grant execute on uis_utils.get_sched_method  to public;
    

			
-- GET_SESS_METHOD: pass in a [SCHED_TYPE_CD](3 chars) and get back { ONLINE, MIXED } literals
-- ...retrieved from (commonly): T_Sect_Base.sched_type_cd - and there are over 40 of them;
--
-- Course Evaluations was initial user of this scheme - maybe the only one, and was checking for SESS_CD:
--    Online <== O
--    Onground <== B,C,V,L,I
--
-- See: uis_utils.is_onlince_crs();
--		edw.T_SESS_CD
--
-- E.g.: select uis_utils.is_online_crs( 'ONL' ) from dual;
--
create or replace FUNCTION  uis_utils.get_sess_method( sess_cd  IN VARCHAR2 ) 
   return VARCHAR2  AS r_sess_method  VARCHAR2( 10 ); 
BEGIN 

   r_sess_method  := 'MIXED';
   
   if ( sess_cd = 'O' )
   then  
		r_sess_method := 'ONLINE';
   end if;
  
  return r_sess_method; 
END;
--
grant execute on uis_utils.get_sess_method  to public;


			
-- IS_NUMBER: Check if string is numeric.
-- ...returns {0} : if string is not numeric;
-- ...returns {1} : if number - as determined by [ to_number ];
--
-- E.g.: case when uis_utils.is_number( '21345.56' ) = 1  then ... else ... end;
--
create or replace function  uis_utils.IS_NUMBER( str_nbr	in varchar2 )
  RETURN INT
IS
  is_nbr	NUMBER;
BEGIN
   is_nbr := to_number(str_nbr);
   return 1;
  
EXCEPTION
   WHEN VALUE_ERROR THEN
   return 0;
   
END; 	-- uis_utils.IS_NUMBER;
--
grant execute on uis_utils.IS_NUMBER  to public;

   
-- GET_NUMBER: Accepts a string as input and returns a numeric as the result.
-- ...returns {0} if string is not numeric;
-- ...returns [to_number( str )] otherwise;
--
-- NOTE: Simple formatting is removed: commas and dollar sign ($)
--
-- E.g.: select uis_utils.get_number( '21345.56' ) from dual;
-- ...or select uis_utils.get_number( '$1,234.56' ) from dual;
-- 

create or replace function  uis_utils.GET_NUMBER( 
   str_nbr		in VARCHAR2
   , fmt		in VARCHAR2		default NULL
)  return NUMBER
is 
  r_number 			NUMBER := 0;
  str_nbr_prep		VARCHAR2( 1000 );

BEGIN  
   -- strip out commas and dollar sign ($)...
   str_nbr_prep := replace( replace( str_nbr, ',', NULL ), '$', NULL );

   if ( uis_utils.is_number( str_nbr_prep) = 0 )
   then
      return r_number;
   end if; 
	     
   if ( fmt is null )
   then  
		r_number := to_number( str_nbr_prep );
   else 
		r_number := to_number( str_nbr_prep, fmt );
   end if;
  
  return r_number; 
  
END ;		-- uis_utils.GET_NUMBER;
--
grant execute on uis_utils.GET_NUMBER  to public;

