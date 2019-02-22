/* 
File:	utils/oracle/misc_utils.sql 
 
Desc:	Oracle utilities commonly needed across applications;
		
NOTE:	

See:	
	
Author:	Vern Huber - Feb. 22, 2019  

Enhancements:
		TBD
		
*/

-- term_to_semester: pass in a term_cd (6 digits) and get back a semester (5 ditits)
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
				
-- semester_to_term: pass in a semester (5 ditits) and get back a term_cd (6 digits)
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

	