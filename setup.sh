#!/bin/bash
source scripts/nextman-functions
if ! HasSudo; then
	exit
fi

DIRECTORY=$(cd `dirname $0` && pwd)
defaultDir="/var/www/nextcloud"
defaultPort="8090"
defaultDBPort="3306"
zipFileLink="https://download.nextcloud.com/server/releases/latest.zip"
apacheNcConf="configs/nextcloud.conf"
nextcloudCronService="configs/nextcloudcron.service"
nextcloudCronTimer="configs/nextcloudcron.timer"
nextcloudUpdate="scripts/nextcloud-update.sh"
scanFiles="scripts/scanFiles.sh"
hasSELinux=false
apacheLocation=""
apacheUser=""

Update()
{
	nextman -S
	
}

InstallDependencies()
{
	packagesNeededRHEL="cronie fastlz liblzf libmemcached-awesome httpd php php-fpm php-cli php-mysqlnd php-gd php-xml php-mbstring php-json php-curl php-zip php-bcmath php-gmp php-intl php-ldap php-pecl-apcu php-pecl-igbinary php-pecl-imagick php-pecl-memcached php-pecl-msgpack php-pecl-redis5 php-smbclient php-process php-imagick php-redis php-opcache redis mariadb mariadb-server unzip curl wget bash-completion policycoreutils-python-utils mlocate bzip2"
	packagesNeededDebian="cron lz4 liblzf-dev libmemcached-dev apache2 php php-fpm php-cli php-mysql php-gd php-xml php-mbstring php-json php-curl php-zip php-bcmath php-gmp php-intl php-ldap php-apcu php-igbinary php-imagick php-memcached php-msgpack php-redis php-smbclient php-process php-imagick php-redis php-opcache redis-server mariadb-server unzip curl wget bash-completion policykit-1 mlocate bzip2"
	packagesNeededArch="cronie lz4 lib32-libmemcached apache php php-fpm php-cli php-gd php-mbstring php-json php-curl php-zip php-bcmath php-gmp php-intl php-apcu php-igbinary php-imagick php-memcached php-msgpack php-redis php-smbclient php-imagick php-redis php-opcache redis mariadb mariadb-clients unzip curl wget bash-completion polkit mlocate bzip2"
	packagesNeededOpenSuse="cron fastlz liblzf1 libmemcached apache2 php php-fpm php-cli php-mysql php-gd php-xml php-mbstring php-json php-curl php-zip php-bcmath php-gmp php-intl php-ldap php7-apcu php7-igbinary php7-imagick php7-memcached php7-msgpack php7-redis php-smbclient php-process php-imagick php-redis php-opcache redis mariadb mariadb-client unzip curl wget bash-completion policycoreutils mlocate bzip2"

	echo "> Preparing to install needed dependancies for LLaman and Open-WebUI..."

	if [[ -f /etc/os-release ]]; then
		source /etc/os-release
		crbOrPowertools=
		osDetected=true
		echo "> ID=$ID"
		
		if [[ $ID_LIKE == .*"rhel".* ]] || [[ $ID == "rhel" ]]; then
			ID=rhel
			
			if [[ $VERSION_ID == *"."* ]]; then
				VERSION_ID=$(echo $VERSION_ID | cut -d "." -f 1)
			fi
			
			if (( $VERSION_ID < 9 )); then
				crbOrPowertools="powertools"
			else
				crbOrPowertools="crb"
			fi
		fi
		
			case "$ID" in
				fedora)	dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
						dnf install $packagesNeededRHEL -y
						apacheLocation="/etc/httpd/conf.d" 
						hasSELinux=true ;;
				rhel)	dnf install epel-release -y
						dnf config-manager --set-enabled $crbOrPowertools
						dnf install --nogpgcheck https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm -y https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E %rhel).noarch.rpm -y
						dnf install $packagesNeededRHEL -y
						apacheLocation="/etc/httpd/conf.d"
						hasSELinux=true ;;
				debian|ubuntu|linuxmint|elementary)
						apt install $packagesNeededDebian -y
						apacheLocation="/etc/apache2/sites-available";;
				arch|endeavouros|manjaro)
						pacman -Syu $packagesNeededArch
						apacheLocation="/etc/httpd/sites-available" ;;
				opensuse*)		zypper install $packagesNeededOpenSuse
						apacheLocation="/etc/httpd/conf.d"
						hasSELinux=true ;;
			esac
	else
		osDetected=false
		echo "+-------------------------------------------------------------------+"
		echo "|                       ******WARNING******                         |"
		echo "|                        ******ERROR******                          |"
		echo "|               FAILED TO FIND /etc/os-release FILE.                |"
		echo "+-------------------------------------------------------------------+"
		
		echo "> Please manually install the following dependencies:"
		echo "$packagesNeededRHEL"
		read -p "Press ENTER to continue" ENTER
	fi
	if id -u apache &>/dev/null; then
		apacheUser="apache"
	elif id -u www-data &>/dev/null; then
		apacheUser="www-data"
	else
		echo "+---------------------------------------------------+"
		echo "|               ******WARNING******                 |"
		echo "|              Apache user not found.               |"
		echo "|   Please ensure either 'apache' or 'www-data'     |"
		echo "| user exists, or manually configure the user below.|"
		echo "+---------------------------------------------------+"
		read -p "Press ENTER to acknowledge and continue" ENTER
	fi
}

