#!/bin/bash

check_exit_status() {

	if [ $? -eq 0 ]
	then
		echo
		echo "Success"
		echo
	else
		echo
		echo "[ERROR] Process Failed!"
		echo
		
		read -p "The last command exited with an error. Exit script? (yes/no) " answer

            if [ "$answer" == "yes" ]
            then
                exit 1
            fi
	fi
}


update() {

    sudo apt-get update;
	check_exit_status

    sudo apt-get upgrade -y;
	check_exit_status

    sudo apt-get dist-upgrade -y;
	check_exit_status
}

housekeeping() {

	sudo apt-get autoremove -y;
	check_exit_status

	sudo apt-get autoclean -y;
	check_exit_status

	sudo updatedb;
	check_exit_status
}

apache_install() {
    sudo apt-get install apache2 -y;
    check_exit_status
    
    echo "Next, we will add a single line to the /etc/apache2/apache2.conf file to suppress a warning message."
    check_exit_status
    
    read -p "Add: 'ServerName server_domain_or_IP' to the bottom of /etc/apache2/apache2.conf" apache_answer
    check_exit_status
    
    sudo nano /etc/apache2/apache2.conf
    check_exit_status
    
    sudo systemctl restart apache2
    check_exit_status
    
    sudo systemctl status apache2
    check_exit_status
}

ufw_config() {
    sudo ufw enable
    check_exit_status
    
    sudo ufw allow OpenSSH
    check_exit_status
    
    sudo ufw allow in "Apache Full"
    check_exit_status
}

mysql_install() {
    sudo apt-get install mysql-server -y
    check_exit_status
    
    sudo mysql_secure_installation
    check_exit_status
    
    echo ""
    echo "CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
    read -p "Next, configure the database for wordpress by copying the command above and entering it in mysql. " create_database
    
    sudo mysql -u root -p
    
    echo ""
    echo "GRANT ALL ON wordpress.* TO 'wordpressuser'@'localhost' IDENTIFIED BY 'password';"
    read -p "Next, configure permissions for wordpress user by copying the command above and entering it into mysql then flush privileges. " wp_user
    
    sudo mysql -u root -p
}

php_install() {
    sudo apt-get install php libapache2-mod-php php-mcrypt php-mysql -y
    check_exit_status
    
    sudo apt-get install php-curl php-gd php-mbstring php-mcrypt php-xml php-xmlrpc -y
    check_exit_status
    
    echo ""
    echo "Next, opening /etc/apache2/mods-enabled/dir.conf"
    echo "Move index.php to first in line."
    read -p "Press Enter to continue" php_answer
    
    sudo nano /etc/apache2/mods-enabled/dir.conf
    
    sudo systemctl restart apache2
    check_exit_status
    
    sudo systemctl status apache2
    check_exit_status
}

hta_overwrite() {
    echo ""
    echo "<Directory /var/www/html/> AllowOverride All </Directory>"
    read -p "Next, copy the text above and insert it into /etc/apache2/apache2.conf. Split the copied text at tags and put on own lines in file. " hta_over
    
    sudo nano /etc/apache2/apache2.conf
    
    sudo a2enmod rewrite
    check_exit_status
    
    sudo systemctl restart apache2
    check_exit_status
}

wp_setup() {
    cd /tmp
    curl -O https://wordpress.org/latest.tar.gz
    check_exit_status
    
    tar xzvf latest.tar.gz
    check_exit_status
    
    touch /tmp/wordpress/.htaccess
    check_exit_status
    
    chmod 660 /tmp/wordpress/.htaccess
    check_exit_status
    
    cp /tmp/wordpress/wp-config-sample.php /tmp/wordpress/wp-config.php
    check_exit_status
    
    mkdir /tmp/wordpress/wp-content/upgrade
    check_exit_status
    
    sudo cp -a /tmp/wordpress/. /var/www/html
    check_exit_status
    
    sudo chown -R ubuntu:www-data /var/www/html
    check_exit_status
    
    sudo find /var/www/html -type d -exec chmod g+s {} \;
    check_exit_status
    
    sudo chmod g+w /var/www/html/wp-content
    check_exit_status
    
    sudo chmod -R g+w /var/www/html/wp-content/themes
    check_exit_status
    
    sudo chmod -R g+w /var/www/html/wp-content/plugins
    check_exit_status
    
    echo ""
    read -p "Next, you must copy the output that comes next. Enter to continue. " copy_secrets
    
    curl -s https://api.wordpress.org/secret-key/1.1/salt/
    
    read -p "Copy the lines above. Enter to continue. " copied_secrets
    echo ""
    
    read -p "Paste the text you copied into the file opening next. Enter to continue " pasting
    read -p "Also you must adjust mysql settings to reflect creds made earlier. Enter to continue. " pasting_two
    nano /var/www/html/wp-config.php
    
    echo "define('FS_METHOD', 'direct');"
    read -p "Copy the text above and insert it into the file that opens next. " pasting_three
    nano /var/www/html/wp-config.php
    
    sudo chown -R www-data:www-data /var/www
    
    echo ""
    echo "Wordpress Installation Finished!"
    echo ""
    
    cd ~
}

update
housekeeping
apache_install
ufw_config
mysql_install
php_install
hta_overwrite
wp_setup
