/*
File:	utils\sqlserver\pop_wdict_new_terms.sql

		Population of [msdb.dbo.wdict_acronym] primarily but also the other tables as well:
		
		{ wdict_general, wdict_preposition, wdict_conjunction }
		
See:	./wdict_tables.sql

Author: Vern Huber

Caveats / Things to Consider:
		
*/
USE msdb;

-- Create plural for certain words...
--
select * into dbo.wdict_general_bak from dbo.wdict_general;
-- ...for words ending in [b]:
insert into dbo.wdict_general ( word )  select word +'s' from dbo.wdict_general where word like '%r'	-- 383 added...
   and word + 's' not in ( select word from dbo.wdic_general );
   -- ...for words ending in [r]:
insert into dbo.wdict_general ( word )  select word +'s' from dbo.wdict_general where word like '%r'	-- 14083 added...
   and word + 's' not in ( select word from dbo.wdic_general );


-- Populate NEW or MISSING WORDs...
--
insert into dbo.wdict_general ( word ) values( 'illini' );
-- insert into dbo.wdict_general ( word ) values( 'we' );	-- removed by accident, as were: he, us, so, pi, fa 
   

-- Populate ACRONYMs...
--
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )
values( 'ADDS', 'Application Development and DB Support', 'Acronym for team in ITS at UIS responsible both custom and commercial applications as well as the DBs underlying these systems');
--
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )
values( 'SAGE', 'Students Allied For A Greener Earth', 'SAGE offers an opportunity for students, staff and faculty to become involved in the promotion of environmental awareness and
protection.  Membership is open to all members of the UIS community.');
--
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )
values( 'TRAC', 'The Recreation and Athletic Center', 'This 72,000 gross-square-foot  state-of-the-artfacility is managed by the Department of Campus Recreation and houses the
offices of UIS Intercollegiate Athletics (that opened in Fall 2007).');
--
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'SAB', 'Student Affairs Building', 'Student Affairs Building');
--
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )
values( 'ECCE', 'Engaged Citizenship Common Experience', 'All undergraduate students are required to take a minimum of 10 hours in the Engaged Citizenship Common Experience (ECCE).');
--
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )
values( 'AIS', 'Association for Integrative Studies', 'AIS - formerly the Association for Integrative Studies, 
is an interdisciplinary professional organization founded in 1979 to promote the interchange of ideas among scholars and administrators in all of the arts and sciences on intellectual and organizational issues related to furthering integrative studies.');
--
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )
values( 'EOM', 'Employee Of the Month', 'A program recognizing an individual employee for outstanding work and contribution(s) to
their employer.');
--
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )
values( 'SOFA', 'Student Organization Funding Association', 'SOFA is a standing committee of the Student Government Association (SGA).
As a guiding body for student organizations under the SGA, this committee looks to allocate University funds to student organizations
in a fair, unbiased, and efficient way, so as to promote student interaction and a positive learning environment on campus.');
--
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )
values( 'AIDS', 'Acquired Immunodeficiency Syndrome', 'AIDS is a disease that attacks the immune system');
--
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )
values( 'LEAD', 'Leadership, Exploration And Development', 'A program at UIS that promotes the
development of essential leadership qualities in our college graduates.');
-- 
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'LA', 'Los Angeles', 'Major city in California, U.S.A.');
--
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )
values( 'PAC', 'Public Affairs Center', 'One of the major buildings on the UIS campus that is typically used to host public events.');
--
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'US', 'United States', 'Shortened acronym for U.S.A.');
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'USA', 'United States of America', 'Acronym for U.S.A.');
--
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )
   values( 'ABC', 'Alphabet Sequence', 'Acronym for the steps of a process equating it to the start of the alphabet (See also ABCs)');
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )
   values( 'ABCs', 'UAlphabet Sequence', 'Acronym for the steps of a process equating it to the start of the alphabet (See also ABC)');