ConfigureFirewall() {
    echo "> Configuring firewall rules..."

    if command -v firewall-cmd &>/dev/null; then
        echo "> Detected firewalld. Configuring rules..."
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-port=$defaultPort/tcp
        firewall-cmd --permanent --add-port=$defaultDBPort/tcp
        firewall-cmd --reload

    elif command -v ufw &>/dev/null; then
        echo "> Detected UFW. Configuring rules..."
        ufw allow http
        ufw allow $defaultPort/tcp
        ufw allow $defaultDBPort/tcp
        ufw reload

    else
        echo "+-------------------------------------------------+"
        echo "|               ******WARNING******               |"
        echo "|        Firewall service not detected.           |"
        echo "| Please manually configure the following ports:  |"
        echo "|   - HTTP (port 80)                              |"
        echo "|   - Nextcloud (port $defaultPort)                       |"
        echo "|   - MariaDB (port $defaultDBPort)                         |"
        echo "+-------------------------------------------------+"
        read -p "Press ENTER to acknowledge and continue" ENTER
    fi
    
    if $hasSELinux; then
		semanage fcontext -a -t httpd_sys_rw_content_t '$defaultDir/config(/.*)?'
		semanage fcontext -a -t httpd_sys_rw_content_t '$defaultDir/apps(/.*)?'
		semanage fcontext -a -t httpd_sys_rw_content_t '$defaultDir/.htaccess'
		semanage fcontext -a -t httpd_sys_rw_content_t '$defaultDir/.user.ini'
		semanage fcontext -a -t httpd_sys_rw_content_t '$defaultDir/3rdparty/aws/aws-sdk-php/src/data/logs(/.*)?'
		restorecon -R '$defaultDir/'
		setsebool -P httpd_can_network_connect on
		chcon -Rt httpd_sys_rw_content_t $defaultDir/data
		semanage fcontext -a -t httpd_sys_rw_content_t  "$defaultDir/data(/.*)?"
		semanage fcontext -m -t httpd_sys_rw_content_t  "$defaultDir/data(/.*)?"
	fi

}

# PHP Configurations
ConfigurePHP() {
    echo "> Configuring PHP settings..."

    # Detect PHP-FPM configuration directory based on distribution
    if [[ -d "/etc/php-fpm.d" ]]; then
        phpFpmDir="/etc/php-fpm.d"
        phpIni="/etc/php.ini"
        phpFpmConf="$phpFpmDir/www.conf"
        phpUser="apache"
        phpGroup="apache"
        
    elif [[ -d "/etc/php/7.4/fpm/pool.d" ]]; then
        phpFpmDir="/etc/php/7.4/fpm/pool.d"
        phpIni="/etc/php/7.4/fpm/php.ini"
        phpFpmConf="$phpFpmDir/www.conf"
        phpUser="www-data"
        phpGroup="www-data"
        
    elif [[ -d "/etc/php/8.0/fpm/pool.d" ]]; then
        phpFpmDir="/etc/php/8.0/fpm/pool.d"
        phpIni="/etc/php/8.0/fpm/php.ini"
        phpFpmConf="$phpFpmDir/www.conf"
        phpUser="www-data"
        phpGroup="www-data"

    elif [[ -d "/etc/php-fpm.d" ]]; then
        phpFpmDir="/etc/php-fpm.d"
        phpIni="/etc/php.ini"
        phpFpmConf="$phpFpmDir/www.conf"
        phpUser="nginx"
        phpGroup="nginx"
    else
        echo "+-------------------------------------------------+"
        echo "|               ******WARNING******               |"
        echo "|         PHP-FPM configuration not found.        |"
        echo "|   Please manually locate and configure PHP.     |"
        echo "+-------------------------------------------------+"
        read -p "Press ENTER to acknowledge and continue" ENTER
        return
    fi

    # Configure php.ini settings
    echo "> Modifying PHP memory limit in $phpIni..."
    sed -ri "s|memory_limit =.*|memory_limit = 512M|g" "$phpIni"

    # Configure PHP-FPM settings
    echo "> Configuring PHP-FPM settings in $phpFpmConf..."
    sed -ri "s|^user =.*|user = $phpUser|g" "$phpFpmConf"
    sed -ri "s|^group =.*|group = $phpGroup|g" "$phpFpmConf"
    sed -ri "s|^listen =.*|listen = /run/php-fpm/www.sock|g" "$phpFpmConf"
    sed -ri "s|^listen.owner =.*|listen.owner = $phpUser|g" "$phpFpmConf"
    sed -ri "s|^listen.group =.*|listen.group = $phpGroup|g" "$phpFpmConf"
    echo "php_value[opcache.interned_strings_buffer] = 8" >> "$phpFpmConf"
}

