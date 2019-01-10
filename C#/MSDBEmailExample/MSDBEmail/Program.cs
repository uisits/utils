using System;
using System.Collections.Generic;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Collections;
using System.Net.Mail;
//using UISEmail;
using System.Runtime.InteropServices;

namespace MSDBEmail
{
    public class Email
    {
        private static string sSqlConnection2 = "Data Source=uisappsrvprod2;Initial Catalog=msdb;User Id=sandal;Password=wh0g03sther3!";
        public static void Main(string[] args)
        {
             try
                {
                    string NetId = "amall2";
                    string FullName = "Mallipeddi, Apeksha";
                    var UserName = FullName.Split(',');
                    string FirstName = UserName[1].Trim();
                    string LastName = UserName[0].Trim();

                    string ToEmail = NetId + "@uis.edu";
                    string FromAddress = "techsupport@uis.edu";
                    string Subject = "Account Removal Notice " + "(" + NetId + ")";
                    string Body = "Hello " + FirstName + ",<br><br>Our records indicate that more than a year has passed since you last enrolled in courses at UIS. " +
                                  "<B>Your email account will be removed in 60 days.</B> " +
                                  "Please move any content you would like to retain before then.<br><br>" +
                                  "Please contact the Technology Support Center at <a href=\"mailto:techsupport@uis.edu\">techsupport@uis.edu</a> " +
                                  "with any questions</a>.<br/><br/>";
                    string BodyFormat = "html";
                    string GroupId = "11";
                    
                    SqlConnection SqlConnMSDB = new SqlConnection(sSqlConnection2);
                    SqlConnMSDB.Open();
                    SqlCommand cmd = new SqlCommand();
                    cmd.Connection = SqlConnMSDB;
                    cmd.CommandText = "uis_sendmail";
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add("@to", SqlDbType.VarChar).Value = ToEmail;
                    cmd.Parameters.Add("@from_address", SqlDbType.VarChar).Value = FromAddress;
                    cmd.Parameters.Add("@subject", SqlDbType.VarChar).Value = Subject;
                    cmd.Parameters.Add("@body_format", SqlDbType.VarChar).Value = BodyFormat;
                    cmd.Parameters.Add("@group_id", SqlDbType.VarChar).Value = GroupId;
                    cmd.Parameters.Add("@body", SqlDbType.VarChar).Value = Body;
                    cmd.ExecuteNonQuery(); 
                }
                catch (Exception e)
                {
                    Console.WriteLine(e.Message);
                    
                }
        }
    }
}
