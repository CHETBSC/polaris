#!/bin/bash
# Written by: Richard Gonsuron
# Copyright: 2020, Polaris Guidance Systems, LLC
# All rights reserved.
clear
HASWSL='false'
if [[ -d /mnt/wsl || -d /mnt/c ]]; then
	HASWSL='true'
fi
echo "
# ********************************************************************
# Polaris Guidance Systems, LLC - Automated Software Installation
# ********************************************************************
# Copyright Notice: This software is owned by
# Polaris Guidance Systems, LLC (“Polaris”) in its entirety, and is
# protected by copyright, trademark, and other intellectual property laws."

# if [[ "$HASWSL" == "false" ]]; then
# echo "# By downloading this software you acknowledge and agree that it may only
# # be used in conjunction with proper licensing and any other use is
# # strictly prohibited by law. For greater certainty and to eliminate any
# # doubt, you are advised and acknowledge and agree that you shall not
# # adapt, edit, change, transform, publish, republish, copy, distribute
# # or redistribute this software (in any form or media).  Polaris takes
# # the protection of its copyright very seriously and in the event that
# # Polaris discovers that you have used its copyright materials in
# # contravention of the terms and conditions set forth above, Polaris may
# # bring legal proceedings against you seeking monetary damages, legal
# # costs and an injunction to prohibit you from engaging in any further
# # breach or non-performance of such terms and conditions. 
# # ******************************************************************** "
# fi

passwd='polaris'
ubuntuver=`lsb_release -sr`
echo
echo
echo "This will install the Polaris software and it's required applications"
if [[ "$HASWSL" == "true" ]]; then
	echo "The Polaris applications will be installed on Windows Subsystem for Linux (WSL)"
fi
echo -n "Continue? y|n: "
read r
if [[ "$r" != "y" ]]; then
	exit 1
fi

BIN=/usr/bin/apt-get
OPTIONS=" -y -q -q -q -q "
NULLOUT=" >/dev/null 2>&1"

echo "Fetching latest package list..."
echo $passwd | sudo -S apt-get $OPTIONS  update >/dev/null 2>&1 || exit 1

# echo
# echo -n "Update the Ubuntu Operating system? y|n: "
# read r
# if [[ "$r" == "y" ]]; then
# echo "Updating Ubuntu operating system"
# echo $passwd | sudo -S apt-get $OPTIONS upgrade || exit 1
# fi

echo $passwd | sudo -S apt-get $OPTIONS install facter >/dev/null 2>&1
ISVIRT=`facter is_virtual`
kmajor=`uname -r | cut -d '.' -f 1`
kminor=`uname -r | cut -d '.' -f 2`
if [[ "$HASWSL" == "false" && "$kmajor" != "" && "$ISVIRT" == "true" ]]; then
	echo $passwd | sudo -S apt-get $OPTIONS install open-vm-tools
	if [[ $kmajor -le 4 || ( $kmajor -eq 5 && $kminor -lt 4 ) ]]; then
		echo "Installing latest kernel for this virtual machine..."
		cd /tmp/
		wget -q -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4/linux-headers-5.4.0-050400_5.4.0-050400.201911242031_all.deb
		wget -q -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4/linux-headers-5.4.0-050400-generic_5.4.0-050400.201911242031_amd64.deb
		wget -q -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4/linux-image-unsigned-5.4.0-050400-generic_5.4.0-050400.201911242031_amd64.deb
		wget -q -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.4/linux-modules-5.4.0-050400-generic_5.4.0-050400.201911242031_amd64.deb
		sudo dpkg -i *.deb
		sudo rm -rf *.deb
		cd -
	fi
	sudo apt-get $OPTIONS remove unattended-upgrades
fi

echo "Installing Microsoft TTF fonts..."
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections
sudo apt-get $OPTIONS install ttf-mscorefonts-installer >/dev/null 2>&1


echo "Installing Java 8 runtime..."
echo $passwd | sudo -S apt-get $OPTIONS install openjdk-8-jre >/dev/null || exit 1

echo "Installing Postgresql database and libraries..."
echo $passwd | sudo -S apt-get $OPTIONS install postgresql postgresql-contrib libpq-dev >/dev/null || exit 1

echo "Installing Apache WEB Server and libraries..."
echo $passwd | sudo -S apt-get $OPTIONS install apache2 libapache2-mod-php libmcrypt-dev >/dev/null || exit 1