Setup()
{
	PromptUser usr "Please enter the desired MariaDB user for Nextcloud" 0 0 "username"
	mariadbUser="$promptResult"
	echo
	PromptUser str "Please enter the desired MariaDB password : " 0 0 "string"
	mariadbPass="$promptResult"
	echo
	PromptUser usr "Please enter the desired admin account name for Nextcloud : " 0 0 "username"
	ncAdmin="$promptResult"
	echo
	PromptUser str "Please enter the desired admin account password for Nextcloud : " 0 0 "password"
	ncPass="$promptResult"
	echo

	# Install Dependencies
	InstallDependencies

	# Install Nextcloud
	wget $zipFileLink
	unzip latest.zip -d /var/www/
	mkdir -p $defaultDir/data
	chown -Rf apache:apache $defaultDir
	chmod -Rf 770 $defaultDir
	cp -f scripts/scanFiles.sh scripts/nextcloud-update.sh $defaultDir/data/
	chmod +x $defaultDir/data/*.sh
	cp -f "$apacheNcConf" > /etc/httpd/conf.d/

	ConfigureFirewall
	ConfigurePHP

	## Enable Services
	echo "$nextcloudCronService" > /usr/lib/systemd/system/nextcloudcron.service
	echo "$nextcloudCronTimer" > /usr/lib/systemd/system/nextcloudcron.timer
	systemctl daemon-reload
	systemctl enable --now php-fpm httpd mariadb redis nextcloudcron.service nextcloudcron.timer

	## MariaDB Setup
	mysql_secure_installation

	mysql -e "CREATE USER '${mariadbUser}'@'localhost' IDENTIFIED BY '${mariadbPass}';"
	mysql -e "CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
	mysql -e "GRANT ALL PRIVILEGES on nextcloud.* to '${mariadbUser}'@'localhost';"

	# Install Nextcloud via occ
	chmod -Rf 777 $defaultDir
	cd $defaultDir
	sudo -u $apacheUser php occ maintenance:install --database='mysql' --database-name='nextcloud' --database-user='${mariadbUser}' --database-pass='${mariadbPass}' --admin-user='${ncAdmin}' --admin-pass='${ncPass}'
	cd ~; chmod -Rf 770 $defaultDir

	# Edit $defaultDir/config/config.php
	echo "We must edit the variable 'trusted_domains' in the Nextcloud config.php."
	echo "If we don't then Nextcloud will not allow us access."
	echo "Please enter your desired text editor"
	read -p "example 'vi', 'nano', 'micro' : " editor
	echo "Great! now here is an example for the 'trusted_domains' variable in the config.php :"
	echo
	echo "  'trusted_domains' => 
	  array (
		0 => 'localhost',
		1 => '127.0.0.1',
		2 => 'cloud.YourDomain.com',
		3 => '192.168.1.11:8090',
	  ),
	  'trusted_proxies' => ['127.0.0.1'],
	  'overwritehost' => 'cloud.YourDomain.com',
	  'overwriteprotocol' => 'https',
	  'maintenance_window_start' => 1,"
	echo
	read -p "Press ENTER to start editing. It is recommended that you copy the above code before pressing ENTER" null

	$editor $defaultDir/config/config.php

	## Restart Services
	systemctl restart php-fpm mariadb httpd

	echo
	echo
	echo "All done. Please navigate to http://yourdomain:$defaultPort"
	echo "It is recommended to use caddy to make a reverse proxy to host Nextcloud with https (secure)"
	echo
	echo "To change the user data directory please edit $defaultDir/config/config.php"
	echo "Edit line 'datadirectory' => '$defaultDir/data',"
	echo "Then run:"
	echo '----------------------------------------------------
sudo chcon -Rt httpd_sys_rw_content_t /path/to/new/nextcloud/data
sudo semanage fcontext -a -t httpd_sys_rw_content_t  "/path/to/new/nextcloud/data(/.*)?"
sudo semanage fcontext -m -t httpd_sys_rw_content_t  "/path/to/new/nextcloud/data(/.*)?"
sudo systemctl restart httpd
----------------------------------------------------'
}

if [[ $1 == "-U" ]]; then
	Update
elif [[ $1 == "-I" ]]; then
	Import "$2"
else
	Setup
fi