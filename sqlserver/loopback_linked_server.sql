/*
File:	utils\sqlserver\loopback_linked_server.sql

Desc:	Scripts needed for creating a loopback linked server.

		This is useful for performing autonomous actions (transactions if you wanted).
		
		E.g. [ uis_sendmail ] uses this capability to send emails independent of
		the transaction the send request is made from.

E.g.:	exec loopback.msdb.dbo.<some procedure> arg1, ...,argX
		
See:	[ utils\sqlserver\uis_sendmail.sql ]
		
Author: Vern Huber

Caveats / Things to Consider:
		
*/

-- Create the LOOPBACK Linked Server
USE MASTER
GO
EXEC sp_addlinkedserver @server = N'loopback',@srvproduct = N' ',@provider = N'SQLNCLI', @datasrc = @@SERVERNAME
GO
EXEC sp_serveroption loopback,N'remote proc transaction promotion','FALSE'
Go

-- Configure RPC on the servers
sp_helpserver
exec sp_serveroption @server=@@servername, @optname='rpc', @optvalue='true'
exec sp_serveroption @server=@@servername, @optname='rpc out', @optvalue='true' 

-- ...don't forget [loopback] server created above.
exec sp_serveroption @server='loopback', @optname='rpc', @optvalue='true'
exec sp_serveroption @server='loopback', @optname='rpc out', @optvalue='true' 
