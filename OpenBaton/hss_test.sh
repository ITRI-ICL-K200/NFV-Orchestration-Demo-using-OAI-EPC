#!/bin/bash

#change host name
ORGHNAME=`cat /etc/hostname`
sed -i "s/ubuntu/$ORGHNAME/" /etc/hosts
sed -i "s/$ORGHNAME/hss/" /etc/hosts
sed -i "s/$ORGHNAME/hss/" /etc/hostname
hostname hss

#start HSS
sudo cp /opt/openbaton/scripts/hss.conf /usr/local/etc/oai
sudo cp /opt/openbaton/scripts/hss_fd.conf /usr/local/etc/oai/freeDiameter
sudo cp /opt/openbaton/scripts/acl.conf /usr/local/etc/oai/freeDiameter
sudo cp /opt/openbaton/scripts/HSS.service /etc/systemd/system
sudo sh /opt/openbaton/scripts/create_db.sh
sudo service HSS start
