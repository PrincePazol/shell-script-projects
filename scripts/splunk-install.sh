#!/bin/bash

##this is for ubuntu

# Update OS and install required packages
apt-get update -y

apt-get install -y \
    bc \
    net-tools \
    ncat \
    socat \
    nethogs \
    htop \
    vim \
    sysstat \
    nano \
    git \
    cowsay \
    chrony \
    rsync 

# Setp crontab
crontab -l > mycron
echo "0 */1 * * * /usr/bin/find /opt/syslog/ -type d -ctime +2 -exec rm -rf {} \;" >> mycron
crontab mycron
rm mycron

# Configure bash history 
echo "# Add date / time information to bash history export HISTTIMEFORMAT=\"%F %T \" " | sudo tee -a /etc/profile.d/ritaedu.sh

# Confugire Users
cat >> /etc/bashrc << 'EOF'

# Added TMOUT as read-only for CIS compliance.
TMOUT=600

readonly TMOUT
export TMOUT
EOF

#changing defualt shell to bash from .sh in useradd command
sed -i '8d' /etc/default/useradd 
sed -i '8iSHELL=/bin/bash' /etc/default/useradd \

useradd -m splunk
useradd -m ritaedu
usermod -a -G splunk ritaedu
chage -M -1 ritaedu
echo "ritaedu ALL=(ALL) NOPASSWD:ALL" | tee --append /etc/sudoers.d/ritaedu

#changing defualt shell to back to .sh
sed -i '8d' /etc/default/useradd 
sed -i '8iSHELL=/bin/sh' /etc/default/useradd \

# Password requirements
echo "minlen = 12" | tee --append /etc/security/pwquality.conf

# Setup ulimits
sed -i 's/#DefaultLimitNOFILE=/# ritaedu modified value below\nDefaultLimitNOFILE=64000/' /etc/systemd/system.conf
sed -i 's/#DefaultLimitNPROC=/# ritaedu modified value below\nDefaultLimitNPROC=16000/' /etc/systemd/system.conf
sed -i 's/#DefaultTasksMax=80%/# ritaedu modified value below\nDefaultTasksMax=8192/' /etc/systemd/system.conf

# Disable THP
echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled
echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag
grub2-editenv - set "$(grub2-editenv - list | grep kernelopts) transparent_hugepage=never"


# Setup Splunk user dir 
mkdir /opt/splunk
chown -R splunk:splunk /opt/splunk

###Setup Git
#create a directory named employee
#mkdir /home/ritaedu/mygit
#initialize git local repository
#git init /home/ritaedu/mygit

# File Permission
chown splunk. /opt/splunk
setfacl -Rdm u:splunk:rX /var/log/
setfacl -Rm "u:splunk:r-X" /var/log/

# MOTD
mkdir /etc/motd.d
cat > /etc/motd.d/ritaedu << 'EOF'
ritaedu Splunk Build
EOF

# Chrony 
systemctl enable chronyd
systemctl start chronyd

# Install Splunk
SPLUNK_HOME="/opt/splunk"
touch /tmp/user-seed.conf
cat > /tmp/user-seed.conf << 'EOF'
[user_info]
USERNAME = admin
PASSWORD = qwerty123
EOF
####TAR version
###wget -O splunk-8.2.7-2e1fca123028-Linux-x86_64.tgz "https://download.splunk.com/products/splunk/releases/8.2.7/linux/splunk-8.2.7-2e1fca123028-Linux-x86_64.tgz"
wget -O /tmp/splunk-9.0.1-82c987350fde-Linux-x86_64.tgz 'https://download.splunk.com/products/splunk/releases/9.0.1/linux/splunk-9.0.1-82c987350fde-Linux-x86_64.tgz'
sudo tar -xzvf /tmp/splunk-9.0.1-82c987350fde-Linux-x86_64.tgz -C /opt 
sleep 2
echo 'oh yeah we we are almost there...HAPPY SPLUNKING WITH RITA EDU.'
wait
###RPM version
#wget -O /tmp/splunk-8.2.3-cd0848707637-linux-2.6-x86_64.rpm 'https://download.splunk.com/products/splunk/releases/8.2.3/linux/splunk-8.2.3-cd0848707637-linux-2.6-x86_64.rpm'
#sudo rpm -i /tmp/splunk-8.2.3-cd0848707637-linux-2.6-x86_64.rpm
mv /tmp/user-seed.conf $SPLUNK_HOME/etc/system/local/user-seed.conf
touch $SPLUNK_HOME/etc/.ui_login
wait
sudo chown -Rf splunk:splunk $SPLUNK_HOME
$SPLUNK_HOME/bin/splunk enable boot-start -user splunk --accept-license --answer-yes --no-prompt
wait
echo -e "[settings]\nstartwebserver = True\nenableSplunkWebSSL = True\nsslVersions = tls1.2\n" >> $SPLUNK_HOME/etc/system/local/web.conf
sudo chown -Rf splunk:splunk $SPLUNK_HOME
$SPLUNK_HOME/bin/splunk start
wait
cowsay -f tux "WoHoo..Welcome to RITA EDU..You installed SPLUNK successfully"
echo "done"
