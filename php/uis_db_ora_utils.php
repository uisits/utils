<?php
/*
File:   utils/php/uis_db_ora_utils.php -  collection of PHP utilities, w/ "uis_" prefixed on to utility name
               to keep from colliding with another name space.

Installs at:  /home/its_services/utils

--------------------
uis_db_ora_connect() : Establish a DB connection with an Oracle DB ($sid) for $user

uis_db_ora_close() : f() closing an Oracle DB connection

Usage E.g.: 

...in your code, source this file in (at the top):
      if (  file_exists( './uis_db_ora_utils.php' ) ) { 
            include './uis_db_ora_utils.php';   
      }  else {
            include '/home/its_services/utils/php/uis_db_ora_utils.php' ;  
      }

...then make your call to establish a connection:

      $db_conn = uis_db_ora_connect( 'oraprod', 'uis_cd' );

See also: 

getenv() PHP f() for accessing environment vars so you can make thinks more
platform independent, e.g.:  getnev( 'MYSCHEMA' ) ....which is set in an [.htaccess] file.

Added benefit of hiding the password from source code that gets submitted GIT.

Author:   Vern Huber
*/

// *************************************************************************
function uis_db_ora_connect( $sid, $user, $loc ) {

   //   $sid='oraprod';        //  getenv('GMEVOTE_SID');
   //   $user='uis_cdm';       // getenv('GMEVOTE_SCHEMA');

   //   $passwd=exec("/home/linux_admins/bin/app_passwd -a db -u $user -n $sid" ); 
   // ...for web usage, may need to use app_passwd (but it was failing for direct usage);
   $passwd=exec("/home/linux_admins/bin/get_passwd -a db -u $user -n $sid" ); 
   //   echo("...using: -a db -u $user -n $sid  ...using passwd =  $passwd \r\n");

   $db_conn = oci_connect( $user, $passwd, $sid );     // print_r( $db_conn );
   if ( !$db_conn ) {
      echo ("Error attempting to connect to DB ["  . $sid . "] as user [" . $user . "] (loc=db_conn1:$loc) \r\n") ;
      echo var_dump( oci_error() );
      die();
   }

   return  $db_conn ;

}   // end of uis_db_ora_connec()


// *************************************************************************
function uis_db_ora_close( $db_conn ) {

  return oci_close( $db_conn );

}   // end of uis_db_ora_close()


// *************************************************************************
function uis_db_ora_commit( $db_conn , $stmt ) {

   $r = oci_commit( $db_conn );
   if ( ! $r ) {
      $e = oci_error( $db_conn );
      print htmlentities($e['message']);
      return 1;
   }
   if ( ! oci_free_statement( $stmt ) ) { 
        print( "oci_free_statement: Error freeing DB resources \r\n");
	return 2;
   }

   if ( ! uis_db_ora_close( $db_conn ) ) {
        print( "ora_close: Error closing DB connection \r\n");
        return 3;
   }

   return 0;   // success

}   // end of uis_db_ora_commit()

// *************************************************************************
function uis_db_ora_close_err( $db_conn, $err_msg ) {

   echo var_dump( oci_error( $db_conn )  );
   oci_rollback( $db_conn );
   oci_close( $db_conn );

   die( $err_mgs . "\r\n"  );

}   // end of uis_db_ora_close_err()

// *************************************************************************
function uis_db_ora_err_stmt( $db_conn, $stmt, $err_msg ) {

   echo var_dump( oci_error( $db_conn )  );

   oci_free_statement( $stmt );

   oci_rollback( $db_conn );
   oci_close( $db_conn );

   die( $err_mgs . "\r\n" );

}   // end of uis_db_ora_close_err_stmt()

?>
