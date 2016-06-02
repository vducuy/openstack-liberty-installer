#!/bin/bash
#Create the public network
source admin-openrc.sh
neutron net-list
echo -n "Copy public network ID > "
read PUBLIC_NET_ID
nova --debug boot p-$1 --flavor 2 --image Wily --nic net-id=$PUBLIC_NET_ID --key-name mykey --security-group default

#Create private instance
#source demo-openrc.sh
#neutron net-list
#echo -n "Copy private network ID > "
#read PRIVATE_NET_ID
#nova boot private-instance --flavor m1.tiny --image cirros --nic net-id=$PRIVATE_NET_ID --security-group default
#Check them
nova list

