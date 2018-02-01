#!/bin/sh

# Usage info
show_help() {
   cat << EOF

   Usage: ${0##*/} -u account-id [-p password] -s OpenStack-IP [-f imagepath]
   
  -u account-id        the username to access OpenStack
  -p passwork          the password of the <account-id>
  -s OpenStack-IP      the IP address of OpenStack
  -f imagepath         the pathname of OAI image. The image file will be download from internet if not specified.
EOF
}


# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
USER=""
PASSWD=""
OPENSTACK_IP=""
IMAGEFILE=""

while getopts "h?u:p:s:f:" opt; do
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
    f)  IMAGEFILE=$OPTARG
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

if [ "X$IMAGEFILE" != "X" ]
then
    if [ ! -f $IMAGEFILE ]
    then
        echo "Error: input filename $IMAGEFILE is not exist or not a file"
        exit 5
    fi
fi

#echo "user=" $USER " passwd=" $PASSWD  " OpenStack IP=" $OPENSTACK_IP " Image file=" $IMAGEFILE

##check if curl has been installed
type curl >/dev/null 2>&1 || { echo "require curl but it's not installed" ; exit 99 ; }

##download image from internet if need
IMAGEURL="https://drive.google.com/open?id=16GBiVH4Zz1fHhmUCMdXgWkWitc0H4wnx"
#IMAGEURL="https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img"
OUTFILE=oai_compress.qcow2
if [ "X$IMAGEFILE" = "X" ]
then

    echo "Download image from internet doesn't NOT support now, since download file from google drive is a little bit complicated."
    echo "There are still jobs to do in the future. Please specify the image file before we finish the jobs."

    exit 99

    ##check if wget has been installed
    type wget >/dev/null 2>&1 || { echo "require wget but it's not installed" ; exit 99 ; }

    echo ""
    echo "==> Download OAI image from internet....."
    echo ""
    wget -L -O $OUTFILE $IMAGEURL
    if [ $? -ne 0 ]
    then 
        echo ""
        echo "Error: Download OAI image from internet FAIL"
        echo "the address is $IMAGEURL"
        exit 6
    fi
    IMAGEFILE=`pwd`/$OUTFILE
    if [ ! -f $IMAGEFILE ]
    then
        echo ""
        echo "Error: Download OAI image from internet to $IMAGEFILE FAIL"
        exit 6
    fi
fi


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

CreateImageResult=`curl -s  http://$OPENSTACK_IP:9292/v2/images -X POST -H "Content-Type: application/json"  -H "X-Auth-Token: $Token" -d '{"name": "oai_compress" , "visibility":"public",  "disk_format":"qcow2",  "container_format":"bare" }' |awk -F',' '{ for( i=1;i<=NF;i++) print $i }' |grep \"id\" ` 

#echo $CreateImageResult
if [ "X$CreateImageResult" = "X" ]
then
    echo "Error: Create Image FAIL"
    exit 2
fi

ImageId=`echo $CreateImageResult | awk -F'"' '{ print $4 }'`

echo ""
echo "Create image SUCCESS : $ImageId"
echo ""


echo "uploading file to openstack : $IMAGEFILE ...."

UploadResult=`curl -sw '%{http_code}' http://$OPENSTACK_IP:9292/v2/images/$ImageId/file -X PUT -H "Content-Type: application/octet-stream" -H "X-Auth-Token: $Token" --data-binary @$IMAGEFILE`

#echo "$UploadResult"

if [ $UploadResult -ge 200 -a $UploadResult -le 299 ]
then
    echo ""
    echo "Upload file SUCCESS"
    echo ""
else
    echo ""
    echo "Upload file FAIL: $UploadResult"
    echo ""
    exit 7
fi

##query upload result
QueryImageResult=`curl -s http://$OPENSTACK_IP:9292/v2/images/$ImageId -X GET -H "X-Auth-Token: $Token" |awk -F',' '{ for( i=1;i<=NF;i++) print $i }' |grep \"status\" ` 

Status=`echo $QueryImageResult | awk -F'"' '{ print $4 }'`

echo "Image Status in OpenStack is $Status"


