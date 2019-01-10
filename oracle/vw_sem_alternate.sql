/*
File:	utils/oracle/vw_sem_alternate.sql  *** DEPRECATED ***

		VH 20170727 : Relocated physical definition of the object to UIS_EDW
		  ...so as to remove cross schema dependency (make things point back to UIS_EDW).
		  
		SEE: CDM/all/all_semesters.sql - for definition

Desc:	An ALTERNATE single record view (vs. the more widely used one [vw_semester]) for
		determining what the current semester is using the following windows of time:
		
		Jan. 10 - May 31:  Spring Semester
		June  1 - Aug. 15: Summer Semester
		Aug. 16 - Jan. 9:  Fall Semester
		
		Users of this definition of when a semester starts:
		
		* Student Insurance (STUINS) - See [ uis_utils.vw_sem_STUINS ]
		
		* Trac / Recreational Sports - See [ uis_utils.vw_sem_TRAC ]
		
		Both STUINS and Trac could reference the alternate view directly and things would
		work, but if a change was ever needed then a coding change would also be needed.
		By dereferencing things in this way, only one view needs to be modified.

See:	[ utils/oracle/vw_semester.sql ] - Commonly used current semester view.		
		[ utils/sqlserver/vw_sem_alternate.sql ] - SQL Server counterpart utility.
		
		[ CDM/all/all_semesters.sql ] - was used for declaring specific privileges, but this object is public.
		
Enhancements:
		
Usage:	select current_term from uis_utils.VW_SEM_ALTERNATE;

Author: Vern Huber
*/

