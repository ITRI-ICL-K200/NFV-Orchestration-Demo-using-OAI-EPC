#!/bin/bash

#change host name
ORGHNAME=`cat /etc/hostname`
sed -i "s/ubuntu/$ORGHNAME/" /etc/hosts
sed -i "s/$ORGHNAME/spgw/" /etc/hosts
sed -i "s/$ORGHNAME/spgw/" /etc/hostname
hostname spgw
echo "public = ${public}" > ~/publicip.txt

SGiInterface=`ifconfig | grep -B1 "inet addr:${public}" | awk '$1!="inet" && $1!="--" {print $1}'`
S1_UInterface=`ifconfig | grep -B1 "inet addr:${public}" | awk '$1!="inet" && $1!="--" {print $1}'`
S11Interface=`ifconfig | grep -B1 "inet addr:${S11}" | awk '$1!="inet" && $1!="--" {print $1}'`

#config files
sudo sed -i "s/__SPGW_SGi_INTERFACE__/${SGiInterface}/" /opt/openbaton/scripts/spgw.conf
sudo sed -i "s/__SPGW_S1U_IP__/${public}/" /opt/openbaton/scripts/spgw.conf
sudo sed -i "s/__SPGW_S1U_INTERFACE__/${S1_UInterface}/" /opt/openbaton/scripts/spgw.conf
sudo sed -i "s/__SPGW_S11_IP__/${S11}/" /opt/openbaton/scripts/spgw.conf
sudo sed -i "s/__SPGW_S11_INTERFACE__/${S11Interface}/" /opt/openbaton/scripts/spgw.conf

#copy files
sudo cp /opt/openbaton/scripts/spgw.conf /usr/local/etc/oai
sudo cp /opt/openbaton/scripts/SPGW.service /etc/systemd/system

#run spgw
sudo service SPGW start
