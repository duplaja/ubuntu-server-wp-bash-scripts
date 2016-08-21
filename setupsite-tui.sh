#!/bin/bash
##################################
## Things you must do first ######
##################################

#Requires: Ubuntu 16.04 (or other Debian), LetsEncrypt, WP-CLI (with wp alias), Apache2

#1) Configure DNS to point to this server for the domain you want, and allow time to propogate

###########################
###### CONFIGURATION ######
###########################

if (whiptail --title "WordPress Quick Setup" --yesno "This script must be run as root. You must have the following installed: Ubuntu 16.04 / Debian equivalent, Apache2, LetsEncrypt (only if using SSL), MySql, and WP CLI configured with an alias of: wp . Are you currently running as root, and ready to begin?" 14 78) then

    echo "Please Ensure the following are correct: " > fun.txt
    echo "" >> fun.txt

else
    echo "Chose not to run" > fun.txt
    exit 0
fi


##Stuff used for MySQL Database / User Creation (account must have database / user creation privileges)

MYSQL_CREATE_USER=$(whiptail --inputbox "Please enter the account name for a MySQL account that has user / database create privilages: " 8 78 root --title "MySQL Account Name w/ Create Privilages" 3>&1 1>&2 2>&3)
# A trick to swap stdout and stderr.
# Again, you can pack this inside if, but it seems really long for some 80-col terminal users.
exitstatus=$?

if [ $exitstatus = 0 ]; then
    echo "MySQL User: " $MYSQL_CREATE_USER >> fun.txt
else
    echo "User selected Cancel." >> fun.txt
    exit 0
fi


MYSQL_CREATE_PASSWORD=$(whiptail --inputbox "Please enter the password for the MySQL account on the previous screen: " 8 78 pw --title "MySQL Account Password w/ Create Privilages" 3>&1 1>&2 2>&3)
# A trick to swap stdout and stderr.
# Again, you can pack this inside if, but it seems really long for some 80-col terminal users.
exitstatus=$?

if [ $exitstatus = 0 ]; then
    echo "MySQL Password: " $MYSQL_CREATE_PASSWORD >> fun.txt
else
    echo "User selected Cancel." >> fun.txt
    exit 0
fi

#Stuff used for apache config file

NO_WWW_SITE_URL=$(whiptail --inputbox "Please your site URL, without the leading www. If this is a subdomain, enter the whole url (sub.example.com) : " 8 78 example.com --title "No WWW URL" 3>&1 1>&2 2>&3)
# A trick to swap stdout and stderr.
# Again, you can pack this inside if, but it seems really long for some 80-col terminal users.
exitstatus=$?

if [ $exitstatus = 0 ]; then
    echo "Site URL (No www): " $NO_WWW_SITE_URL >> fun.txt
else
    echo "User selected Cancel." >> fun.txt
    exit 0
fi

DOCUMENT_ROOT=$(whiptail --inputbox "Please enter the full path to the directory you want to create for this installation (must not exist): " 8 78 "/var/www/$NO_WWW_SITE_URL" --title "Site Directory Path" 3>&1 1>&2 2>&3)
exitstatus=$?

if [ $exitstatus = 0 ]; then
    echo "Directory Path: " $DOCUMENT_ROOT >> fun.txt
else
    echo "User selected Cancel." >> fun.txt
    exit 0
fi


if (whiptail --title "Subdomain Check" --yesno "Was the URL you just entered a subdomain? (sub.example.com)" 8 78) then

    #echo "URL Type: Subdomain" >> fun.txt
    IS_SUB=true
    SITE_URL=$NO_WWW_SITE_URL
    APACHE_CONF="<VirtualHost *:80>\n      ServerName $SITE_URL\n ServerAdmin webmaster@localhost\n      DocumentRoot $DOCUMENT_ROOT\n     ErrorLog \${APACHE_LOG_DIR}/error.log\n      CustomLog \${APACHE_LOG_DIR}/access.log combined\n</VirtualHost>"

else

    #echo "URL Type: Full Domain" >> fun.txt
	IS_SUB=false
	SITE_URL="www."$NO_WWW_SITE_URL
	APACHE_CONF="<VirtualHost *:80>\n      ServerName $SITE_URL\n       ServerAlias $NO_WWW_SITE_URL\n ServerAdmin webmaster@localhost\n      DocumentRoot $DOCUMENT_ROOT\n     ErrorLog \${APACHE_LOG_DIR}/error.log\n      CustomLog \${APACHE_LOG_DIR}/access.log combined\n</VirtualHost>"

fi

HTTPS_URL="https://"$SITE_URL

##Checks if you want SSL Enabled
if (whiptail --title "SSL Enabled?" --yesno "Would you like to automatically enable SSL via LetsEncrypt for your site now? (domain must be already pointing to the correct IP)" 8 78) then

    echo "LetsEncrypt SSL: Yes" >> fun.txt

    USE_SSL=true    

else
    echo "LetsEncrypt SSL: No" >> fun.txt
    USE_SSL=false
fi


whiptail --textbox fun.txt 15 80

