#!/bin/bash
#change host name
ORGHNAME=`cat /etc/hostname`
sudo sed -i "s/ubuntu/$ORGHNAME/" /etc/hosts
sudo sed -i "s/$ORGHNAME/spgw/" /etc/hosts
sudo ed -i "s/$ORGHNAME/spgw/" /etc/hostname
sudo hostname spgw

#get interface for s11/s1
#$1 --> public ip
#$2 --> MME S11 ip
#S3 --> spgw s11 ip
SGiInterface=`ifconfig | grep -B1 "inet addr:$1" | awk '$1!="inet" && $1!="--" {print $1}'`
S1_UInterface=`ifconfig | grep -B1 "inet addr:$1" | awk '$1!="inet" && $1!="--" {print $1}'`
S11Interface=`ifconfig | grep -B1 "inet addr:$2" | awk '$1!="inet" && $1!="--" {print $1}'`

#config files
sudo sed -i "s/__SPGW_SGi_INTERFACE__/${SGiInterface}/" ~/NFV-Orchestration-Demo-using-OAI-EPC/OpenSourceMANO/scripts/spgw.conf
sudo sed -i "s/__SPGW_S1U_IP__/$1/" ~/NFV-Orchestration-Demo-using-OAI-EPC/OpenSourceMANO/scripts/spgw.conf
sudo sed -i "s/__SPGW_S1U_INTERFACE__/${S1_UInterface}/" ~/NFV-Orchestration-Demo-using-OAI-EPC/OpenSourceMANO/scripts/spgw.conf
sudo sed -i "s/__SPGW_S11_IP__/$2/" ~/NFV-Orchestration-Demo-using-OAI-EPC/OpenSourceMANO/scripts/spgw.conf
sudo sed -i "s/__SPGW_S11_INTERFACE__/${S11Interface}/" ~/NFV-Orchestration-Demo-using-OAI-EPC/OpenSourceMANO/scripts/spgw.conf

#copy files
sudo cp ~/NFV-Orchestration-Demo-using-OAI-EPC/OpenSourceMANO/scripts/spgw.conf /usr/local/etc/oai
sudo cp ~/NFV-Orchestration-Demo-using-OAI-EPC/OpenSourceMANO/scripts/SPGW.service /etc/systemd/system

#run spgw
sudo service SPGW start