echo "Installing other required libraries..."
echo $passwd | sudo -S apt-get $OPTIONS install libnet-ssleay-perl libio-socket-ssl-perl pslib1 libssh2-1 libncurses5-dev libncursesw5-dev libmemcached-dev cutycapt zlibc net-tools >/dev/null || exit 1

echo "Installing PHP and libraries..."
echo $passwd | sudo -S apt-get $OPTIONS install php php-pgsql php-gd php-zip php-fpdf php-pear php-imap php-soap libphp-phpmailer php-memcached php-tcpdf php-dev php-imagick php-curl >/dev/null || exit 1

echo "Installing required applications..."
echo $passwd | sudo -S apt-get $OPTIONS install texlive-extra-utils gnuplot zip unzip sendemail dialog lsb memcached setserial ssh sshpass composer imagemagick >/dev/null || exit 1

if [[ "$HASWSL" == "true" ]]; then
	echo $passwd | sudo -S apt-get $OPTIONS install monit >/dev/null || exit 1
fi



echo "Installing pecl applications..."
sudo pecl -q -q channel-update pecl.php.net >/dev/null
ok=`pecl list mcrypt | grep -i mcrypt`
if [[ -z "$ok" ]]; then
	sudo pecl -q -q install mcrypt-1.0.1 >/dev/null
fi
# NOTE: include mcrypt.so in php.ini

if [[ "$ubuntuver" == '16.04' ]]; then
	echo $passwd | sudo -S apt-get $OPTIONS install "libhpdf-2.2.1" >/dev/null
	# sudo apt-get -y -q install pdftk
else
	echo $passwd | sudo -S apt-get $OPTIONS install "libhpdf-2.3.0" >/dev/null
	# sudo snap install pdftk
fi

# echo "Checking for Logmein Hamachi VPN service..."
if [[ ! -f /etc/init.d/logmein-hamachi ]]; then
	echo "Installing the latest Logmein-Hamachi version"
	HAMFILE="logmein-hamachi.deb"
	sudo wget -qO- "http://www.polarisguidance.com/install/$HAMFILE" >$HAMFILE
	if [[ -f $HAMFILE ]]; then
		sudo dpkg -i $HAMFILE >/dev/null 2>&1
		sudo rm -f $HAMFILE 
	fi
fi
# make sure apache has access to hamachi vpn
if [[ -d /var/lib/logmein-hamachi ]]; then
	h2file="/var/lib/logmein-hamachi/h2-engine-override.cfg"
	if [[ ! -f $h2file ]]; then
		echo $passwd | sudo -S bash -c "echo 'Ipc.User www-data
Ipc.User polaris' >$h2file"
	else
		hasoverride=`grep 'Ipc.User www-data' $h2file`
		if [[ "$hasoverride" == "" ]]; then
		echo $passwd | sudo -S bash -c "echo 'Ipc.User www-data
Ipc.User polaris' >$h2file"
		fi
	fi
fi

# echo "Checking if Desktop installed... "
ISDESKTOP='no'
if dpkg-query -W -f'${Status}' "firefox" 2>/dev/null | grep -q "ok installed"; then
	ISDESKTOP='yes'
fi
if [[ "$ISDESKTOP" == "yes" ]]; then
	if [[ "$ISVIRT"=="true" ]]; then
		echo $passwd | sudo -S apt-get $OPTIONS install open-vm-tools-desktop
	fi
	echo $passwd | sudo -S apt-get $OPTIONS install firefox thunderbird gnome-software 
	echo "Desktop detected: Installing IrFanView image viewing application"
	sudo snap install irfanview $NULLOUT
	sudo apt-get $OPTIONS install gtkterm zenity
else
	# echo "No Desktop environment installed: Setting up autologin and menu"
	HASRDSCP="$(grep rdscp ~/.profile)"
	if [[ -z "$HASRDSCP" ]]; then
		echo "rdscp" >>.profile
	fi
#auto login
	dir="/etc/systemd/system/getty@tty1.service.d"
	if [[ ! -d $dir ]]; then
		sudo mkdir $dir
	fi
	file="/etc/systemd/system/getty@tty1.service.d/override.conf"
	sudo bash -c "echo \"[Service]
ExecStart=
ExecStart=-/sbin/agetty --noissue --autologin polaris %I linux
Type=idle\" >$file"
fi

echo "Installation of Linux applications complete"
pver=`php --version | head -n 1 | cut -d " " -f 2 | cut -c 1,3`
phpver=`echo "scale=1; $pver/10" | bc -l` 


