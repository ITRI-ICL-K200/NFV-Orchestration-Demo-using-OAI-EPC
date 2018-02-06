#!/bin/bash

# login openstack in user "demo" and get authentication
export OS_USERNAME=demo
export OS_PASSWORD=pass
export OS_TENANT_NAME=demo
export OS_AUTH_URL=http://127.0.0.1:35357/v2.0

# clear router's gateway
neutron router-gateway-clear router1

# delete router interface
neutron router-interface-delete router1 subnet=private-subnet
neutron router-interface-delete router1 subnet=ipv6-private-subnet

# delete router "router1"
neutron router-delete router1

# delete network "private"
neutron net-delete private

# login openstack in user "admin" and get authentication
export OS_USERNAME=admin
export OS_TENANT_NAME=admin

# delete ipv6 subnet of network "public"
neutron subnet-delete ipv6-public-subnet

# add dns in subnet "public-subnet" and enable dhcp
neutron subnet-update public-subnet --dns-nameserver 8.8.8.8 --enable-dhcp
