#!/usr/bin/bash 

# File:	docker_env_parse.sh - extract resource data from a container's env file.
#
# Input:	$1 - [container/app] to look for (ie, {container}.env to parse for resource usage).
#
# Output:	[data/docker/csv/<container>.csv] - where output is written to
#
# eg call: ./docker_en v_parse.sh  uisdocker1-adviseu-test
#         ...or pass NO argument - to process all the container env files.
#
# Note:		Originally test uder [~/WORKON/docker_miner] - [env] files pulled locally, vs using at ENV_FILES_DIR.
#
# Note2: 	[$HOME/data/docker/csv] must exist
#
# Note3:	[env] files are on [UISdocker3] per TL 11/15/2023 (originally were on UISdocker1)
#

DDIR="$HOME/data/docker"
#
# Location of Laravel env files to parse - based upon the application containers
ENV_FILES_DIR="/docker/env_files"
CSV_CONTAINER="${DDIR}/docker_env_apps.csv"

# Check to see if the output directory exist - exit if it does not.
if [ ! -d $DDIR ]
then
	echo "Directory [$DDIR] for generating output to does not exist" 
	exit 1 
fi

##Check the number of arguments OR command usage
if [ $# -gt 1 ]; then
   # usage
   echo "Too many arguments pased in." 
   exit 5
fi
if [ $# -lt 1 ]; then
   # Process all the env files that are present...
   cd $DDIR
   CONTAINER_LIST="`find $ENV_FILES_DIR -maxdepth 1  -type d  -print | cut -d'/' -f4 `"
   cd -
else
   # Process only the env file for the container called for...
   CONTAINER_LIST="${1}"
   if [ ! -d $ENV_FILES_DIR/$CONTAINER_LIST ]
   then
	  echo "Container requested [$CONTAINER_LIST] for generating output to does not exist" 
	  exit 1 
   fi
fi


# CSV header for resource file (was building individually - but then we'd need to aggregate them.
# 
# Mapping:  [/docker/env_files/<containter>/.env]
#
# ...APP_NAME 		>> appshome.APP_DETAILS.FancyName	>> team.APPLICATION.app_title
# ...<container>	>> appshome.APP_DETAILS.Name		>> team.APPLICATION.app_acronym
# ...{ DB, MAIL, ...}									>> team.APP_RESOURCE.res_type
# ...4th field: eg server								>> team.APP_RESOURCE.res_item
# ...5th field											>> team.APP_RESOURCE.res_instance
# ...6th field											>> team.APP_RESOURCE.res_user
#
echo "FancyName,Name,Type,Server,Instance,User"  > ${CSV_CONTAINER}
   
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! BEGIN of FOR-LOOP across containters...
#
for i in  $CONTAINER_LIST
do

   CONTAINER=$(echo  $i)

   TGT_CONTAINER="${ENV_FILES_DIR}/${CONTAINER}/prod/.env"

   # REPO_NAME=$(echo $CONTAINER  | sed 's/uisdocker1\-//g' | sed 's/\-test//g' )  ...test format
   REPO_NAME=$CONTAINER

   echo "Processing [CONTAINER=${CONTAINER}] for [REPO=${REPO_NAME}]"

   # See if the target container exist...
   if [ ! -f $TGT_CONTAINER ]
   then
      echo "$TGT_CONTAINER ENV does not exist"  1>&2
      # exit 10
	  continue
   fi


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
   # end of loop across resources (eg, where multiple of same type might be used)

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

