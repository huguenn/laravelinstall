#!/bin/bash

#swaping space configuration
dd if=/dev/zero of=/swap bs=1M count=2048;mkswap /swap;swapon /swap;echo "/swap swap swap defaults 0 0" >> /etc/fstab

#global values
required_version="5.5.9"
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color


#install lamp stack (apache2, php5, mysql)
echo "Do you want to install apache,php and mysql?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) 
			apt-get update
			apt-get install -y apache2
			apt-get install -y mysql-server
			mysql_secure_installation

			apt-get install -y php5 php-pear
			apt-get install -y php5-mysql
			a2enmod rewrite
			service apache2 restart
		break;;
        No ) break;;
    esac
done

#install phpmyadmin
echo "Do you want to install phpmyadmin?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) 
			apt-get install -y phpmyadmin
			echo "Include /etc/phpmyadmin/apache.conf" >> /etc/apache2/apache2.conf
			service apache2 restart
		break;;
        No ) break;;
    esac
done


#check for php installation
if ! type "php" > /dev/null; then
  echo -e "${RED}You don't have php installed, please install PHP first and then try again${NC}"
  exit 1
fi

#check php version
php_version=$(php -v | grep -P -o -i "PHP (\d+\.\d+\.\d+)" | tr -d "\n\r\f" | sed 's/PHP //g' )

if [[ $php_version < $required_version ]]
then
	echo -e "${RED}You need to upgrade your PHP version to work with Laravel. Required version: $required_version ${NC}"
	exit 1
fi


#check for php extensions
if ! [ "$(php -m | grep -c 'mbstring')" -ge 1 ]; then
	echo -e "${RED}Please enable 'mbstring' php extension to proceed${NC}"
	exit 1
fi 

if ! [ "$(php -m | grep -c 'PDO')" -ge 1 ]; then
	echo -e "${RED}Please enable 'PDO' php extension to proceed${NC}"
	exit 1
fi 

if ! [ "$(php -m | grep -c 'openssl')" -ge 1 ]; then
	echo -e "${RED}Please enable 'openssl' php extension to proceed${NC}"
	exit 1
fi 

if ! [ "$(php -m | grep -c 'tokenizer')" -ge 1 ]; then
	echo -e "${RED}Please enable 'tokenizer' php extension to proceed${NC}"
	exit 1
fi 

#check for composer installation
if ! type "composer" > /dev/null; then
  	echo -e "${RED}You don't have Composer installed.${NC}"

  	echo "Do you want to install composer?"
	select yn in "Yes" "No"; do
	    case $yn in
	        Yes ) 
				echo -e "${GREEN}Installing Composer...${NC}"
				curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
				mv composer.phar /usr/local/bin/composer
			break;;
	        No ) 
				echo -e "${RED}You need to install composer to proceed.${NC}"
			exit 1;;
	    esac
	done
fi


echo -n "Enter a project name: "
read project_name


# if a project name given then work on that otherwise prompt to give a project name
if [ "$project_name" == "" ]; then
	echo -e "${RED}Please give a project name.${NC}"
else
	cd /var/www/html
	composer create-project --prefer-dist laravel/laravel $project_name
	#apache user group permission 
	chown -R www-data.www-data /var/www/$project_name 
	chmod -R 755 /var/www/$project_name
	cd $project_name
	chmod -R 775 storage
	chmod -R 775 bootstrap/cache	
	echo -e "${GREEN}Everything is ready, mate! Create something awesome!${NC}"
fi


#TODO
# laravel version selection when creating
# linux other distros support
# virtual host creation
