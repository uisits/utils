<?php
/*
File:  utils/php/get_emp_img.php

Desc:  Return the Base64 image for an employee - based upon where
       where it is located:

       WEBROOT/images/alternate/  ...if not here, then get from...
       WEBROOT/images/employees/  ...if not here, then use...
       WEBROOT/images/employees/000000000.jpg

       Install at:  WEBROOT/images/get_emp_img.php
 */

// $uin = "660838482";

$uin = $_GET["uin"];

if ( "$uin" == '' ) {
   $uin = "000000000";
}

$uin_jpg = $uin . ".jpg";

$WEB_ROOT = "/var/www/html";
$IMG_ROOT = "$WEB_ROOT/images";
$EMP_ROOT = "$IMG_ROOT/employees/all";
$ALT_ROOT = "$IMG_ROOT/alternate/all";
$IMG_FILENAME = "$EMP_ROOT/000000000.jpg";

// echo "Image file beginning: IMG_FILENAME" . "<br/>" . PHP_EOL;

clearstatcache();

if ( file_exists( "$ALT_ROOT/$uin_jpg" ) == true ) {

   $IMG_FILENAME = "$ALT_ROOT/$uin_jpg";

} elseif ( file_exists( "$EMP_ROOT/$uin_jpg" ) == true ) {
   
   $IMG_FILENAME = "$EMP_ROOT/$uin_jpg";
}

// echo "Image file = " . $IMG_FILENAME . "<br/>" . PHP_EOL;

$img_data = file_get_contents( "$IMG_FILENAME" );

echo '<img src="data:image/jpg;base64,' . base64_encode( $img_data ) . '" />';

?>
