#!/bin/bash
##################################
## Things you must do first ######
##################################

#1) Configure DNS to point to this server for the domain you want, and allow time to propogate

###########################
###### CONFIGURATION ######
###########################

##Stuff used for MySQL Database / User Creation (account must have database / user creation privileges)
MYSQL_CREATE_USER="xxxx"
MYSQL_CREATE_PASSWORD="xxxx"

#Stuff used for apache config file
SITE_URL="www.example.com"
NO_WWW_SITE_URL="example.com"
DOCUMENT_ROOT="/var/www/www.example.com"
APACHE_CONF="<VirtualHost *:80>\n      ServerName $SITE_URL\n      ServerAlias $NO_WWW_SITE_URL\n        ServerAdmin webmaster@localhost\n      DocumentRoot $DOCUMENT_ROOT\n     ErrorLog \${APACHE_LOG_DIR}/error.log\n      CustomLog \${APACHE_LOG_DIR}/access.log combined\n</VirtualHost>"

HTTPS_URL="https://www.example.com"

#Database STuff
DB_NAME="exampledb"
DB_USER="exampledb"
DB_PASS="akdsfkKDJKIWWdfawe"
DB_PREFIX="wp_example_"


#Wordpress COnfig Stuff
SITE_TITLE="Example"
ADMIN_USER="user"
ADMIN_PASSWORD="password"
ADMIN_EMAIL="test@gmail.com"
WP_THEME="ultra"

#Makes site root, and moves there.
mkdir $DOCUMENT_ROOT
cd $DOCUMENT_ROOT

#Creates mysql database and user on it.
mysql -u$MYSQL_CREATE_USER -p$MYSQL_CREATE_PASSWORD -e "CREATE DATABASE $DB_NAME"

mysql -u$MYSQL_CREATE_USER -p$MYSQL_CREATE_PASSWORD -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS'"

mysql -u$MYSQL_CREATE_USER -p$MYSQL_CREATE_PASSWORD -e "FLUSH PRIVILEGES"


##Creats the apache config file, and loads it
echo -e "$APACHE_CONF" > /etc/apache2/sites-available/$SITE_URL.conf
a2ensite $SITE_URL.conf
service apache2 reload

##Uses LetsEncrypt to set up SSL for the site
/opt/letsencrypt/letsencrypt-auto --apache -d $SITE_URL -d $NO_WWW_SITE_URL -n

##sets file perms


##Downloads WOrdpress Files to current folder
wp core download 

##Creates wp-config.php
wp core config --dbname=$DB_NAME --dbuser=$DB_USER --dbpass=$DB_PASS --dbhost=localhost --dbprefix=$DB_PREFIX 

##Installs Wordpress, using settings above
wp core install --url=$HTTPS_URL --title=$SITE_TITLE --admin_user=$ADMIN_USER --admin_password=$ADMIN_PASSWORD --admin_email=$ADMIN_EMAIL 

##Installs theme
wp theme install $WP_THEME 

##Creates blank child theme and enables it
wp scaffold child-theme $WP_THEME-child --parent_theme=$WP_THEME --theme_name="$WP_THEME  Child" --author='Dan Dulaney' --author_uri='https://www.convexcode.com' --theme_uri='https://www.convexcode.com' --activate 

###Installing Pluggins

### Plugins to be activated
declare -a arr=("all-in-one-seo-pack" "async-javascript" "autoptimize" "baw-login-logout-menu" "black-studio-tinymce-widget" "tiny-compress-images" "contact-form-7" "contact-form-7-accessible-defaults" "login-customizer" "login-lockdown" "megamenu" "ml-slider" "siteorigin-panels" "remove-category-url" "remove-query-strings-from-static-resources" "so-widgets-bundle" "codelights-shortcodes-and-widgets" "user-role-editor" "widgets-for-siteorigin" "wp-force-https")
for i in "${arr[@]}"
do

	wp plugin install $i --activate 


done

###Plugins to install but not activate (require further config)
declare -a twoarr=("cdn-enabler" "easy-wp-smtp")
for i in "${twoarr[@]}"
do

	wp plugin install $i  
done

#Removes default plugins

	wp plugin uninstall akismet 
	wp plugin uninstall hello 

#removes default themes

wp theme uninstall twentysixteen 
wp theme uninstall twentyfourteen 
wp theme uninstall twentyfifteen 



#Settings for Autoptimize
wp option add autoptimize_html on 
wp option add autoptimize_js on 
wp option add autoptimize_js_exclude s_sid,smowtion_size,sc_project,WAU_,wau_add,comment-form-quicktags,edToolbar,ch_client,seal.js,jquery.js 
wp option add autoptimize_js_trycatch on 
wp option add autoptimize_css on 
wp option add autoptimize_css_exclude admin-bar.min.css, dashicons.min.css 
wp option add autoptimize_css_datauris on 
wp option add autoptimize_css_nogooglefont on 
wp option add autoptimize_cache_nogzip on 

#Settings for Async Javascript

wp option add aj_enabled 1 
wp option add aj_method defer 
wp option add aj_exclusions https://ajax.googleapis.com/ajax/libs/jquery/2.1.4/jquery.min.js,http://convexcode.com/wp-content/plugins/stripe-subscriptions/assets/js/public-main.min.js,pikaday-jquery.min.js,moment.min.js,checkout.js,pikaday.min.js,public-main.min.js,jquery.js 

#copies .htaccess file (Preset) to document root (see .htaccess)
cp /var/www/other-scripts/.htaccess $DOCUMENT_ROOT/.htaccess
