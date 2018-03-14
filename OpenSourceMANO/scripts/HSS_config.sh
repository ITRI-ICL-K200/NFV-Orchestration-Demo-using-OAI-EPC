#!/bin/bash

#change host name
ORGHNAME=`cat /etc/hostname`
sudo sed -i "s/ubuntu/$ORGHNAME/" /etc/hosts
sudo sed -i "s/$ORGHNAME/hss/" /etc/hosts
sudo sed -i "s/$ORGHNAME/hss/" /etc/hostname
sudo hostname hss

#start HSS
sudo cp ~/NFV-Orchestration-Demo-using-OAI-EPC/OpenSourceMANO/scripts/hss.conf /usr/local/etc/oai
sudo cp ~/NFV-Orchestration-Demo-using-OAI-EPC/OpenSourceMANO/scripts/hss_fd.conf /usr/local/etc/oai/freeDiameter
sudo cp ~/NFV-Orchestration-Demo-using-OAI-EPC/OpenSourceMANO/scripts/acl.conf /usr/local/etc/oai/freeDiameter
sudo cp ~/NFV-Orchestration-Demo-using-OAI-EPC/OpenSourceMANO/scripts/HSS.service /etc/systemd/system
sudo sh ~/NFV-Orchestration-Demo-using-OAI-EPC/OpenSourceMANO/scripts/create_db.sh
sudo service HSS start
