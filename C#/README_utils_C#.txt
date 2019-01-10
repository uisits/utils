The MSDBEmailExample holds a project that shows how to call a procedure from a database and pass in parameters using prepared statements.

SQLEmail holds the project that sends an email by passing in parameters to an SQL database.  The project calls the uis_sendmail procedure.
The SQLEmailDll holds the DLL of the project so that others can use it in their own projects.

UISEmail holds the project that also sends an email but it uses an SMTP server instead.  It takes what data is given to it and sends it to
the SMTP server to send.  The EmailDll holds the DLL for this project so others may use it in their own projects.