echo "Configuring applications..."

sudo service memcached stop
if [[ -f "/etc/memcached.conf" ]]; then
	sudo sed -i 's/^-l/# -l/g' /etc/memcached.conf
fi
sudo service memcached start
if [[ -f /etc/ssh/sshd_config ]]; then
	sudo sed -i "s/.*Port 22/Port 1984/g" /etc/ssh/sshd_config || exit 1
	if ! cat /etc/ssh/sshd_config | grep -q "AllowUsers polaris@10"; then
		sudo bash -c "echo 'AllowUsers polaris@10.0.0.0/8' >>/etc/ssh/sshd_config"
	fi
	if ! cat /etc/ssh/sshd_config | grep -q "AllowUsers polaris@25"; then
		sudo bash -c "echo 'AllowUsers polaris@25.0.0.0/8' >>/etc/ssh/sshd_config"
	fi
	if ! cat /etc/ssh/sshd_config | grep -q "AllowUsers polaris@192"; then
		sudo bash -c "echo 'AllowUsers polaris@192.0.0.0/8' >>/etc/ssh/sshd_config"
	fi
	if ! cat /etc/ssh/sshd_config | grep -q "AllowUsers polaris@172"; then
		sudo bash -c "echo 'AllowUsers polaris@172.0.0.0/8' >>/etc/ssh/sshd_config"
	fi
fi
if [ -f /etc/ImageMagick-6/policy.xml ]; then
	sudo mv /etc/ImageMagick-6/policy.xml /etc/ImageMagick-6/policy.xmlout
fi
if [[ "$HASWSL" == "false" &&  -f "/etc/systemd/system.conf" ]]; then
	sudo sed -i 's/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=4s/g' /etc/systemd/system.conf
fi
phpini="/etc/php/$phpver/apache2/php.ini"
cliphpini="/etc/php/$phpver/cli/php.ini"
maxinpvars='s/; *max_input_vars.*/max_input_vars = 10000/g'
maxexec='s/max_execution_time.*/max_execution_time = 1200/g'
maxinput='s/max_input_time.*/max_input_time = 180/g'
memlimit='s/memory_limit.*/memory_limit = 512M/g'
errrpt='s/error_reporting.*/error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_NOTICE/g'
logerr='s/log_errors.*/log_errors = Off/g'
postmax='s/post_max_size.*/post_max_size = 200M/g'
magic='s/magic_quotes_gpc.*/magic_quotes_gpc = On/g'
uploadsz='s/upload_max_filesize.*/upload_max_filesize = 200M/g'
uploadmax='s/max_file_uploads.*/max_file_uploads = 100/g'
shorttag='s/short_open_tag.*/short_open_tag = On/g'
zlib='s/zlib.output_compression.*/zlib.output_compression = On/g'
sudo sed -i "$maxinpvars;$maxexec;$maxinput;$memlimit;$errrpt;$logerr;$postmax;$magic;$uploadsz;$uploadmax;$shorttag;$zlib" $phpini || exit 1
sudo sed -i "$maxinpvars;$maxexec;$maxinput;$memlimit;$errrpt;$logerr;$postmax;$magic;$uploadsz;$uploadmax;$shorttag;$zlib" $cliphpini || exit 1
phpconf="/etc/php/$phpver/fpm/php.ini"
if [[ -f $phpconf ]]; then
	sudo sed -i "s/log_errors = [Oo]n/log_errors = Off/g" $phpconf
fi
apachesecfile='/etc/apache2/conf-available/security.conf'
svrtok='s/ServerTokens.*/ServerTokens Prod/g'
svrsig='s/ServerSignature.*/ServerSignature Off/g'
sudo sed -i "$svrtok;$svrsig" $apachesecfile || exit 1

# echo "Apache site configuration"

WWWDIR=/home/www-data
if [[ ! -d $WWWDIR ]]; then
	sudo mkdir /home/www-data
	sudo chown -R www-data:www-data /home/www-data
#	if [[ ! -L /var/www/html ]]; then sudo rm -rf /var/www/html; fi
#	sudo ln -s /home/www-data /var/www/html
fi
WWWTMP=/home/www-data/tmp
if [[ ! -L $WWWTMP ]]; then
	sudo ln -s /tmp $WWWTMP || exit 1
fi

