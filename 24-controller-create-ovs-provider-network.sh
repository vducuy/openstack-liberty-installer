#!/bin/bash
#Create the public network
source admin-openrc.sh


neutron net-create provider --shared \
  --provider:physical_network provider \
  --provider:network_type flat \
#Config security group
#nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
#nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
#Get some usefull data
#echo -n "Enter Provider CIDR > "
#read PROVIDER_NETWORK_CIDR
#echo -n "Enter start IP address > "
#read START_IP_ADDRESS
#echo -n "Enter end IP address > "
#read END_IP_ADDRESS
#echo -n "Enter DNS > "
#read DNS_RESOLVER
#echo -n "Enter gateway > "
#read PROVIDER_NETWORK_GATEWAY
#Create a subnet on the network:

PROVIDER_NETWORK_CIDR=10.38.70.0/24
START_IP_ADDRESS=10.38.70.120
END_IP_ADDRESS=10.38.70.210
DNS_RESOLVER=8.8.8.8
PROVIDER_NETWORK_GATEWAY=10.38.70.1

neutron subnet-create provider $PROVIDER_NETWORK_CIDR \
  --name provider-subnet \
  --allocation-pool start=$START_IP_ADDRESS,end=$END_IP_ADDRESS \
  --enable-dhcp \
  --dns-nameserver $DNS_RESOLVER --gateway $PROVIDER_NETWORK_GATEWAY 

ip netns

#Create public instance
#ssh-keygen -q -N ""
#openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey
#openstack keypair list

#openstack security group rule create --proto icmp default
#openstack security group rule create --proto tcp --dst-port 22 default

#openstack flavor list
#openstack image list
#openstack network list
#openstack security group list

#echo -n "Copy Provider network ID > "
#read PROVIDER_NET_ID
#openstack server create --flavor m1.tiny --image cirros --nic net-id=$PROVIDER_NET_ID --security-group default --key-name mykey provider-instance


#openstack server list

