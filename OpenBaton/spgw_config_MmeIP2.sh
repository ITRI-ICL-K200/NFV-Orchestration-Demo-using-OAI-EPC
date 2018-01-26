#!/bin/bash
#change host name
sed -i "s/ubuntu/$hostname/" /etc/hosts

#get interface for s11/s1
S1Interface=`ifconfig | grep -B1 "inet addr:${public}" | awk '$1!="inet" && $1!="--" {print $1}'`
S11Interface=`ifconfig | grep -B1 "inet addr:${S11}" | awk '$1!="inet" && $1!="--" {print $1}'`

#mod mme.conf
#S1 ip on mme
sudo sed -i "s/__MME_S1_C_IP__/${public}/" /opt/openbaton/scripts/mme.conf
#S1 interface on mme
sudo sed -i "s/__MME_S1_C_INTERFACE__/${S1Interface}/" /opt/openbaton/scripts/mme.conf

#S11 ip on mme
sudo sed -i "s/__MME_S11_C_IP__/${S11}/" /opt/openbaton/scripts/mme.conf
#S11 interface on mme
sudo sed -i "s/__MME_S11_C_INTERFACE__/${S11Interface}/" /opt/openbaton/scripts/mme.conf
 
#SPGW ip on spgw
sudo sed -i "s/SPGW_PRIVATE_IP/${spgw_S11}/" /opt/openbaton/scripts/mme.conf
