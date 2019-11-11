<?php 
/*
File:  utils/php/get_emp_img.php

Desc:  Return the Base64 image for an employee - based upon where
       where it is located:

       WEBROOT/images/alternate/  ...if not here, then get from...
       WEBROOT/images/employees/  ...if not here, then use...
       WEBROOT/images/employees/000000000.jpg

       ...json encoded:


       Install at:  WEBROOT/images/get_emp_img.php
 */

// $uin = "660838482";

$uin = $_GET["uin"];

$json_img_exist = "false";

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
   $json_img_exist = "true";
} elseif ( file_exists( "$EMP_ROOT/$uin_jpg" ) == true ) {
   
   $IMG_FILENAME = "$EMP_ROOT/$uin_jpg";
   $json_img_exist = "true";
}

// echo "Image file = " . $IMG_FILENAME . "<br/>" . PHP_EOL;

$img_data = file_get_contents( "$IMG_FILENAME" );

// Show a straight up image:
//
// echo '<img src="data:image/jpg;base64,' . base64_encode( $img_data ) . '" />';

// Return JSON for image (with a flag if file was found)
// ...the following hearders are needed to address new Chromium checks
// ...relating to CORS and CORB
//
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
//header("Access-Control-Allow-Headers: *");
// ...test change for IE - but did not work:
header("Access-Control-Allow-Headers:Origin,x-csrf-token,X-Requested-With,Content-Type,Accept");
header("X-Requested-With:'XMLHttpRequest'");
header("Access-Control-Allow-Methods:'GET'");

echo '{' . PHP_EOL 
. '   "imagebase64" : "' . base64_encode( $img_data ) . '"' .  PHP_EOL 
. '   , "imageExists" : "' . $json_img_exist . '"' .  PHP_EOL 
. '}' . PHP_EOL ;

?>

