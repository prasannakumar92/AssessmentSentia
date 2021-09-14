#!/bin/bash
resourceGroupName=$1
storageAccountName=$2
ClientID=$3
ClientSecret=$4
subscriptionName=$5
tenantID=$6
fileShareName=$7


###Pre-Requisites
echo "Installing Az"
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

echo "Installing cfis's "
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install cifs-utils -y

#Login to Azure 
az login --service-principal -u $ClientID -p $ClientSecret --tenant $tenantID --allow-no-subscriptions

#Set Subscription
az account set --subscription $subscriptionName

#Get Storage Account Keys
storageAccountKey=$(az storage account keys list \
    --resource-group $resourceGroupName \
    --account-name $storageAccountName \
    --query "[0].value" | tr -d '"')

#Mount Storage Part
sudo mkdir /mnt/$fileShareName
if [ ! -d "/etc/smbcredentials" ]; then
sudo mkdir /etc/smbcredentials
fi
if [ ! -f "/etc/smbcredentials/devsentiastrg.cred" ]; then
    sudo bash -c "echo username=$storageAccountName >> /etc/smbcredentials/devsentiastrg.cred"
    sudo bash -c "echo password="$storageAccountKey" >> /etc/smbcredentials/devsentiastrg.cred"
fi
sudo chmod 600 /etc/smbcredentials/devsentiastrg.cred

sudo bash -c "echo //devsentiastrg.file.core.windows.net/$(($fileShareName)) /mnt/$(($fileShareName)) cifs nofail,vers=3.0,credentials=/etc/smbcredentials/devsentiastrg.cred,dir_mode=0777,file_mode=0777,serverino >> /etc/fstab"
sudo mount -t cifs //devsentiastrg.file.core.windows.net/$fileShareName /mnt/$fileShareName -o vers=3.0,credentials=/etc/smbcredentials/devsentiastrg.cred,dir_mode=0777,file_mode=0777,serverino


## SetUP FTP ######

#Install SFTP
sudo apt install vsftpd -y

#Enable and Start FTP service
sudo systemctl enable vsftpd
sudo systemctl start vsftpd

#Backup Configuration Files
sudo cp /etc/vsftpd.conf  /etc/vsftpd.conf_default

#Create FTP User
sudo useradd -m ftpuser
sudo passwd F@ftpuser2021

#Configure Firewall to Allow FTP Traffic
sudo ufw allow 20/tcp
sudo ufw allow 21/tcp