using System;
using System.Linq;
using System.Text;
using System.Data;
using System.Data.SqlClient;
/****************************************
 * There are some untested variables that
 * require some attention.  The variables
 * are:
 *  profileName
 *  bodyFormat
 *  importance
 *  sensitivity
 *  query
 *  executeQueryDatabase
 *  attachQueryResultAsFile
 *  queryAttachmentFilename
 *  queryResultHeader
 *  queryResultWidth
 *  queryResultSeparator
 *  excludeQueryOutput
 *  appendQueryError
 *  queryNoTruncate
 *  queryResultNoPadding
 *  mailItemID - couldn't set mailItemID to null so it's not even a variable here
 *  replyTo
 *  applicationError
 *  sendAutonomously
 *  runType
 * 12/9/2013
 * **************************************/
namespace UISSQLEmail
{
    public class SQLEmail
    {
        private string connectionString;
        private string toEmailAddress;
        private string fromEmailAddress;
        private string subject;
        private string body;
        private string bodyFormat;
        private Decimal groupID;
        private string procedureCallName;
        private string importance;
        private string replyTo;
        private string fileAttachment;
        private string cc;
        private string bcc;
        private string sensitivity;
        private string query;
        private bool attachQueryResultAsFile;
        private string queryAttachmentFilename;
        private bool queryResultHeader;
        private Int32 queryResultWidth;
        private string queryResultSeparator;
        private bool excludeQueryOutput;
        private bool appendQueryError;
        private bool queryNoTruncate;
        private bool queryResultNoPadding;
        private bool applicationError;
        private bool sendAutonomously;
        private string runType;
        private string profileName;
        private string executeQueryDB;

        public SQLEmail()
        {
            profileName = "uisappdev";
            connectionString = "Data Source=uisappsrvprod2;Initial Catalog=msdb;User Id=sandal;Password=wh0g03sther3!";
            procedureCallName = "uis_sendmail";
            groupID = 10;
            bodyFormat = "html";
            importance = "NORMAL";
            sensitivity = "NORMAL";
            attachQueryResultAsFile = false;
            queryResultHeader = true;
            queryResultWidth = 256;
            queryResultSeparator = " ";
            excludeQueryOutput = false;
            appendQueryError = false;
            queryNoTruncate = false;
            queryResultNoPadding = false;
            applicationError = false;
            sendAutonomously = false;
            runType = "HELP";

            fileAttachment = "";
            toEmailAddress = "";
            fromEmailAddress = "";
            subject = "";
            body = "";
            replyTo = "";
            cc = "";
            bcc = "";
            query = "";
            queryAttachmentFilename = "";
            executeQueryDB = "";
        }

        public string ProfileName
        {
            get { return profileName; }
            set { profileName = value; }
        }

        public string ExecuteQueryDB
        {
            get { return executeQueryDB; }
            set { executeQueryDB = value; }
        }

        public string ToEmailAddress
        {
            get { return toEmailAddress; }
            set { toEmailAddress = value; }
        }

        public string FromEmailAddress
        {
            get { return fromEmailAddress; }
            set { fromEmailAddress = value; }
        }

        public string Subject
        {
            get { return subject; }
            set { subject = value; }
        }

        public string Body
        {
            get { return body; }
            set { body = value; }
        }

        public string BodyFormat
        {
            get { return bodyFormat; }
            set { bodyFormat = value; }
        }

        public string Importance
        {
            get { return importance; }
            set { importance = value; }
        }

        public string Sensitivity
        {
            get { return sensitivity; }
            set { sensitivity = value; }
        }

        public Decimal GroupID
        {
            get { return groupID; }
            set { groupID = value; }
        }

        public string ReplyTo
        {
            get { return replyTo; }
            set { replyTo = value; }
        }

        //To have multiple CC addresses you must separate them with a semicolon.
        //Example: email.CCAddresses = "first@mail.com;second@mail.com;...etc";
        public string CC
        {
            get { return cc; }
            set { cc = value; }
        }

        //To have multiple BCC addresses you must separate them with a semicolon.
        //Example: email.CCAddresses = "first@mail.com;second@mail.com;...etc";
        public string BCC
        {
            get { return bcc; }
            set { bcc = value; }
        }

        public string FileAttachment
        {
            get { return fileAttachment; }
            set { fileAttachment = value; }
        }

        public string Query
        {
            get { return query; }
            set { query = value; }
        }

        public bool AttachQueryResultAsFile
        {
            get { return attachQueryResultAsFile; }
            set { attachQueryResultAsFile = value; }
        }

        public string QueryAttachmentFilename
        {
            get { return queryAttachmentFilename; }
            set { queryAttachmentFilename = value; }
        }

        public bool QueryResultHeader
        {
            get { return queryResultHeader; }
            set { queryResultHeader = value; }
        }

