#!/bin/bash
# config hss ip for mme
#mod mme.conf
#S1 ip on mme
sudo sed -i "s/__HSS_PRIVATE_IP__/${hss_Hss}/" /opt/openbaton/scripts/mme_fd.conf

#copy files
sudo cp /opt/openbaton/scripts/mme.conf /usr/local/etc/oai
sudo cp /opt/openbaton/scripts/mme_fd.conf /usr/local/etc/oai/freeDiameter
sudo cp /opt/openbaton/scripts/MME.service /etc/systemd/system

#change host name
ORGHNAME=`cat /etc/hostname`
sed -i "s/$ORGHNAME/nano/" /etc/hosts
sed -i "s/$ORGHNAME/nano/" /etc/hostname
hostname nano

#start MME service
while :
do
    ResultForHss3868=`nmap -p 3868 ${hss_Hss} | grep open`
    ResultForHss5868=`nmap -p 5868 ${hss_Hss} | grep open`
    if [ "X$ResultForHss3868" = "X" ] || [ "X$ResultForHss5868" = "X" ]; then
        echo "wait for HSS"
    else
        echo "HSS is alread up"
        break
    fi
    sleep 1
done

sudo service MME start
