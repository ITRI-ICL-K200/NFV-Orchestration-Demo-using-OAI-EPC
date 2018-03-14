#!/bin/bash
#change host name
ORGHNAME=`cat /etc/hostname`
sudo sed -i "s/ubuntu/$ORGHNAME/" /etc/hosts
sudo sed -i "s/$ORGHNAME/nano/" /etc/hosts
sudo sed -i "s/$ORGHNAME/nano/" /etc/hostname
sudo hostname nano
#$1 --> public
#$2 --> S11
#$3 --> spgw_S11
#$4 --> hss_ip

#get interface for s11/s1
S1Interface=`ifconfig | grep -B1 "inet addr:$1" | awk '$1!="inet" && $1!="--" {print $1}'`
S11Interface=`ifconfig | grep -B1 "inet addr:$2" | awk '$1!="inet" && $1!="--" {print $1}'`

#mod mme.conf
#S1 ip on mme
sudo sed -i "s/__MME_S1_C_IP__/$1/" ~/testInfo/test/mme.conf
#S1 interface on mme
sudo sed -i "s/__MME_S1_C_INTERFACE__/${S1Interface}/" ~/testInfo/test/mme.conf

#S11 ip on mme
sudo sed -i "s/__MME_S11_C_IP__/$2/" ~/testInfo/test/mme.conf
#S11 interface on mme
sudo sed -i "s/__MME_S11_C_INTERFACE__/${S11Interface}/" ~/testInfo/test/mme.conf
 
#SPGW ip on spgw
sudo sed -i "s/SPGW_PRIVATE_IP/$3/" ~/testInfo/test/mme.conf

sudo sed -i "s/__HSS_PRIVATE_IP__/$4/" ~/testInfo/test/mme_fd.conf

#copy files
sudo cp ~/testInfo/test/mme.conf /usr/local/etc/oai
sudo cp ~/testInfo/test/mme_fd.conf /usr/local/etc/oai/freeDiameter
sudo cp ~/testInfo/test/MME.service /etc/systemd/system

sudo apt-get update 
sudo apt-get install -y nmap

#start MME service
echo "wait for HSS" > ~/waiteinfo.txt
while :
do
    ResultForHss3868=`nmap -p 3868 $4 | grep open`
    ResultForHss5868=`nmap -p 5868 $4 | grep open`
    if [ "X$ResultForHss3868" = "X" ] || [ "X$ResultForHss5868" = "X" ]; then
        echo $4 >> ~/waiteinfo.txt
    else
        echo "HSS is alread up" > ~/success.txt
        break
    fi
    sleep 1
done
sudo service MME start