        public Int32 QueryResultWidth
        {
            get { return queryResultWidth; }
            set { queryResultWidth = value; }
        }

        public string QueryResultSeparator
        {
            get { return queryResultSeparator; }
            set { queryResultSeparator = value; }
        }

        public bool ExcludeQueryOutput
        {
            get { return excludeQueryOutput; }
            set { excludeQueryOutput = value; }
        }

        public bool AppendQueryError
        {
            get { return appendQueryError; }
            set { appendQueryError = value; }
        }

        public bool QueryNoTruncate
        {
            get { return queryNoTruncate; }
            set { queryNoTruncate = value; }
        }

        public bool QueryResultNoPadding
        {
            get { return queryResultNoPadding; }
            set { queryResultNoPadding = value; }
        }


        public bool ApplicationError
        {
            get { return applicationError; }
            set { applicationError = value; }
        }

        public bool SendAutonomously
        {
            get { return sendAutonomously; }
            set { sendAutonomously = value; }
        }

        public string RunType
        {
            get { return runType; }
            set { runType = value; }
        }

        //For email validation I only check to make sure the to and from addresses
        //aren't empty or null.  If you would like to know my reasoning as to why I didn't
        //try to validate the address format read here: 
        //http://haacked.com/archive/2007/08/21/i-knew-how-to-validate-an-email-address-until-i.aspx
        private void checkNecessaryValues()
        {
            if(String.IsNullOrEmpty(toEmailAddress) || String.IsNullOrEmpty(fromEmailAddress))
            {
                throw new ArgumentException("Either the toAddress or fromAddress are null or empty.");
            }


        }

        public void sendEmail()
        {
            try
            {
                SqlConnection sqlConnMSDB = new SqlConnection(connectionString);
                sqlConnMSDB.Open();
                SqlCommand cmd = new SqlCommand();
                cmd.Connection = sqlConnMSDB;

                cmd.CommandText = procedureCallName;
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.Add("@to", SqlDbType.VarChar).Value = toEmailAddress;
                cmd.Parameters.Add("@from_address", SqlDbType.VarChar).Value = fromEmailAddress;
                cmd.Parameters.Add("@subject", SqlDbType.NVarChar).Value = subject;
                cmd.Parameters.Add("@body", SqlDbType.NVarChar).Value = body;
                cmd.Parameters.Add("@body_format", SqlDbType.VarChar).Value = bodyFormat;
                cmd.Parameters.Add("@group_id", SqlDbType.Decimal).Value = groupID;
                cmd.Parameters.Add("@importance", SqlDbType.VarChar).Value = importance;
                cmd.Parameters.Add("@reply_to", SqlDbType.VarChar).Value = replyTo;
                cmd.Parameters.Add("@file_attachments", SqlDbType.NVarChar).Value = fileAttachment;
                cmd.Parameters.Add("@cc", SqlDbType.VarChar).Value = cc;
                cmd.Parameters.Add("@bcc", SqlDbType.VarChar).Value = bcc;
                cmd.Parameters.Add("@sensitivity", SqlDbType.VarChar).Value = sensitivity;
                cmd.Parameters.Add("@query", SqlDbType.NVarChar).Value = query;
                cmd.Parameters.Add("@attach_query_result_as_file", SqlDbType.Bit).Value = attachQueryResultAsFile;
                cmd.Parameters.Add("@query_attachment_filename", SqlDbType.NVarChar).Value = queryAttachmentFilename;
                cmd.Parameters.Add("@query_result_header", SqlDbType.Bit).Value = queryResultHeader;
                cmd.Parameters.Add("@query_result_width", SqlDbType.Int).Value = queryResultWidth;
                cmd.Parameters.Add("@query_result_separator", SqlDbType.Char).Value = queryResultSeparator;
                cmd.Parameters.Add("@exclude_query_output", SqlDbType.Bit).Value = excludeQueryOutput;
                cmd.Parameters.Add("@append_query_error", SqlDbType.Bit).Value = appendQueryError;
                cmd.Parameters.Add("@query_no_truncate", SqlDbType.Bit).Value = queryNoTruncate;
                cmd.Parameters.Add("@query_result_no_padding", SqlDbType.Bit).Value = queryResultNoPadding;
                cmd.Parameters.Add("@application_error", SqlDbType.Bit).Value = applicationError;
                cmd.Parameters.Add("@send_autonomously", SqlDbType.Bit).Value = sendAutonomously;
                cmd.Parameters.Add("@run_type", SqlDbType.NVarChar).Value = runType;
                cmd.Parameters.Add("@profile_name", SqlDbType.VarChar).Value = profileName;
                cmd.Parameters.Add("@execute_query_database", SqlDbType.VarChar).Value = executeQueryDB;
                cmd.ExecuteNonQuery();
                sqlConnMSDB.Close();
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                Console.WriteLine("\nPress ENTER to continue...");
                Console.ReadKey();
            }
        }
    }
}
