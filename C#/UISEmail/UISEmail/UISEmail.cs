using System;
using System.Collections.Generic;
using System.Net.Mail;

namespace UISEmail
{
    public class Email
    {
        private List<string> toAddresses;
        private List<string> bccAddresses;
        private List<string> attachmentPaths;
        private List<string> carbonCopies;

        private string fromAddress;
        private string subject;
        private string body;
        private string smtpClient= "uismail2.uis.edu";
        private string sender;

        private int priority = 1; //Normal
        private int deliveryMethod = 0; //SmtpDeliveryMethod Default Network

        private bool isHtml = true;

        private MailMessage message;
        private SmtpClient smtp;

        /// <summary>
        /// This constructor is used when you want to add everything
        /// explicitly by calling their properties.  
        /// </summary>
        public Email()
        {
            fromAddress = "";
            subject = "";
            body = "";

            toAddresses = new List<string>();
            attachmentPaths = new List<string>();
            bccAddresses = new List<string>();
            carbonCopies = new List<string>();

            message = new MailMessage();
        }

        /// <summary>
        /// This constructor allows you to provide a from address, the name of the sender,
        /// and a list of addresses to send the email to.  Note:  You can put null for toAddresses
        /// and it will simply create a new List of toAddresses for you to add addresses to.
        /// </summary>
        /// <param name="fromAddress">A string that contains the from address.</param>
        /// <param name="sender">A string that contains the name of the sender.</param>
        /// <param name="toAddresses">A List of strings containing the addresses to send to.</param>
        public Email(string fromAddress, string sender, List<string> toAddresses)
        {
            body = "";
            subject = "";

            this.sender = sender;
            this.fromAddress = fromAddress;

            this.toAddresses = toAddresses == null ? new List<string>() : toAddresses;
            attachmentPaths = new List<string>();
            bccAddresses = new List<string>();
            carbonCopies = new List<string>();

            message = new MailMessage();
        }

        /// <summary>
        /// This constructor allows for a little more to be passed to it.
        /// Note:  You can put null for the lists
        /// and it will simply create a new List that you can add to later.
        /// </summary>
        /// <param name="fromAddress">A string that contains the from address.</param>
        /// <param name="sender">A string that contains the name of the sender.</param>
        /// <param name="toAddresses">A List of strings containing the addresses to send to.</param>
        /// <param name="subject">The subject of the email can be stated here</param>
        /// <param name="body">The message to be sent to the recipient.</param>
        /// <param name="attachmentPaths">A list of paths to a file to be attached.</param>
        /// <param name="bccAddresses">A list of blind carbon copy addresses.</param>
        /// <param name="carbonCopies">A list of carbon copy addresses.</param>
        public Email(string fromAddress, string sender, List<string> toAddresses, string subject, string body, List<string> attachmentPaths, List<string> bccAddresses, List<string> carbonCopies)
        {

            this.sender = sender;
            this.fromAddress = fromAddress;
            this.subject = subject;
            this.body = body;


            //All of these are basically stating that if the passed parameter
            //that is respective to it's global variable is null then set the
            //global variable to a new list.  If the passed parameter is not null
            //then we can set the global variable to that instead.
            this.toAddresses = toAddresses == null ? new List<string>() : toAddresses;
            this.attachmentPaths = attachmentPaths == null ? new List<string>() : attachmentPaths;
            this.bccAddresses = bccAddresses == null ? new List<string>() : bccAddresses;
            this.carbonCopies = carbonCopies == null ? new List<string>() : carbonCopies;

            message = new MailMessage();
        }

        /**public string SmtpClient
        {
            get { return smtpClient}
            set {smtpClient = value;}
        }**/

        public int DeliveryMethod
        {
            get { return deliveryMethod; }
            set { deliveryMethod = value; }
        }

        public bool IsHtml
        {
            get { return isHtml; }
            set { isHtml = value; }
        }

        public List<string> BccAddresses
        {
            get { return bccAddresses; }
            set { bccAddresses = value; }
        }

        public List<string> AttachmentPaths
        {
            get { return attachmentPaths; }
            set { attachmentPaths = value; }
        }

        public List<string> ToAddresses
        {
            get { return toAddresses; }
            set { toAddresses = value; }
        }

        public List<string> CC
        {
            get { return carbonCopies; }
            set { carbonCopies = value; }
        }

        public string Body
        {
            get { return body; }
            set { body = value; }
        }

        public string Subject
        {
            get { return subject; }
            set { subject = value; }
        }

        public string Sender
        {
            get { return sender; }
            set { sender = value; }
        }

        public string FromAddress
        {
            get { return fromAddress; }
            set { fromAddress = value; }
        }

        public int Priority
        {
            get { return priority; }
            set { priority = value; }
        }

        private void setMailAddresses(List<string> collection, MailAddressCollection messageCollection)
        {
            foreach (string element in collection)
            {
                messageCollection.Add(element);
            }
        }

        private void setAttachmentAddresses(List<string> collection, AttachmentCollection attachmentCollection)
        {
            foreach (string element in collection)
            {
                attachmentCollection.Add(new Attachment(element));
            }
        }

        private void setSmtpDeliveryMethod()
        {
            switch (deliveryMethod)
            {
                case 0:
                    smtp.DeliveryMethod = SmtpDeliveryMethod.Network;
                    break;
                case 1:
                    smtp.DeliveryMethod = SmtpDeliveryMethod.PickupDirectoryFromIis;
                    break;
                case 2:
                    smtp.DeliveryMethod = SmtpDeliveryMethod.SpecifiedPickupDirectory;
                    break;
                default:
                    throw new ArgumentException("Invalid delivery method.  0 = Network, 1 = Pickup Directory From IIS, 2 = Specified Pickup Directory");
            }
        }

        private void setPriorityState()
        {
            switch (priority)
            {
                case 0:
                    message.Priority = MailPriority.Low;
                    break;
                case 1:
                    message.Priority = MailPriority.Normal;
                    break;
                case 2:
                    message.Priority = MailPriority.High;
                    break;
                default:
                    throw new ArgumentException("Invalid priority set. 0 = Low, 1 = Normal, 2 = High.");
            }
        }

        public void sendMail()
        {
            try
            {

                smtp = new SmtpClient(smtpClient);
                message.From = new MailAddress(fromAddress, sender);
                message.Subject = subject;
                message.Body = body;
                message.IsBodyHtml = isHtml;

                setMailAddresses(toAddresses, message.To);
                setMailAddresses(bccAddresses, message.Bcc);
                setMailAddresses(carbonCopies, message.CC);
                setAttachmentAddresses(attachmentPaths, message.Attachments);

                setPriorityState();
                setSmtpDeliveryMethod();

                smtp.Send(message);
            }
            catch (SmtpException ex)
            {
                throw new SmtpException(ex.Message);
            }
            catch (ArgumentException ex)
            {
                if (toAddresses.Count == 0 || toAddresses == null)
                {
                    throw new ArgumentException("No TO address was specified: " + ex.Message);
                }
                else if (String.IsNullOrEmpty(fromAddress))
                {
                    throw new ArgumentException("No FROM address was specified: " + ex.Message);
                }
                else
                {
                    throw new ArgumentException(ex.Message);
                }
            }
            catch (InvalidOperationException ex)
            {
                if (String.IsNullOrEmpty(smtpClient))
                {
                    throw new InvalidOperationException("Please specify an SMTP hostname: " + ex.Message);
                }
                else
                {
                    throw new InvalidOperationException(ex.Message);
                }
            }
            catch (Exception ex)
            {
                throw new Exception(ex.Message);
            }
        }
    }
}
