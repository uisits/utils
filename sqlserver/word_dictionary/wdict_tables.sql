/*
File:	utils\sqlserver\wdict_tables.sql

		Tables to hold word dictionaries -
		
		wdict_words :	General words.
		
		wdict_conjuction :	Words which are conjuction 
		
		wdict_prepositon : 	Words which are prepositons.
		
See:	./pop_wdict_acronym.sql: for population of acronym set.

Author: Vern Huber

Caveats / Things to Consider:
		
*/
USE msdb;

CREATE TABLE dbo.wdict_general (
	word			nvarchar(100) not null,		-- Unique word
	CONSTRAINT pk_wdict_general PRIMARY KEY CLUSTERED (
		word ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF
	  , ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
);
--
alter table msdb.dbo.wdict_general alter column word  varchar(100) collate Latin1_General_CS_AS  not null;  -- Make Case Sensitive
alter table msdb.dbo.wdict_general ADD  CONSTRAINT UNQ_wdict_general  UNIQUE NONCLUSTERED ( word ASC );	   -- ...add back PK using UNQ

CREATE TABLE dbo.wdict_conjunction (
	word			nvarchar(100) not null,		-- Unique word
	CONSTRAINT pk_wdict_conjunction PRIMARY KEY CLUSTERED (
		word ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF
	  , ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
);
--
alter table msdb.dbo.wdict_conjunction alter column word  varchar(100) collate Latin1_General_CS_AS  not null;  -- Make Case Sensitive
alter table msdb.dbo.wdict_conjunction ADD  CONSTRAINT UNQ_wdict_conjunction  UNIQUE NONCLUSTERED ( word ASC );	   -- ...add back PK using UNQ


CREATE TABLE dbo.wdict_preposition (
	word			nvarchar(100) not null,		-- Unique word
	CONSTRAINT pk_wdict_preoposition PRIMARY KEY CLUSTERED (
		word ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF
	  , ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
);
--
alter table msdb.dbo.wdict_preposition alter column word  varchar(100) collate Latin1_General_CS_AS  not null;  -- Make Case Sensitive
alter table msdb.dbo.wdict_preposition ADD  CONSTRAINT UNQ_wdict_preposition  UNIQUE NONCLUSTERED ( word ASC );	   -- ...add back PK using UNQ

-- Table for acronyms...
--
CREATE TABLE dbo.wdict_acronym (
	acronym			nvarchar(100) 	not null		-- Unique word
	, short_name	nvarchar(250) 	not null
	, acronym_desc	nvarchar(1000)
	, is_active 	nvarchar(1) 	not null default 'Y';
	, CONSTRAINT pk_wdict_preoposition PRIMARY KEY CLUSTERED (
		acronym ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF
	  , ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
);
grant select on dbo.wdict_acronym  to public;
--
alter table msdb.dbo.wdict_acronym alter column acronym  varchar(100) collate Latin1_General_CS_AS  not null;  -- Make Case Sensitive
alter TABLE msdb.dbo.wdict_acronym  ADD  CONSTRAINT UNQ_wdict_acronym  UNIQUE NONCLUSTERED ( acronym ASC );	   -- ...add back PK using UNQ

-- Get rid of duplication...
--
delete from dbo.wdict_general where word in ( select word from dbo.wdict_conjunction );   -- 29 records removed.
delete from dbo.wdict_general where word in ( select word from dbo.wdict_preposition );   -- 99 records removed.

-- Pull them together...
--
alter view dbo.wdict_words  as 
   select word, 'general' as word_type  from dbo.wdict_general 
   union
   select word, 'conjunction' as word_type  from dbo.wdict_conjunction
   -- select word, 'general' as word_type  from dbo.wdict_conjunction
   union
   select word, 'preposition' as word_type  from dbo.wdict_preposition  -- override so we get Camel BACKUP
   -- select word, 'general' as word_type  from dbo.wdict_preposition
   union
   select acronym as word, 'acronym' as word_type  from dbo.wdict_acronym where is_active = 'Y'
;

-- Uniqueness?
select word, COUNT(0) from dbo.wdict_words group by word having COUNT(0) > 1;

-- Grant permissions to read tables...
--
grant select on dbo.wdict_words  to public;