--
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )
values( 'SCAIC', 'Student Chapter of Association for Information Systems', 'An official student chapter of AIS');
--
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )
values( 'APA', 'American Psychological Association', 'Organization established to act on/address pschological concerns');
--
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )
values( 'vs', 'Short for verses', 'Added to the acronym list to keep the lower case setting.');
--
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )
values( 'ITS', 'Information Technology', 'Common term for a field of interest relating to the processing of information.');
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )
values( 'ITS', 'Information Technology Services', 'Organization at UIS dealing with IT and Media support.');
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )
values( 'CITES', 'Campus Information Technology and Educational Services', 'Organization at UIUC dealing with IT and Media support.');
--
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )
values( 'MIS', 'Management Information Systems', 'MIS is a department in the College of Business and Management at UIS 
with a focus on the application of information technology to solving business problems.');

-- these 4 requrested by Sadie Furman on 11/21/2016
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'MBA', 'Master''s in Business Administration', 'TBD');
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'BBA', 'Bachelor''s in Business Administration', 'TBD');
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'LEG', 'TBD', 'TBD');
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'MKT', 'TBD', 'TBD');

--
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )
values( 'RSVP', 'Réserve Si Vous Plaira', 'From French - requesting folks to "Reply if you please".');
--
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )
values( 'EZ', 'EZ', 'To correct for:  Quik-n-EZ');
--
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'PM', 'Post Meridiem', 'Latin for after noon.');
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'AM', 'Ante Meridiem', 'Latin for before noon.');
--
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )
values( 're', 'Contraction for "are"', 'Fitting solution to prevent Camel Case for contractions of "are".');
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )
values( 't', 'Contraction', 'Fitting solution to prevent Camel Case for contraction of "not".');
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )
values( 's', 'Posessive', 'Fitting solution to prevent Camel Case for article possesion.');
--
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'SAC', 'Student Activities Committee', 'Student Activities Committee');
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'ASB', 'Alternative Spring Break', 'Alternative Spring Break');
delete from dbo.wdict_general where word = 'asb';
--
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'HR', 'Human Resources', 'Human Resources - department withhin an organization dealing with high level personnel management related items');
delete from dbo.wdict_general where word = 'hr';
--
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'MLK', 'Martin Luther King', 'Martin Luther King, Jr - sometimes used to refer to the U.S. Holiday.');
--
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'CAPE', 'Chancellor''s Academic Professional Excellence Award'
   , 'Chancellor''s Academic Professional Excellence Award honors all Academic Professionals at UIS by recognizing one outstanding AP each year.');
--
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'SWV', 'Sister''s With Vision'
   , 'To be completed.');
--



delete from dbo.wdict_general where word = 'asb';
--
delete from dbo.wdict_general where upper(word) in ( 'NBC', 'CBS' ) ;  -- 'ABC' , 'WCIA', 'WUIS' ) ;

-- ...State and 2 letter abbreviations...
delete from dbo.wdict_general where LOWER(word) in ( 
 'a1','aa','ab','ac','ad','ae','af','ag','ah','ai','ak','al','am','ap','aq','ar','av','aw','ax','ay','az'
,'ba','bb','bd','bf','bg','bi','bk','bl','bm','bn','bo','bp','br','bs','bt','bu','bv','bx','bz'
,'cb','cc','cd','ce','cf','cg','ch','ck','cl','cm','co','cp','cq','cr','cs','ct','cu','cv','cy'
,'d','da','db','dc','dd','de','dg','di','dj','dk','dl','dm','dn','dp','dr','ds','dt','du','dx','dy','dz'
,'ea','ec','ee','ef','eh','em','en','eo','ep','eq','er','es','et','eu','ew','ex','ey'
,'fa','fb','fc','fe','ff','fg','fi','fl','fm','fn','fo','fp','fr','fs','ft','fu','fv','fw','fy','fz'
,'ga','gd','ge','gi','gl','gm','gn','gp','gr','gs','gt','gu','gv'
,'ha','hb','hd','hf','hg','hl','hm','hp','hq','hs','ht','hv','hw','hy'
,'ia','ib','ic','id','ie','ii','ik','il','im','io','iq','ir','iv','iw','ix'
,'ja','jg','jo','jr','js','jt','ka','kb','kc','kg','ki','kl','km','kn','ko','kr','kt','kv','kw','ky'
,'lb','lc','ld','le','lf','lg','lh','li','ll','lm','ln','lo','lp','lr','ls','lt','lu','lv','lx','ly'
,'ma','mb','mc','md','me','mf','mg','mh','mi','mk','ml','mm','mn','mo','mp','mr','ms','mt','mu','mv','mw','my'
,'na','nb','nd','ne','ng','ni','nj','nl','nm','np','nr','ns','nt','nu','nv','ny'
,'ob','oc','od','oe','og','ol','om','op','os','ot','ow','oy'
,'pa','pc','pd','pe','pf','pg','ph','pi','pk','pl','pm','po','pp','pq','pr','ps','pt','pu'
,'qe','qh','ql','qm','qn','qp','qr','qs','qt','qu','qv','qy','ra','rc','rd','rf','rg','rh','rm','rn','ro','rs','rt'
,'sa','sb','sc','sd','se','sf','sg','sh','si','sk','sl','sm','sn','sp','sq','sr','ss','st','su','sv','sw'
,'t','ta','tb','tc','te','tg','th','ti','tk','tm','tn','tp','tr','ts','tu','tv','tx'
,'uc','ug','ui','um','un','ur','ut','ux','va','vb','vc','vd','vg','vi','vl','vo','vp','vr','vs','vt','vv'
,'w/','wa','wb','wc','wd','wf','wg','wh','wi','wk','wl','wm','wo','wr','ws','wt','wy','xc','xd','xi','xr','xs','xu','xw','xx'
,'ya','yd','ye','yi','ym','yn','yo','yr','ys','yt','za','zn','zo','zs'
);
-- 2 letter abbreviations that are also words...
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'IS', 'Iceland', 'Iceland ISO abbreviation');
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'IN', 'Indiana', 'Indiana state abbreviation');
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'PI', 'TBD', 'PI the acronym has a lot of different meanings');
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'SO', 'TBD', 'SO the acronym has a lot of different meanings');
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'FA', 'TBD', 'FA can be an acronym for a number of things');

