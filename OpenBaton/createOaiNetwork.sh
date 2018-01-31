#!/bin/sh

# Usage info
show_help() {
   cat << EOF

   Usage: ${0##*/} -u account-id [-p password] -s OpenStack-IP
   
  -u account-id        the username to access OpenStack
  -p passwork          the password of the <account-id>
  -s OpenStack-IP      the IP address of OpenStack
EOF
}


# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
USER=""
PASSWD=""
OPENSTACK_IP=""

while getopts "h?u:p:s:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    u)  USER=$OPTARG
        ;;
    p)  PASSWD=$OPTARG
        ;;
    s)  OPENSTACK_IP=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1)) # Discard the options and sentinel --

if [ "X$USER" = "X" -o  "XOPENSTACK_IP" = "X" ]
then
	show_help
	exit 1
fi

while [ "X$PASSWD" = "X" ]
do
    stty -echo
    echo "Enter Password for $USER: "
    read PASSWD
    stty echo
done

#echo "user=" $USER " passwd=" $PASSWD  " OpenStack IP=" $OPENSTACK_IP


##check if curl and python has been installed
type curl >/dev/null 2>&1 || { echo "require curl but it's not installed" ; exit 99 ; }
type python >/dev/null 2>&1 || { echo "require python but it's not installed" ; exit 99 ; }

##get token
GetTokenCmd=`echo "curl -s http://$OPENSTACK_IP:35357/v2.0/tokens -H \"Content-Type: application/json\" -d '{\"auth\": {\"passwordCredentials\": {\"username\": \"$USER\", \"password\": \"$PASSWD\"},\"tenantName\": \"admin\"}}'"`

#echo $GetTokenCmd
TokenResult=`eval $GetTokenCmd | python -m json.tool |grep token -A 6 |grep \"id\"`
#echo $TokenResult
if [ "X$TokenResult" = "X" ]
then 
	echo "Error: Get token FAIL"
	exit 2
fi

Token=`echo $TokenResult | awk -F'"' '{ print $4 }'`

#echo "Token=" $Token

##create network : S11, Hss

S11TestCidr="10.99.1.0/24"
HssTestCidr="10.99.2.0/24"

for NetName in "S11" "Hss"
#for NetName in "S11Test" "HssTest"
do

    CreateNet1=`echo "curl -s http://$OPENSTACK_IP:9696/v2.0/networks -X POST -H \"Content-Type: application/json\" -H \"Accept: application/json\" -H \"X-Auth-Token: $Token\" -d '{\"network\": {\"name\": \"$NetName\"}}'"`

    #echo $CreateNet1

    CreateNetResult=`eval $CreateNet1 | python -m json.tool |grep \"id\"`

    #echo $CreateNetResult
    if [ "X$CreateNetResult" = "X" ]
    then 
	    echo "Error: Create network $NetName FAIL"
	    exit 2
    fi

    NetworkId=`echo $CreateNetResult | awk -F'"' '{ print $4 }'`

    #echo "NetworkId=" $NetworkId

    #set subnet at network1
    CidrVar=`echo $NetName"Cidr"`
    eval "SubnetCidr=\$$CidrVar"

    SetNet1Subnet=`echo "curl -s http://$OPENSTACK_IP:9696/v2.0/subnets -X POST -H \"Content-Type: application/json\" -H \"Accept: application/json\" -H \"X-Auth-Token: $Token\" -d '{\"subnet\": {\"name\": \"$NetName\", \"cidr\":\"$SubnetCidr\", \"ip_version\":4, \"network_id\":\"$NetworkId\",\"enable_dhcp\":true, \"gateway_ip\":null}}'"`

    #echo $SetNet1Subnet

    CreateSubnetResult=`eval $SetNet1Subnet | python -m json.tool |grep \"id\"`

    #echo $CreateSubnetResult
    if [ "X$CreateSubnetResult" = "X" ]
    then 
	    echo "Error: Create subnet (CIDR=$SubnetCidr) at network $NetName FAIL"
	    exit 3 
    fi

    echo ""
    echo "Create Network $NetName with CIDR=$SubnetCidr SUCCESS"
    echo ""

done

