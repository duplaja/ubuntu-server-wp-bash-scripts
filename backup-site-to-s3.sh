#!/bin/bash
###########################
###### CONFIGURATION ######
###########################
DATE=`date +%Y-%m-%d`
DOMAIN="www.example.com"
SITE_DIR="/var/www/www.example.com/"
TEMP_DIR="/tmp/www-backups/${DOMAIN}_${DATE}"
TEMP_DB="$TEMP_DIR/database"
DB_NAME="dbname"
DB_USER="dbuser"
DB_PASSWORD="db_pass"
S3_DIR="s3://bucket-name/personal/${DOMAIN}/${DATE}"
MSG_COLOR='\033[0;97m'
MSG_COLOR_DONE='\033[0;96m'
MSG_END='\033[0m'
RUN_SLEEP="0.5"
###########################

### OPENING LINE
printf "${MSG_COLOR}\n"'%*s\n\n'"${MSG_END}" "${COLUMNS:-$(tput cols)}" '' | tr ' ' -;

### CREATE TEMPORARY FOLDERS
printf "${MSG_COLOR}Creating temporary folder...${MSG_END}";
while true; do printf "${MSG_COLOR}.${MSG_END}"; sleep $RUN_SLEEP; done &
mkdir -p $TEMP_DB
kill $!; trap 'kill $!' SIGTERM
printf "${MSG_COLOR}...done!${MSG_END}\n\n";

### EXPORT DATABASE
printf "${MSG_COLOR}Exporting database...${MSG_END}";
while true; do printf "${MSG_COLOR}.${MSG_END}"; sleep $RUN_SLEEP; done &
mysqldump -u $DB_USER -p$DB_PASSWORD $DB_NAME > $TEMP_DB/$DB_NAME.sql
kill $!; trap 'kill $!' SIGTERM
printf "${MSG_COLOR}...done!${MSG_END}\n\n";

### COMPRESS & DELETE ORIGINAL DATABASE FILE
printf "${MSG_COLOR}Compressing database file...${MSG_END}";
while true; do printf "${MSG_COLOR}.${MSG_END}"; sleep $RUN_SLEEP; done &
tar -zcf $TEMP_DIR/database.tar.gz -C $TEMP_DIR . --warning=no-all
rm -rf $TEMP_DB
kill $!; trap 'kill $!' SIGTERM
printf "${MSG_COLOR}...done!${MSG_END}\n\n";

### COMPRESS WEBSITE FILES
printf "${MSG_COLOR}Compressing website files...${MSG_END}";
while true; do printf "${MSG_COLOR}.${MSG_END}"; sleep $RUN_SLEEP; done &
tar -zcf $TEMP_DIR/html.tar.gz -C $SITE_DIR . --warning=no-all
kill $!; trap 'kill $!' SIGTERM
printf "${MSG_COLOR}...done!${MSG_END}\n\n";

### SYNC ARCHIVE TO S3
printf "${MSG_COLOR}Uploading to Amazon S3...${MSG_END}";
while true; do printf "${MSG_COLOR}.${MSG_END}"; sleep $RUN_SLEEP; done &
/usr/local/bin/aws s3 mv $TEMP_DIR $S3_DIR --recursive --quiet
kill $!; trap 'kill $!' SIGTERM
printf "${MSG_COLOR}...done!${MSG_END}\n\n";

### DELETE BACKUP DIRECTORY
printf "${MSG_COLOR}Cleaning up temporary folders...${MSG_END}";
while true; do printf "${MSG_COLOR}.${MSG_END}"; sleep $RUN_SLEEP; done &
rm -rf $TEMP_DIR
kill $!; trap 'kill $!' SIGTERM
printf "${MSG_COLOR}...done!${MSG_END}\n\n";

### COMPELTED MESSAGE
printf "${MSG_COLOR_DONE}Backup complete!${MSG_END}\n\n";
pkill 'backup-site-to-s3';
### CLOSING LINE
##printf "${MSG_COLOR}"'%*s\n\n'"${MSG_END}" "${COLUMNS:-$(tput cols)}" '' | tr ' ' -;
