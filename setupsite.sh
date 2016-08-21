#!/bin/bash
##################################
## Things you must do first ######
##################################

#Requires: Ubuntu 16.04 (or other Debian), LetsEncrypt, WP-CLI (with wp alias), Apache2

#1) Configure DNS to point to this server for the domain you want, and allow time to propogate

###########################
###### CONFIGURATION ######
###########################

##Stuff used for MySQL Database / User Creation (account must have database / user creation privileges)
MYSQL_CREATE_USER="MYSQL_USER"
MYSQL_CREATE_PASSWORD="MYSQL_PASSWORD"

#Stuff used for apache config file
SITE_URL="www.example.com"
NO_WWW_SITE_URL="example.com"
DOCUMENT_ROOT="/var/www/www.example.com"
APACHE_CONF="<VirtualHost *:80>\n      ServerName $SITE_URL\n       ServerAlias $NO_WWW_SITE_URL\n ServerAdmin webmaster@localhost\n      DocumentRoot $DOCUMENT_ROOT\n     ErrorLog \${APACHE_LOG_DIR}/error.log\n      CustomLog \${APACHE_LOG_DIR}/access.log combined\n</VirtualHost>"

HTTPS_URL="https://www.example.com"

#Database Stuff
DB_NAME="example_db"
DB_USER="example_db"
DB_PASS=`openssl rand -hex 16` #Per suggestion from /u/chocolate-cake
DB_PREFIX="wp_example_"


#Wordpress Config Stuff
SITE_TITLE="Example"
ADMIN_USER="somereallynonobvioususernamehere"
ADMIN_PASSWORD="somecomplexadminpwhere"
ADMIN_EMAIL="test@gmail.com"
WP_THEME="ultra" #If you use this one, it needs to be a theme from wordpress.org. I haven't worked in being able to add another from zip, yet.

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

##Uses LetsEncrypt to set up SSL for the site (If you haven't pointed your domain yet, comment this line out)
/opt/letsencrypt/letsencrypt-auto --apache -d $SITE_URL -n

##sets file perms


##Downloads Wordpress Files to current folder
wp core download 

##Creates wp-config.php
wp core config --dbname=$DB_NAME --dbuser=$DB_USER --dbpass=$DB_PASS --dbhost=localhost --dbprefix=$DB_PREFIX 

##Installs Wordpress, using settings above
wp core install --url=$HTTPS_URL --title=$SITE_TITLE --admin_user=$ADMIN_USER --admin_password=$ADMIN_PASSWORD --admin_email=$ADMIN_EMAIL 

##Installs theme
wp theme install $WP_THEME 

##Creates blank child theme and enables it
wp scaffold child-theme $WP_THEME-child --parent_theme=$WP_THEME --theme_name="$WP_THEME  Child" --author='Your Name' --author_uri='https://www.example.com' --theme_uri='https://www.example.com' --activate 

###Installing Pluggins

### Plugins to be activated

#####Plugin List#####

#All Plugins Here are From wordpress.org

#all-in-one-seo-pack : SEO Plugin
#async-javascript : Sets, where possible, js files to be deferred (helping page render time)
#autoptimize : Compresses and combines CSS, JS, and HTML Files 
#baw-login-logout-menu : Adds log in / log out menu item option (shows opposite of current status)
#black-studio-tinymce-widget : Various Widgets
#tiny-compress-images : Requires some config, auto compresses images on upload (limit on free / month)
#contact-form-7 : Free contact form, requires mail settings to be correct
#contact-form-7-accessible-defaults : Makes Contact Form 7 more accessible
#login-lockdown : Locks out wrong attempts after x number of tries, for a set amount of time
#ml-slider : Slider plugin (works well with Ultra Theme)
#siteorigin-panels : WYSIWYG layout editor
#remove-category-url : Removes category from the url on permalinks
#remove-query-strings-from-static-resources : Removes query strings from resources, nice for PageSpeed ratings
#so-widgets-bundle : Widgets for Site Origin
#codelights-shortcodes-and-widgets : More Useful Widgets
#widgets-for-siteorigin : Yet more Widgets for Site Origin
#wp-force-https : Forces the site to use https, remove this move to install but not activate if not using SSL
#stop-user-enumeration : Security, prevents yoursite.com/?author=1 from giving away root login name
#olevmedia-shortcodes : Allows accordions, columns, and more. Responsive, uses shortcodes.

declare -a arr=("all-in-one-seo-pack" "async-javascript" "autoptimize" "baw-login-logout-menu" "black-studio-tinymce-widget" "tiny-compress-images" "contact-form-7" "contact-form-7-accessible-defaults" "login-lockdown" "ml-slider" "siteorigin-panels" "remove-category-url" "remove-query-strings-from-static-resources" "so-widgets-bundle" "codelights-shortcodes-and-widgets" "widgets-for-siteorigin" "wp-force-https" "stop-user-enumeration" "olevmedia-shortcodes")
for i in "${arr[@]}"
do

	wp plugin install $i --activate 


done

###Plugins to install but not activate (require further config)
#
# cdn-enabler : Set up to use a CDN of your choice
# easy-wp-smtp : Set up your site to use a smtp e-mail (gmail, or gapps)
# wps-hide-login : changes /wp-login.php, /wp-admin/ to something custom of your choice. Prevents most brute force attacks by hiding login screen
# google-apps-login : Allows login using oAuth google account instead of password

declare -a twoarr=("cdn-enabler" "easy-wp-smtp" "wps-hide-login" "google-apps-login")
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

chmod -R 777 $DOCUMENT_ROOT


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
wp option add aj_exclusions jquery.min.js,public-main.min.js,pikaday-jquery.min.js,moment.min.js,checkout.js,pikaday.min.js,public-main.min.js,jquery.js 

#copies .htaccess file provided to your wordpress folder. Make sure the .htaccess is in the same file as this script runs from. (I used /var/www/other-scripts, you can modify as needed).
cp /var/www/other-scripts/.htaccess $DOCUMENT_ROOT/.htaccess