-- Terrorist groups...
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'ISIS', 'ISIS', 'Islamic State in Iraq and Syria - terrorist group');
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'ISIL', 'ISIL', 'Islamic State of Iraq and the Levant - terrorist group');

-- St: Street, Saint, ...
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'St', 'St', 'Acronym for Street, Saint, etc.');


-- Misc groups...
use msdb
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'TFSE', 'TFSE', 'Therkildsen Field Station at Emiquon');

insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( '#NCSAM ', '#NCSAM ', 'National Cyber Security Awareness Month');
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'NCSAM ', 'NCSAM ', 'National Cyber Security Awareness Month');
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'NCSA ', 'NCSA', 'National Center for Supercomuting Applications');
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'COPE-L', 'COPE-L', 'Community of Practice for eLearning (COPE-L) and COLRS');
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'COPEL', 'COPE-L', 'Community of Practice for eLearning (COPE-L) and COLRS');
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'COPE', 'COPE-L', 'Community of Practice for eLearning (COPE-L) and COLRS');


use msdb
select * from dbo.wdict_words where lower(word) in ( 'am');
select * from dbo.wdict_acronym where lower(acronym) in ( 'st');


-- commit
alter table msdb.dbo.wdict_general alter column word  varchar(100) collate Latin1_General_CS_AS  not null;  -- Make Case Sensitive
alter TABLE msdb.dbo.wdict_general ADD  CONSTRAINT UNQ_wdict_general  UNIQUE NONCLUSTERED ( word ASC );	   -- ...add back PK using UNQ


-- Populate College acronyms - e.g. BIO, ENG, ...
begin transaction pop_acronyms;


insert into msdb.dbo.wdict_acronym ( acronym, short_name, acronym_desc )
select distinct crs_subj_cd, crs_subj_cd, 'TBD'
   from dbo.COURSES_ALL where CRS_SUBJ_CD not in ( select acronym from msdb.dbo.wdict_acronym ); 

-- commit transaction pop_acronyms;  rollback transaction pop_acronyms;

-- Numbering suffixes...
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'st', 'Numbering Suffix', 'Numbering Suffix');
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'nd', 'Numbering Suffix', 'Numbering Suffix');
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'rd', 'Numbering Suffix', 'Numbering Suffix');
insert into dbo.wdict_acronym ( acronym, short_name, acronym_desc )  values( 'th', 'Numbering Suffix', 'Numbering Suffix');

-- Deprovision acronyms from the General word list, so they come thru or default as an ACRONYMs
--
delete from dbo.wdict_general where word = 'adm';


