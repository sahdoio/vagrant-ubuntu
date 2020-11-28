#!/bin/bash

 

log_file=/tmp/vagrantup.log

exec &> >(tee -a "$log_file")

 

common_packages=(curl git unzip make gcc build-essential make libpng-devel rsync openssh-clients zip unzip wget)

 

configure_resolvconf()

{

  sudo sh -c 'echo "nameserver 10.111.15.10" > /etc/resolvconf/resolv.conf.d/base'

  sudo sh -c 'echo "nameserver 10.111.15.11" >> /etc/resolvconf/resolv.conf.d/base'

  sudo resolvconf -u

}

 

install_commom_packages()
{
  sudo apt-get -y install ${common_packages[@]}
}

 
install_php_packages()
{

  which php > /dev/null

  if [ $? -ne 0 ]; then

    sudo apt-get install software-properties-common

    sudo add-apt-repository ppa:ondrej/php

    sudo apt-get update

 

    sudo apt-get -y install php7.3

    php_packages=(libapache2-mod-php php-cli php-cgi php-soap php-xml php-common php-json php-mysql php-mbstring php-mcrypt php-zip php-fpm php-gd)

 

    sudo apt-get -y install ${php_packages[@]}

    sudo a2enmod proxy_fcgi setenvif

    sudo a2enconf php7.3-fpm

    sudo systemctl restart apache2.service

  else

    echo "PHP packages are already installed!"

  fi
}

 

install_composer()

{

  install_dir=/home/vagrant/composer

  if [ ! -d "$install_dir" ]; then

    EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"

    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"

    ACTUAL_SIGNATURE="$(php -r "echo hash_file('SHA384', 'composer-setup.php');")"

 

    if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then

        >&2 echo 'ERROR: Invalid installer signature'

        rm -rf composer-setup.php

        exit 1

    fi

 

    mkdir -p $install_dir

    php composer-setup.php --install-dir=$install_dir

    rm -rf composer-setup.php

    echo "alias composer=\"$install_dir/composer.phar\"" >> /home/vagrant/.bashrc

  else

    echo "Composer is already installed!"

  fi

 

}

 

install_redis()

{

  which redis-server > /dev/null

  if [ $? -ne 0 ]; then

    redis_file="redis-stable.tar.gz"

    if [ ! -f "$redis_file" ]; then

      wget http://download.redis.io/redis-stable.tar.gz

    fi

    tar xzf $redis_file

    pushd redis-stable

    make distclean

    make

    sudo make install

    popd

    rm -rf redis-stable

  else

    echo "Redis is already installed!"

  fi

}

 

install_docker()

{

  which docker > /dev/null

  if [ $? -ne 0 ]; then

  sudo apt-get -y remove docker docker-engine docker.io

  sudo apt-get -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common

  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

  sudo apt-get update

  sudo apt-get -y install docker-ce docker-ce-cli containerd.io

  sudo curl -L https://github.com/docker/compose/releases/download/1.21.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose

  sudo chmod +x /usr/local/bin/docker-compose

  sudo usermod -aG docker vagrant

  else

    echo "Docker is already installed!"

  fi

}

 

install_node_yarn()

{

  curl -sL https://deb.nodesource.com/setup_11.x | sudo -E bash -

  apt-get install -y nodejs

 

  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -

  echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

  sudo apt update

  sudo apt install -y yarn

}

 

install_ansible() {

  apt install software-properties-common

  apt-add-repository -y ppa:ansible/ansible

  apt update

  apt install -y ansible

}

 

install_gplusplus() {

  sudo apt update

  sudo apt install -y g++

  sudo apt install -y make

  sudo apt install -y build-essencial

  sudo apt-get install -y libpng-dev

  sudo yarn global add cross-env

  sudo /bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=1024

  sudo /sbin/mkswap /var/swap.1

  sudo /sbin/swapon /var/swap.1

}

 

install_mysql()

{

  which mysql > /dev/null

  if [ $? -ne 0 ]; then

    #Removes previously installation if it exists

    sudo apt-get -y remove --purge mysql*

    sudo apt-get -y purge mysql*

    sudo apt-get -y autoremove

    sudo apt-get -y autoclean

    sudo apt-get -y remove dbconfig-mysql

 

    # Download and Install the Latest Updates for the OS

    sudo apt-get -y update

 

    # Enable Ubuntu Firewall and allow SSH & MySQL Ports

    sudo ufw allow 22

    sudo ufw allow 3306

 

    # Install essential packages

    sudo apt-get -y install zsh htop

 

    # Install MySQL Server in a Non-Interactive mode. Default root password will be "root"

    echo "mysql-server mysql-server/root_password password root" | sudo debconf-set-selections

    echo "mysql-server mysql-server/root_password_again password root" | sudo debconf-set-selections

    sudo apt-get -y install mysql-server

 

    sudo sed -i 's/127\.0\.0\.1/0\.0\.0\.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf

    sudo mysql -uroot -proot -e 'USE mysql; UPDATE `user` SET `Host`="%" WHERE `User`="root" AND `Host`="localhost"; DELETE FROM `user` WHERE `Host` != "%" AND `User`="root"; FLUSH PRIVILEGES;'

 

    sudo /etc/init.d/mysql restart

  else

    echo "MySQL is already installed!"

  fi

}

 

install_client_tools()

{

  which ecl > /dev/null

  if [ $? -ne 0 ]; then

    curl https://edgecastcdn.net/00423A/releases/CE-Candidate-7.0.2/bin/clienttools/hpccsystems-clienttools-community_7.0.2-1xenial_amd64.deb > /usr/local/etc/clienttools.deb

    cd /usr/local/etc

    sudo dpkg -i clienttools.deb

    sudo apt-get -y update

    sudo apt-get -y -f install

  else

    echo "Client Tools is already installed!"

  fi

}

 

echo "###########################"

echo "Replacing resolv.conf"

echo "###########################"

configure_resolvconf

echo "###########################"

 

echo "###########################"

echo "Installing common packages..."

echo "###########################"

install_commom_packages

echo "###########################"

 

echo "###########################"

echo "Installing PHP packages..."

echo "###########################"

install_php_packages

echo "###########################"

 

echo "###########################"

echo "Installing Composer..."

echo "###########################"

install_composer

echo "###########################"

 

echo "###########################"

echo "Installing Docker..."

echo "###########################"

install_docker

echo "###########################"

 

echo "###########################"

echo "Installing Node and Yarn..."

echo "###########################"

install_node_yarn

echo "###########################"

 

echo "###########################"

echo "Installing Ansible..."

echo "###########################"

install_ansible

echo "###########################"

 

echo "###########################"

echo "Installing g++ and other missing stuffs"

echo "###########################"

install_gplusplus

echo "###########################"

 

echo "###########################"

echo "Installing MySQL"

echo "###########################"

install_mysql

echo "###########################"

 

echo "###########################"

echo "Installing Client Tools"

echo "###########################"

install_client_tools

echo "###########################"

 

sudo systemctl stop apache2

sudo systemctl disable apache2

 
