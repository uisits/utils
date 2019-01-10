/*
File:	utils/oracle/vw_semester.sql  *** DEPRECATED ***

		VH 20170727 : Relocated physical definition of the object to UIS_EDW
		  ...so as to remove cross schema dependency (make things point back to UIS_EDW).
		  
		SEE: CDM/all/all_semesters.sql - for definition
		
		  
Desc:	Single record view for providing access to common semester/term codes.

Note:	Some re-working may need to occur depending on when a term is no longer
		considered current.
		
See:	[ utils/sqlserver/vw_semester.sql ] - SQL Server counterpart utility.		
		[ utils/oracle/vw_sem_alternate.sql ] - different semester window definition;
		
		[ CDM/all/all_semesters.sql ] - for privileges and synonyms relating to this object.
		
Enhancements:
		* Have the SQL Server view call this one (so logic is in one place).
		
		* VH 20140725 : Added [ academic_year ] as yy1yy2 (e.g. 1314)
		
		* VH 20150514 : Added cur_/next_/prev_sem_code;  E.g. 1, 8 or 5
		
Usage:	select current_term from uis_utils.vw_semester

Author: Vern Huber
*/
-- select * from uis_utils.vw_semester ;

