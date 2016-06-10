#!/bin/bash
source demo-openrc.sh
neutron net-list
echo -n "Copy network ID > "
read PRIVATE_NET_ID
nova --debug boot vm-$1 --flavor 2 --image Wily --nic net-id=$PRIVATE_NET_ID --key-name mykey --security-group default

nova list

