/*
File:	utils/oracle/campus.sql  (depending on what this name remains as - e.g. Campus_Affiliation)

Desc:	Table for holding variable information needed by applications that tends
		to differ between platforms (dev/test/prod) - and you don't want to 
		hardcode the settings.
		
		Really belongs in the CDM repo, but is provided here for sharing purposes.
		
See:	utils/oracle/pop_uis_sys_param_lkp.sql for populating entries in this table.

Author: Vern Huber

Caveats / Things to Consider:

		Entries here need to consider the SQL Server equivalent code at [ utils/sqlserver ].
*/

CREATE TABLE uis_edw.Campus_Affiliation
  (
    campusID INTEGER NOT NULL ,
    acronym  VARCHAR2 (10) ,
    name     VARCHAR2 (100)
  ) ;
ALTER TABLE uis_edw.Campus_Affiliation ADD CONSTRAINT Campus_PK PRIMARY KEY ( campusID ) ;
ALTER TABLE uis_edw.Campus_Affiliation ADD CONSTRAINT UNQ_Campus_acronym UNIQUE ( acronym ) ;
ALTER TABLE uis_edw.Campus_Affiliation ADD CONSTRAINT UNQ_Campus_name UNIQUE ( name ) ;

insert into uis_edw.Campus_Affiliation ( campusID, acronym, name ) values( 1, 'UIUC', 'University of Illinois at Urbana-Champaign');
insert into uis_edw.Campus_Affiliation ( campusID, acronym, name ) values( 2, 'UIC', 'University of Illinois at Chicago');
insert into uis_edw.Campus_Affiliation ( campusID, acronym, name ) values( 4, 'UIS', 'University of Illinois at Springfield');
insert into uis_edw.Campus_Affiliation ( campusID, acronym, name ) values( 9, 'UA', 'University Administration');
--
insert into uis_edw.Campus_Affiliation ( campusID, acronym, name ) values( 99, 'TBD', 'To Be Determined');
--
-- Core Affiliations by Campus...
--
insert into uis_edw.Campus_Affiliation ( campusID, acronym, name ) values( 100, 'UIUC F/S', 'UIUC Faculty/Staff');
insert into uis_edw.Campus_Affiliation ( campusID, acronym, name ) values( 200, 'UIC F/S', 'UIC Faculty/Staff');
insert into uis_edw.Campus_Affiliation ( campusID, acronym, name ) values( 400, 'UIS F/S', 'UIS Faculty/Staff');
insert into uis_edw.Campus_Affiliation ( campusID, acronym, name ) values( 900, 'UA F/S', 'UA Faculty/Staff');
--
insert into uis_edw.Campus_Affiliation ( campusID, acronym, name ) values( 1000, 'UIUC HSG', 'UIUC Housing');
insert into uis_edw.Campus_Affiliation ( campusID, acronym, name ) values( 2000, 'UIC HSG', 'UIC Housing');
insert into uis_edw.Campus_Affiliation ( campusID, acronym, name ) values( 4000, 'UIS HSG', 'UIS Housing');
insert into uis_edw.Campus_Affiliation ( campusID, acronym, name ) values( 9000, 'UA HSG', 'UA Housing');

--
-- Non-Core Campus affiliations...
--
insert into uis_edw.Campus_Affiliation ( campusID, acronym, name ) values( 4001, 'LLCC HSG', 'Housing for Lincoln Land Community College');
insert into uis_edw.Campus_Affiliation ( campusID, acronym, name ) values( 4002, 'Other HSG', 'Housing for Other');
insert into uis_edw.Campus_Affiliation ( campusID, acronym, name ) values( 4003, 'F/S HSG', 'Housing for UIS Faculty/Staff');
insert into uis_edw.Campus_Affiliation ( campusID, acronym, name ) values( 4004, 'ESL HSG', 'Housing for English as a Second Language (ESL)program');

-- Table for holding instances of a person's affiliation (since it can be many to one).
CREATE TABLE uis_edw.Campus_Affiliation_Instance
(
    campusID		integer 		not null,
    personID		varchar2(128)	not null,			-- was specifically [email_addr] - allow for multiple types of keys.
	personID_type	varchar2(10)	not null,
    max_term_cd     varchar2(6)		default '999999'	-- A specific term_cd or [999999] for matching any term_cd
	min_term_cd     varchar2(6)		default '420151'	-- Picking some term code;  If important set to term instance is to become effective.
) ;
ALTER TABLE uis_edw.Campus_Affiliation_Instance ADD CONSTRAINT PK_Campus  PRIMARY KEY ( campusID, personID, personID_type ) ;

alter table uis_edw.Campus_Affiliation_Instance ADD CONSTRAINT FK_CAI_Campus_Affiliation  FOREIGN KEY ( campusID )   
   References uis_edw.Campus_Affiliation ( campusID );
   
alter table uis_edw.Campus_Affiliation_Instance  ADD CONSTRAINT CHK_CAI_personID_Type  check ( personID_type in ( 'UIN', 'EDWPERSID', 'EMAIL') );
