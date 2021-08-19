#!/usr/bin/bash 

# File:	docker_env_parse.sh - extract resource data from a container's env file.
#
# Input:	[env] - {container}.env is parsed for resource usage.
#
# Output:	[csv] - output is written to a {contanter}.csv file
#
# eg call: ./docker_en v_parse.sh  uisdocker1-adviseu-test
#         ...or pass NO argument - to process all the env files.
#
# Note:	Originally test uder [~/WORKON/docker_miner] - [env] files pulled locally, vs using at EDIR.
#
# Note2: 	[csv] must exist in the directory this cmd is invoked from.
#

##To start the containers based on the text file
EDIR="/docker/env_files"
DFILE_BASE="$DDIR/"
PDIR="./csv"
PFILE_BASE="$PDIR/"

##Check the number of arguments OR command usage
if [ $# -gt 1 ]; then
   # usage
   echo "Too many arguments pased in." 
   exit 1
fi
if [ $# -lt 1 ]; then
   # Process all the env files that are present...
   cd $DDIR
   CONTAINER_LIST="`find $EDIR -type d -maxdepth 1 -print | cut -d'/' -f4 `"
   cd -
else
   # Process only the env file for the container called for...
   CONTAINER_LIST="${1}"
fi

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! BEGIN of FOR-LOOP across containters...
#
for i in  $CONTAINER_LIST
do

   CONTAINER=$(echo  $i)

   TGT_CONTAINER="${EDIR}/${CONTAINER}/prod/.env"

   CSV_CONTAINER="${PFILE_BASE}${CONTAINER}.csv"

   # REPO_NAME=$(echo $CONTAINER  | sed 's/uisdocker1\-//g' | sed 's/\-test//g' )  ...test format
   REPO_NAME=$CONTAINER

   echo "Processing [CONTAINER=${CONTAINER}] for [REPO=${REPO_NAME}]"

   # See if the target container exist...
   if [ ! -f $TGT_CONTAINER ]
   then
      echo "$TGT_CONTAINER ENV does not exist"
      exit 10
   fi

   # CSV header for a new resource file...
   #
   echo "APP_NAME,REPO_NAME,TYPE,SERVER,INSTANCE,USER_NAME"  > ${CSV_CONTAINER}

   # There can be >1 APP_NAME - eg Parking Permit and Ticket, so rare - ignore
   #
   APP_NAME=$(grep -e APP_NAME\= $TGT_CONTAINER  |  head -1  | tr -d '\r'  | cut -d'=' -f2  | tr -d "'" )

   # DB_CONNECTION is the name used in app to refer to the connection (not important here)
   #
   # DB dependent resources - common to have more than 1...
   for i in {1..25}
   do 
      if [ $i -eq 1 ]
      then
         EXT=""
      else
         EXT="_$i"
      fi

      DB_HOST=$(grep -e '^DB_HOST'${EXT}\= $TGT_CONTAINER  |  head -1  | tr -d '\r'  | cut -d'=' -f2 )
      if [ "$DB_HOST" == "" ] ;  then  continue;  fi

      DB_DATABASE=$(grep -e '^DB_DATABASE'${EXT}\= $TGT_CONTAINER  |  head -1  | tr -d '\r'  | cut -d'=' -f2 )
      if [ "$DB_DATABASE" == "" ] ;  then  continue;  fi

      DB_USERNAME=$(grep -e '^DB_USERNAME'${EXT}\= $TGT_CONTAINER  |  head -1  | tr -d '\r'  | cut -d'=' -f2 )
      if [ "$DB_USERNAME" == "" ] ;  then  continue;  fi

      echo "${APP_NAME},${REPO_NAME},DB,${DB_HOST},${DB_DATABASE},${DB_USERNAME}"  >> ${CSV_CONTAINER}
   
   done

   # MAIL: Rarely will there be >1 resource, so ignore multiple case.
   #
   MAIL_HOST=$(grep -e '^MAIL_HOST\=' $TGT_CONTAINER  |  head -1  | tr -d '\r'  | cut -d'=' -f2 )
   MAIL_DRIVER=$(grep -e '^MAIL_DRIVER\='  $TGT_CONTAINER  |  head -1  | tr -d '\r'  | cut -d'=' -f2 )
   MAIL_USERNAME=$(grep -e '^MAIL_USERNAME\='  $TGT_CONTAINER  |  head -1  | tr -d '\r'  | cut -d'=' -f2 )
   if [ "$MAIL_HOST" != "" ]
   then 
      echo "${APP_NAME},${REPO_NAME},MAIL,${MAIL_HOST},${MAIL_DRIVER},${MAIL_USERNAME}"  >> ${CSV_CONTAINER}
   fi

   # LDAP: Rarely will there be >1 resource, so ignore multiple case.
   #
   LDAP_SERVER=$(grep -e '^ADLDAP_CONTROLLERS\=' $TGT_CONTAINER  |  head -1  | tr -d '\r'  | cut -d'=' -f2  | cut -d' ' -f1 | tr -d "'" )
   LDAP_USERNAME=$(grep -e '^ADLDAP_ADMIN_USERNAME\='  $TGT_CONTAINER  |  head -1  | tr -d '\r'  | cut -d'=' -f2 )
   if [ "$LDAP_SERVER" != "" ]
   then 
      echo "${APP_NAME},${REPO_NAME},LDAP,${LDAP_SERVER},UISAD,${LDAP_USERNAME}"  >> ${CSV_CONTAINER}
   fi

   # iPAY: Rarely will there be >1 resource, so ignore multiple case.
   #
   PMT_SERVER=$(grep -e '^PAYMENT_URL\=' $TGT_CONTAINER  |  head -1  | tr -d '\r'  | cut -d'=' -f2  | cut -d'/' -f3  | tr -d "'" )
   PMT_USERNAME=$(grep -e '^PAYMENT_SITEID\=' $TGT_CONTAINER  |  head -1  | tr -d '\r'  | cut -d'=' -f2  | tr -d "'" )
   if [ "$PMT_SERVER" != "" ]
   then
      echo "${APP_NAME},${REPO_NAME},PAYMENT,${PMT_SERVER},IPAY,${PMT_USERNAME}"  >> ${CSV_CONTAINER}
   fi

done
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! END of FOR-LOOP across containters...

echo "Successfully completed executing the script"

