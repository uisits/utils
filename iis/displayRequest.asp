<!DOCTYPE html SYSTEM "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<title>Display Request</title>
	</head>
	<body>
	<h1>Display Request</h1>
	<h4><a href="https://dev.auth.uillinois.edu/logout/sm_logout.fcc">Development Log Off Link</a></h4>
	<h4><a href="https://test.auth.uillinois.edu/logout/sm_logout.fcc">Test Log Off Link</a></h4>	
	<h4><a href="https://auth.uillinois.edu/logout/sm_logout.fcc">Production Log Off Link</a></h4>
		Remote Host: <%= Request.ServerVariables("REMOTE_HOST") %><BR>
		Server Name: <%= Request.ServerVariables("SERVER_NAME") %><BR>
			<TABLE style="background-color: #ECE5B6;" WIDTH="100%" border="1">
				
				<tr>
					<th>method used to send request</th>
					<td><%= Request.ServerVariables("REQUEST_METHOD") %></td>
				</tr>
				
				<tr>
					<th>URI of the request</th>
					<td><%= Request.ServerVariables("PATH_TRANSLATED") %></td>
				</tr>
				
				<tr>
					<th>path info</th>
					<td><%= Request.ServerVariables("PATH_INFO") %></td>
				</tr>
				
				<tr>
					<th>remote host</th>
					<td><%= Request.ServerVariables("REMOTE_HOST") %></td>
				</tr>
				
				<tr>
					<th>server name</th>
					<td><%= Request.ServerVariables("SERVER_NAME") %></td>
				</tr>
				
				<tr>
					<th>user-agent</th>
					<td><%= Request.ServerVariables("HTTP_USER_AGENT") %></td>
				</tr>
				
				<tr>
					<th>accept</th>
					<td><%= Request.ServerVariables("HTTP_ACCEPT") %></td>
				</tr>
				
				<tr>
					<th>https</th>
					<td><%= Request.ServerVariables("HTTPS") %></td>
				</tr>
				
				<tr>
					<th>accept-language</th>
					<td><%= Request.ServerVariables("HTTP_ACCEPT_LANGUAGE") %></td>
				</tr>
				
				<tr>
					<th>accept-encoding</th>
					<td><%= Request.ServerVariables("HTTP_ACCEPT_ENCODING") %></td>
				</tr>
				
				<tr>
					<th>connection</th>
					<td><%= Request.ServerVariables("HTTP_CONNECTION") %></td>
				</tr>
				
				<tr>
					<th>SM_TRANSACTIONID</th>
					<td><%= Request.ServerVariables("HEADER_SM_TRANSACTIONID") %></td>
				</tr>
				
				<tr>
					<th>SM_SDOMAIN</th>
					<td><%= Request.ServerVariables("HEADER_SM_SDOMAIN") %></td>
				</tr>
				
				<tr>
					<th>SM_REALM</th>
					<td><%= Request.ServerVariables("HEADER_SM_REALM") %></td>
				</tr>
				
				<tr>
					<th>SM_REALMOID</th>
					<td><%= Request.ServerVariables("HEADER_SM_REALMOID") %></td>
				</tr>
				
				<tr>
					<th>SM_AUTHTYPE</th>
					<td><%= Request.ServerVariables("HEADER_SM_AUTHTYPE") %></td>
				</tr>
				
				<tr>
					<th>SM_AUTHREASON</th>
					<td><%= Request.ServerVariables("HEADER_SM_AUTHREASON") %></td>
				</tr>
				
				<tr>
					<th>UIN</th>
					<td><%= Request.ServerVariables("HEADER_UIN") %></td>
				</tr>
				
				<tr>
					<th>DISPLAY_NAME1</th>
					<td><%= Request.ServerVariables("HEADER_DISPLAY_NAME1") %></td>
				</tr>
				
				<tr>
					<th>DISPLAY_NAME2</th>
					<td><%= Request.ServerVariables("HEADER_DISPLAY_NAME2") %></td>
				</tr>
				
				<tr>
					<th>FIRST_NAME</th>
					<td><%= Request.ServerVariables("HEADER_FIRST_NAME") %></td>
				</tr>
				
				<tr>
					<th>LAST_NAME</th>
					<td><%= Request.ServerVariables("HEADER_LAST_NAME") %></td>
				</tr>
				
				<tr>
					<th>DOMAIN</th>
					<td><%= Request.ServerVariables("HEADER_DOMAIN") %></td>
				</tr>
				
				<tr>
					<th>REMOTE_USER</th>
					<td><%= Request.ServerVariables("HEADER_REMOTE_USER") %></td>
				</tr>
				
				<tr>
					<th>SM_SESSIONDRIFT</th>
					<td><%= Request.ServerVariables("HEADER_SM_SESSIONDRIFT") %></td>
				</tr>
				
				<tr>
					<th>SM_UNIVERSALID</th>
					<td><%= Request.ServerVariables("HEADER_SM_UNIVERSALID") %></td>
				</tr>
				
				<tr>
					<th>SM_AUTHDIROID</th>
					<td><%= Request.ServerVariables("HEADER_SM_AUTHDIROID") %></td>
				</tr>
				
				<tr>
					<th>SM_AUTHDIRNAME</th>
					<td><%= Request.ServerVariables("HEADER_SM_AUTHDIRNAME") %></td>
				</tr>
				
				<tr>
					<th>SM_AUTHDIRSERVER</th>
					<td><%= Request.ServerVariables("HEADER_SM_AUTHDIRSERVER") %></td>
				</tr>
				
				<tr>
					<th>SM_AUTHDIRNAMESPACE</th>
					<td><%= Request.ServerVariables("HEADER_SM_AUTHDIRNAMESPACE") %></td>
				</tr>
				
				<tr>
					<th>COOKIE</th>
					<td><%= Request.ServerVariables("HTTP_COOKIE") %></td>
				</tr>
				
				<tr>
					<th>SM_USER</th>
					<td><%= Request.ServerVariables("HEADER_SM_USER") %></td>
				</tr>
				
				<tr>
					<th>SM_USERDN</th>
					<td><%= Request.ServerVariables("HEADER_SM_USERDN") %></td>
				</tr>
				
				<tr>
					<th>SM_SERVERSESSIONID</th>
					<td><%= Request.ServerVariables("HEADER_SM_SERVERSESSIONID") %></td>
				</tr>
				
				<tr>
					<th>SM_SERVERSESSIONSPEC</th>
					<td><%= Request.ServerVariables("HEADER_SM_SERVERSESSIONSPEC") %></td>
				</tr>
				
				<tr>
					<th>SM_TIMETOEXPIRE</th>
					<td><%= Request.ServerVariables("HEADER_SM_TIMETOEXPIRE") %></td>
				</tr>
				
				<tr>
					<th>SM_SERVERIDENTITYSPEC</th>
					<td><%= Request.ServerVariables("HEADER_SM_SERVERIDENTITYSPEC") %></td>
				</tr>
				
				<tr>
					<th>ALL_HTTP</th>
					<td><%= Request.ServerVariables("ALL_HTTP") %></td>
				</tr>

				<tr>
					<th>ALL_RAW</th>
					<td><%= Request.ServerVariables("ALL_RAW") %></td>
				</tr>
						
			</TABLE>
	</body>
</html>