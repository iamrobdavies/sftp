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
sudo useradd -m sftpuser -s /usr/sbin/nologin -G ftpaccess
echo "sftpuser:$USERPASS" | sudo chpasswd

sudo mkdir -p /sftp/ecom
sudo chmod 755 /sftp
sudo chown root:root /sftp
sudo chown -R sftpuser:ftpaccess /sftp/ecom

sudo sed -i '/Subsystem sftp/s/^/#/g' /etc/ssh/sshd_config

echo $'\nSubsystem sftp internal-sftp' | sudo tee --append /etc/ssh/sshd_config > /dev/null
echo "Match User sftpuser" | sudo tee --append /etc/ssh/sshd_config > /dev/null
echo $'\tChrootDirectory /sftp' | sudo tee --append /etc/ssh/sshd_config > /dev/null
echo $'\tX11Forwarding no' | sudo tee --append /etc/ssh/sshd_config > /dev/null
echo $'\tAllowTcpForwarding no' | sudo tee --append /etc/ssh/sshd_config > /dev/null
echo $'\tForceCommand internal-sftp' | sudo tee --append /etc/ssh/sshd_config > /dev/null
echo $'\tPasswordAuthentication yes' | sudo tee --append /etc/ssh/sshd_config > /dev/null
echo "Match all" | sudo tee --append /etc/ssh/sshd_config > /dev/null

sudo systemctl restart ssh

until sudo apt-get -y update && sudo apt-get -y install cifs-utils
do
	echo "installing..."
	sleep 2
done

sudo bash -c 'echo "//$0.file.core.windows.net/$1	/home/sftpuser/ecom	cifs	nofail,vers=3.0,username=$0,password=$2,dir_mode=0777,file_mode=0777,serverino" >> /etc/fstab' $ACCOUNT $CONTAINER $STORAGEPASS

sudo mount -a
