# ubuntu-server-wp-bash-scripts

# .htaccess 
(download, and keep in the same folder as your setupsite.sh script)
 
#setupsite-tui.sh (new)

Same as setupsite.sh, but all done through a TUI (whiptail). Options to either use theme or not, use LetsEncrypt or not, and pick which plugins you want to install.
 
# setupsite.sh : 
Designed for Ubuntu 16.04 or other Debian system. Requires LetsEncrypt and WP-CLI to be installed. The DNS MUST be set up for the SSL cert to work correctly.
- Create directory for the site
- Creates an apache sites-available .conf file, and then enables it, before restarting apache.
- Creates SSL certs for the site, suing lets-encrypt auto (*note, you must have your dns set up to point to your server before running this script, if you want this option).
- Creates mysql database and password for your wordpress installation. 
- Downloads latest version of core, makes wp-config.php, and installs wordpress.
- Installs a theme of your choice, and creates a blank child theme from it automatically, before activating.
- Installs and activates a list of pre-selected plugins I use on every site.
- Installs other plugins that I don't want activated yet (CDN Enabler, others that need more config).
- Removes Akismet, Hello Dolly
- Removes Default Themes
- Copies .htaccess to active folder

# .backup-site-to-s3

Requires the following:
- AWS account
- S3 bucket pre-created
- AWS-CLI installed
- AWS-CLI configure run (set your keys, account, etc)