##Checks config so far
if (whiptail --title "Setup Check" --yesno "Were the settings on the previous box correct? Hit Yes to Continue, and No to cancel and restart" 8 78) then

    echo "Please Ensure the following are correct: " > fun.txt
    echo "" >> fun.txt

else
    echo "Chose not to run" > fun.txt
    exit 0
fi


#Database Stuff


DB_NAME=$(whiptail --inputbox "Please enter the desired name for your WordPress database for this site (must not exist). The database user will be identical: " 8 78 ex_db --title "WordPress Database / User Name" 3>&1 1>&2 2>&3)
exitstatus=$?

if [ $exitstatus = 0 ]; then
	DB_USER=$DB_NAME
    echo "WP DB and User: " $DB_NAME >> fun.txt
else
    echo "User selected Cancel." >> fun.txt
    exit 0
fi

DB_PASS=`openssl rand -hex 16` #Per suggestion from /u/chocolate-cake
echo "WP DB Password: $DB_PASS" >> fun.txt


DB_PREFIX=$(whiptail --inputbox "Please enter the desired prefix for your WP Tables: " 8 78 "wp_" --title "WP Table Prefix" 3>&1 1>&2 2>&3)
exitstatus=$?

if [ $exitstatus = 0 ]; then
    echo "DB Prefix: " $DB_PREFIX >> fun.txt
else
    echo "User selected Cancel." >> fun.txt
    exit 0
fi


#Wordpress Config Stuff
SITE_TITLE=$(whiptail --inputbox "Please enter the desired site title for your WP Site (no spaces): " 8 78 "site" --title "WP Site Title" 3>&1 1>&2 2>&3)
exitstatus=$?

if [ $exitstatus = 0 ]; then
    echo "Site Title: " $SITE_TITLE >> fun.txt
else
    echo "User selected Cancel." >> fun.txt
    exit 0
fi

ADMIN_USER=$(whiptail --inputbox "Please enter the desired admin username: " 8 78 "uname" --title "WP Admin Username" 3>&1 1>&2 2>&3)
exitstatus=$?

if [ $exitstatus = 0 ]; then
    echo "WP Admin Name: " $ADMIN_USER >> fun.txt
else
    echo "User selected Cancel." >> fun.txt
    exit 0
fi

ADMIN_PASSWORD=$(whiptail --inputbox "Please enter the desired admin password: " 8 78 "upass" --title "WP Admin Password" 3>&1 1>&2 2>&3)
exitstatus=$?

if [ $exitstatus = 0 ]; then
    echo "WP Admin PW: " $ADMIN_PASSWORD >> fun.txt
else
    echo "User selected Cancel." >> fun.txt
    exit 0
fi

ADMIN_EMAIL=$(whiptail --inputbox "Please enter the desired admin email: " 8 78 "test@gmail.com" --title "WP Admin Email" 3>&1 1>&2 2>&3)
exitstatus=$?

if [ $exitstatus = 0 ]; then
    echo "WP Admin Email: " $ADMIN_EMAIL >> fun.txt
else
    echo "User selected Cancel." >> fun.txt
    exit 0
fi


WP_THEME=$(whiptail --inputbox "If you want to use a theme from wordpress.org, please enter the appropriate slug here. This will install, activate, and create a child-theme. Otherwise, click cancel to use a default theme for now, and pick your own later.: " 15 78 "ultra" --title "WP Theme" 3>&1 1>&2 2>&3)
exitstatus=$?

if [ $exitstatus = 0 ]; then
    echo "WP Theme: " $WP_THEME >> fun.txt
    DL_THEME=true
else
    WP_THEME="twentysixteen"
    echo "WP THEME: " $WP_THEME >> fun.txt
    DL_THEME=false
fi



whiptail --textbox fun.txt 20 80

##Checks config so far
if (whiptail --title "WP Setup Check" --yesno "Were the settings on the previous box correct? Hit Yes to Continue, and No to cancel and restart" 8 78) then

    echo "Please Ensure the following are correct: " > fun.txt
    echo "" >> fun.txt

else
    echo "Chose not to run" > fun.txt
    exit 0
fi

rm fun.txt


#Makes site root, and moves there.
mkdir $DOCUMENT_ROOT
cd $DOCUMENT_ROOT

#Creates mysql database and user on it.
mysql -u$MYSQL_CREATE_USER -p$MYSQL_CREATE_PASSWORD -e "CREATE DATABASE $DB_NAME"

mysql -u$MYSQL_CREATE_USER -p$MYSQL_CREATE_PASSWORD -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS'"

mysql -u$MYSQL_CREATE_USER -p$MYSQL_CREATE_PASSWORD -e "FLUSH PRIVILEGES"


##Creats the apache config file, and loads it (Debian / Ubuntu Only)
echo -e "$APACHE_CONF" > /etc/apache2/sites-available/$SITE_URL.conf
a2ensite $SITE_URL.conf
service apache2 reload

##Uses LetsEncrypt to set up SSL for the site

