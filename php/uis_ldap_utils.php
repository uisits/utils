<?php
/*
File:  utils/php/uis_ldap_utils.php

 f() for establing a LDAP connection with LDAP server for domain ($domain) for user ($ldap_user).

Installs at:  /home/its_services/utils

Note: Failure to establish an LDAP connection will trigger a termination call (die).

--------------------

 Usage e.g.:

..in your code, source this file in (at the top):

       if (  file_exists( './ldap_utils.php' ) ) {
             include './uis_ldap_utils.php';
       } else {
             include '/home/its_services/utils/php/uis_ldap_utils.php' ;
       }

...then make your call to establish a connection:

       $ldap_conn = uis_ldap_connect( 'UISAD', 'ldapwriter' );

See also:

getenv() PHP f() for accessing environment vars so you can make thinks more
platform independent, e.g.:  getnev( 'MYSCHEMA' ) ....which is set in an [.htaccess]
file.

Note: 
Password for LDAP accounts - ldapreader, etc. are retrieved via the [get_passwd] utility in order
to prevent passwords from being embedded in code.

Enhancments:

Author:
*/ 

// *************************************************************************
function uis_ldap_connect( $domain, $ldap_user ) {

   $domain = strtolower( $domain );
   $ldap_user = strtolower( $ldap_user );

   $binddn = "";

   // Determine the LDAP server...

   if ( strtolower( $domain ) == 'uisad' ) {

       $ip = "uisad.uis.edu";

       if ( strtolower( $ldap_user ) ==  'ldapwriter'  ) {

            $binddn = "CN=ldapwriter,OU=ServiceAccounts,OU=CTS,DC=uisad,DC=uis,DC=edu";          

       } else if ( strtolower( $ldap_user ) ==  'ldapreader'  ) {

            $binddn = "CN=ldapreader,OU=ServiceAccounts,OU=CTS,DC=uisad,DC=uis,DC=edu";          
       } else {
            die( "uis_ldap_connect() error: Invalid domain - " . $domain . "\r\n " );
       }
   } else if (  strtolower( $domain ) == 'uismt' ) {

       $ip = "uismt.edu";

       if ( strtolower( $ldap_user ) ==  'ldapwriter'  ) {

            $binddn = "CN=LdapWriter,OU=ServiceAccounts,OU=CTS,DC=uismt,DC=edu";
       } 
   }  else  {
       die( "uis_ldap_connect() error: Invalid domain - " . $domain . " \r\n" );
   }

   // If binddn is not set, then we've been called with an unsupported LDAP account
   if ( $binddn == "" ) {

          die( "uis_ldap_connect() error: Invalid/unsupported user - " . $ldapuser . " for domain - " . $domain . "\r\n");
   }

   $ldap_passwd=exec("/home/linux_admins/bin/get_passwd -a os -u $ldap_user -n $domain" );
   //   $ldap_passwd=exec("/home/linux_admins/bin/app_passwd -a os -u $ldap_user -n $domain" );
   $ldap_url = "ldaps://$ip";
   $port = 636;

   $ldap_conn = ldap_connect( $ldap_url, $port ) 
       or die("Sorry! Could not connect to LDAP server ($ip)"  .  ldap_error( $ldap_conn) . "\r\n" );

   ldap_set_option( $ldap_conn, LDAP_OPT_PROTOCOL_VERSION, 3 );
   //    ldap_set_option( $ldap_conn, LDAP_OPT_REFERRALS, 0 );

   $ldap_tries = 0;
   for ( ;  $ldap_tries < 5;  $ldap_tries++ ) {

      $result = ldap_bind( $ldap_conn, $binddn, $ldap_passwd ) ;

      if ( ! $result ) {
        sleep( 3 * $ldap_tries );
	continue;
      } else {
	break;
      }
   }  // end of for-ldap bind loop
   //
   // DO NOT PUT CODE in between the above for-ldap connect attempt and chk for success
   if( $result )  {

      return $ldap_conn;

   } else {

      die("ldap_connect_crt() error: Could not bind after $ldap_tries attempts to server [" . $ldap_url . "] with [" . $ldap_user . "]  Details: \r\n" .  ldap_error( $ldap_conn) . "\r\n" );

   }

}   // end of: uis_ldap_connect()

// *************************************************************************
function uis_ldap_close( $ldap_conn ) {

   ldap_unbind( $ldap_conn );

}   // end of: uis_ldap_close()

?>
