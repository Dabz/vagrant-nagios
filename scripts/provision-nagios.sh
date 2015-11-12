#!/bin/sh

##
## provision-nagios.sh for Project in /Users/gaspar_d/Projects/vagrant-nagios
##
## Made by Gasparina Damien
## Login   <gaspar_d@epita.fr>
##
## Started on  Fri  6 Nov 13:16:42 2015 Gasparina Damien
## Last update Mon  9 Nov 07:24:10 2015 Gasparina Damien
##

NAGIOS_VERSION=4.1.1
NAGIOS_PLUGIN_VERSION=2.1.1


# Compile & Install Nagios

sudo yum -y install gd gd-devel gcc glibc glibc-common wget httpd
sudo yum -y install php-mysql php-devel php-gd php-pecl-memcache php-pspell php-snmp php-xmlrpc php-xml php xinetd


sudo useradd -m nagios
sudo -s bash -c 'echo nagio | passwd nagios --stdin'

sudo groupadd nagcmd
sudo usermod -a -G nagcmd nagios
sudo usermod -a -G nagcmd apache

cd /vagrant/
tar xzf nagios-$NAGIOS_VERSION.tar.gz
tar xzf nagios-plugins-$NAGIOS_PLUGIN_VERSION.tar.gz

cd nagios-$NAGIOS_VERSION
./configure --with-command-group=nagcmd
make all
sudo -s bash -c 'make install && make install-init && make install-config && make install-commandmode'
sudo -s bash -c 'make install-webconf'
sudo -s bash -c 'htpasswd -b -c /usr/local/nagios/etc/htpasswd.users nagiosadmin nagiosadmin'

sudo sed -i 's#Allow from 127.0.0.1#Allow from 127.0.0.1 192.168.1.0/24#' /etc/httpd/conf.d/nagios.conf

/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
sudo systemctl restart httpd
sudo systemctl start nagios
sudo chkconfig --add nagios
sudo chkconfig nagios on

# Install contrib
sudo cp -R contrib/eventhandlers/ /usr/local/nagios/libexec/
sudo chown -R nagios:nagios /usr/local/nagios/libexec/eventhandlers

# Configure Nagios plugin

cd /vagrant/nagios-plugins-*
./configure --with-nagios-user=nagios --with-nagios-group=nagios
make
sudo make install
sudo make install-init

# Configure Nagios NRPE

cd /vagrant/nrpe-*
./configure --enable-command-args --with-nagios-user=nagios --with-nagios-group=nagios --with-ssl=/usr/bin/openssl --with-ssl-lib=/usr/lib/x86_64-linux-gnu
make all
sudo make install
sudo make install-xinetd
sudo make install-daemon-config
sudo service xinetd restart


# Configure SNMP trap

sudo yum -y install net-snmp net-snmp-libs net-snmp-utils net-snmp-perl perl-Net-SNMP net-snmp-devel cpan
sudo echo "traphandle default /usr/sbin/snmptt" >> /etc/snmp/snmptrapd.conf
sudo echo "disableAuthorization yes" >> /etc/snmp/snmptrapd.conf
sudo systemctl restart snmptrapd

# Configure SNMP trap translator

cd /vagrant/
sudo cp snmptt.ini /etc/snmp/
tar xzf snmptt_1.4.tgz
cd snmptt*
cp snmptt snmptthandler snmpttconvertmib /usr/sbin/
sudo groupadd snmptt
sudo adduser -g snmptt snmptt
sudo chown snmptt:snmptt /etc/snmp/snmptt.ini
sudo mkdir /var/spool/snmptt
sudo chown snmptt:snmptt /var/spool/snmptt
sudo cp snmptt-init.d /etc/init.d/snmptt

sudo -s bash -c 'export PERL_MM_USE_DEFAULT=1; cpan install List::Util && cpan install Module::Build::Compat && cpan install Sys::Syslog && cpan install Config::IniFiles'
sudo /etc/init.d/snmptt start

# Configure Nagios service

echo 'cfg_dir=/usr/local/nagios/etc/servers' >> /usr/local/nagios/etc/nagios.cfg
sudo mkdir /usr/local/nagios/etc/servers/
sudo cat > /usr/local/nagios/etc/servers/localhost.cfg << EOF
define host {
        use                             linux-server
        host_name                       nagios.vagrant.dev
        alias                           My first Apache server
        address                         10.132.234.52
        max_check_attempts              5
        check_period                    24x7
        notification_interval           30
        notification_period             24x7
}

define service {
        use                             generic-service
        host_name                       nagios.vagrant.dev
        service_description             PING
        check_command                   check_ping!100.0,20%!500.0,60%
}

define service {
        use                             generic-service
        host_name                       nagios.vagrant.dev
        service_description             SSH
        check_command                   check_ssh
        notifications_enabled           0
}

define service{
   host_name               nagios.vagrant.dev
   use                     generic-service
   service_description     MONGODB-TRAP
   is_volatile             1
   check_command           check-host-alive
   max_check_attempts      1
   normal_check_interval   1
   retry_check_interval    1
   passive_checks_enabled  1
   check_period            none
   notification_interval   31536000
}

EOF

sudo systemctl restart nagios

# Compiling MIBS
cd /vagrant/
sudo snmpttconvertmib --in=MMS-10GEN-MIB.txt --out=/etc/snmp/snmptt.conf.mongodb --exec='/usr/local/nagios/libexec/eventhandlers/submit_check_result $r TRAP 1'

sudo cat >> /etc/snmp/snmptt.ini << EOF
[TrapFiles]
snmptt_conf_files = <<END
/etc/snmp/snmptt.conf.mongodb
END
EOF

sudo cat >> /etc/snmp/snmptt.conf << EOF
EVENT general .* "General event" Normal
FORMAT ZBXTRAP $aA $ar
EOF

sudo systemctl restart snmptt
sudo systemctl restart nagios
sudo systemctl stop firewalld
sudo systemctl disable firewalld