if $USE_SSL
then

	if $IS_SUB
	then

		/opt/letsencrypt/letsencrypt-auto --apache -d $SITE_URL -n
	else

		/opt/letsencrypt/letsencrypt-auto --apache -d $SITE_URL -d $NO_WWW_SITE_URL -n
	fi
	
fi

##Downloads Wordpress Files to current folder
wp core download --allow-root 

##Creates wp-config.php
wp core config --dbname=$DB_NAME --dbuser=$DB_USER --dbpass=$DB_PASS --dbhost=localhost --dbprefix=$DB_PREFIX --allow-root

##Installs Wordpress, using settings above
wp core install --url=$HTTPS_URL --title=$SITE_TITLE --admin_user=$ADMIN_USER --admin_password=$ADMIN_PASSWORD --admin_email=$ADMIN_EMAIL --allow-root


##Installs theme if selected

if $DL_THEME
then
	wp theme install $WP_THEME --allow-root
fi

##Creates blank child theme and enables it
wp scaffold child-theme $WP_THEME-child --parent_theme=$WP_THEME --theme_name="$WP_THEME  Child" --author='Your Name' --author_uri='https://www.example.com' --theme_uri='https://www.example.com' --activate --allow-root

###Installing Pluggins
##Plugins to Install and Activate

whiptail --title "Choose Plugins To Install and Activate" --checklist --separate-output \
"Choose plugins to install and activate, or cancel to not install any: (space to select, tab to move to Ok / Cancel)" 30 110 20 \
"async-javascript" "Sets js files to be deferred" ON \
"autoptimize" "Compresses and combines CSS, JS, and HTML Files " ON \
"tiny-compress-images" "Auto compresses images on upload" ON \
"login-lockdown" "Locks out wrong pw attempts by IP" ON \
"stop-user-enumeration" "Security, prevents leak of admin login" ON \
"remove-category-url" "Removes category from the url on permalinks" ON \
"remove-query-strings-from-static-resources" "Nice for PageSpeed ratings" ON \
"wp-force-https" "Forces the site to use https" OFF \
"contact-form-7" "Free contact form" ON \
"contact-form-7-accessible-defaults" "Makes Contact Form 7 more accessible" ON \
"ml-slider" "Slider plugin (works well with Ultra Theme)" OFF \
"baw-login-logout-menu" "Adds log in / log out menu item" OFF \
"siteorigin-panels" "WYSIWYG layout editor" OFF \
"black-studio-tinymce-widget" "Various Widgets" OFF \
"so-widgets-bundle" "Widgets for Site Origin" OFF \
"codelights-shortcodes-and-widgets" "More Useful Widgets" OFF \
"widgets-for-siteorigin" "Yet more Widgets for Site Origin" OFF \
"olevmedia-shortcodes" "Allows responsive shortcode layouts" ON \
"all-in-one-seo-pack" "SEO Plugin" ON 2>results

while read choice
do
	wp plugin install $choice --allow-root
	
done < results
rm results

##Plugins to be installed but not activated ##

whiptail --title "Choose Plugins To Install but NOT Activate" --checklist --separate-output \
"Choose plugins to install but not yet activate, or cancel to not install any: (space to select, tab to move to Ok / Cancel)" 30 110 20 \
"cdn-enabler" "Set up to use a CDN of your choice" ON \
"easy-wp-smtp" "Set up your site to use a smtp e-mail" ON \
"wps-hide-login" "Prevents most brute force attacks by hiding login screen" ON \
"google-apps-login" "Allows login using oAuth google account instead of password" ON 2>results2

while read notactivate
do
	wp plugin install $notactivate --allow-root 
	
done < results2
rm results2

#Removes default plugins

	wp plugin uninstall akismet --allow-root 
	wp plugin uninstall hello --allow-root

#removes default themes

wp theme uninstall twentyfourteen --allow-root
wp theme uninstall twentyfifteen --allow-root 

chmod -R 755 $DOCUMENT_ROOT

#Settings for Autoptimize
wp option add autoptimize_html on --allow-root
wp option add autoptimize_js on --allow-root
wp option add autoptimize_js_exclude s_sid,smowtion_size,sc_project,WAU_,wau_add,comment-form-quicktags,edToolbar,ch_client,seal.js,jquery.js --allow-root
wp option add autoptimize_js_trycatch on --allow-root
wp option add autoptimize_css on --allow-root
wp option add autoptimize_css_exclude admin-bar.min.css, dashicons.min.css --allow-root 
wp option add autoptimize_css_datauris on --allow-root
wp option add autoptimize_css_nogooglefont on --allow-root
wp option add autoptimize_cache_nogzip on --allow-root

#Settings for Async Javascript

wp option add aj_enabled 1 --allow-root
wp option add aj_method defer --allow-root
wp option add aj_exclusions jquery.min.js,public-main.min.js,pikaday-jquery.min.js,moment.min.js,checkout.js,pikaday.min.js,public-main.min.js,jquery.js --allow-root 

#copies .htaccess file provided to your wordpress folder. Make sure the .htaccess is in the same file as this script runs from. (I used /var/www/other-scripts, you can modify as needed).
#cp /var/www/other-scripts/.htaccess $DOCUMENT_ROOT/.htaccess