if [[ -f /lib/systemd/system/apache2.service ]]; then
sudo sed -i "s/PrivateTmp\=true/PrivateTmp\=false/g" /lib/systemd/system/apache2.service || exit 1
fi
sudo find /etc/apache2/sites-enabled/000* -exec sed -i 's/#*[Cc]ustom[Ll]og/#CustomLog/g' {} \;
sudo find /etc/apache2/sites-enabled/000* -exec sed -i 's/#*[Ee]rror[Ll]og/#ErrorLog/g' {} \;
sudo find /etc/apache2/sites-enabled/000* -exec sed -i 's/DocumentRoot.*/DocumentRoot \/home\/www-data/g' {} \;
sudo find /etc/apache2/apache2.conf -exec sed -i 's/<Directory \/var\/www.*/<Directory \/home\/www-data\/>/g' {} \;
sudo phpenmod zip

# echo "Configuring Postgresql"
sudo service postgresql stop
pghba=`find /etc/postgresql -name pg_hba.conf`
peer='s/peer$/trust/g'
md5='s/md5$/trust/g'
sudo sed -i "$peer;$md5" $pghba || exit 1
# disable Postgres logging
pgconf=`find /etc/postgresql -name postgresql.conf`
sudo sed -i "s/#log_min_duration_statement.*$/log_min_duration_statement = -1/g" $pgconf
sudo sed -i "s/#log_min_messages.*$/log_min_messages = panic/g" $pgconf
sudo rm -rf /var/log/postgresql/*
sudo service postgresql start || exit 1

# echo "Creating password for postgres: "
echo "postgres:postgres" | sudo chpasswd

sudo createuser -U postgres --superuser --no-password  2>/dev/null
sudo createuser -U postgres umsdata --superuser --no-password 2>/dev/null
sudo createuser -U postgres jobbox --superuser --no-password 2>/dev/null
# createdb -U umsdata umsdata

# lets quiet things down a bit
sudo sed -i "s/\$IncludeConfig/# \$IncludeConfig/g" /etc/rsyslog.conf
sudo find /var/log -name *.gz -exec rm -f {} \;
sudo find /var/log -name "*.1" -exec rm -f {} \;
if [[ ! -f /etc/rc.local ]]; then
	sudo bash -c "echo \"dmesg -D\" >/etc/rc.local"
else
	ret="$(grep "dmesg -D" /etc/rc.local)"
	if [[ -z "$ret" ]]; then
		sudo bash -c "echo \"dmesg -D\" >>/etc/rc.local"
	fi
fi
sudo sed -i "s/#kernel.printk.*/kernel.printk = 3 4 1 3/g" /etc/sysctl.conf
# even quieter
sudo touch ~/.hushlogin
FILE="/etc/issue"
if [[ -f $FILE || -d $FILE ]]; then sudo rm -rf $FILE; fi
FILE="/etc/cloud/cloud.cfg.d/90_dpkg.cfg"
if [[ -f "$FILE" ]]; then
	echo 'datasource_list: [ None ]' | sudo -s tee $FILE
fi
sudo apt-get $OPTIONS purge cloud-init >/dev/null
FILE="/etc/cloud"
if [[ -d $FILE ]]; then sudo rm -rf $FILE; fi
FILE="/var/lib/cloud"
if [[ -d $FILE ]]; then sudo rm -rf $FILE; fi

sudo service apache2 stop
sudo usermod -d /home/www-data www-data >/dev/null
sudo service apache2 start
sudo usermod -a -G dialout www-data >/dev/null
sudo usermod -a -G dialout polaris >/dev/null
sudo adduser www-data sudo >/dev/null
sudo usermod -a -G sudo www-data >/dev/null
echo "www-data:www-data" | sudo chpasswd >/dev/null
echo "Configuration complete"
if [ ! -f vmupdate.zip ]; then
	echo "Downloading the latest Polaris software..."
	wget -q http://www.polarisguidance.com/update/vmupdate.zip
	echo "Extracting downloaded update package..."
	unzip vmupdate.zip
	echo "Installing update package..."
	sudo bash -c "cd vmupdate; ./install"
	rm -rf vmupdate*
else
	echo "Extracting local update package..."
	unzip vmupdate.zip
	echo "Installing update package..."
	sudo bash -c "cd vmupdate; ./install"
	rm -rf vmupdate
fi

echo
echo "Installation of Polaris software is complete"
echo
if [[ "$HASWSL" == "false" ]]; then
	echo -n "Reboot now? y|n: "
	read r
	if [[ "$r" == "y" ]]; then
		sudo reboot
	fi
fi
echo "Press ENTER to continue:"
read r
