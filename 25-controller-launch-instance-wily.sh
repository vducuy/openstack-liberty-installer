#!/bin/bash
#Create the public network
source admin-openrc.sh
echo "Flavor List"
openstack flavor list
echo "Image List"
openstack image list
echo "Security group List"
openstack security group list
echo "Network List"
openstack network list

echo -n "Copy Provider network ID > "
read PROVIDER_NET_ID
nova --debug boot --flavor 2 --image Wily --nic net-id=$PROVIDER_NET_ID --security-group default --key-name mykey wily


openstack server list

