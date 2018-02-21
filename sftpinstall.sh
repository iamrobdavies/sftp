#!/bin/bash
while getopts a:c:p:u: option
do
	case "${option}"
	in
	a) ACCOUNT=${OPTARG};;
	c) CONTAINER=${OPTARG};;
	p) STORAGEPASS=${OPTARG};;
	u) USERPASS=${OPTARG};;
	esac
done

sudo addgroup ftpaccess

sudo sed -i '/Subsystem sftp/s/^/#/g' /etc/ssh/sshd_config

echo $'\nSubsystem sftp internal-sftp' | sudo tee --append /etc/ssh/sshd_config > /dev/null
echo "Match group ftpaccess" | sudo tee --append /etc/ssh/sshd_config > /dev/null
echo "ChrootDirectory %h" | sudo tee --append /etc/ssh/sshd_config > /dev/null
echo "X11Forwarding no" | sudo tee --append /etc/ssh/sshd_config > /dev/null
echo "AllowTcpForwarding no" | sudo tee --append /etc/ssh/sshd_config > /dev/null
echo "ForceCommand internal-sftp" | sudo tee --append /etc/ssh/sshd_config > /dev/null

sudo systemctl restart ssh

sudo useradd -m sftpuser -s /usr/sbin/nologin -G ftpaccess
echo "sftpuser:$USERPASS" | sudo chpasswd
sudo chown root:root /home/sftpuser
sudo mkdir -p /home/sftpuser/ecom
sudo chown -R sftpuser:ftpaccess /home/sftpuser/ecom

until sudo apt-get -y update && sudo apt-get -y install cifs-utils
do
	echo "installing..."
	sleep 2
done

sudo mkdir -p /datadir
sudo bash -c 'echo "//$0.file.core.windows.net/$1	/datadir	cifs	nofail,vers=3.0,username=$0,password=$2,dir_mode=0777,file_mode=0777,serverino" >> /etc/fstab' $ACCOUNT $CONTAINER $STORAGEPASS

sudo mount -a
