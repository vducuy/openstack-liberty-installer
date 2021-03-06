#!/bin/bash
source default-config.sh


# Add network

apt-get install openvswitch-switch -y
ovs-vsctl add-br br-provider
ovs-vsctl add-port br-provider eth1

echo "#Install networking"
apt-get install neutron-plugin-openvswitch-agent conntrack -y
echo "#Edit the /etc/neutron/neutron.conf file and complete the following actions:"
echo "#In the [database] section, comment out any connection options because compute nodes do not directly access the database."
crudini --set /etc/neutron/neutron.conf DEFAULT rpc_backend rabbit
crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_host controller
crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_password ${ADMIN_PASSWORD}

crudini --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
crudini --del /etc/neutron/neutron.conf keystone_authtoken
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://controller:5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://controller:35357
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_plugin password
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_domain_id default
crudini --set /etc/neutron/neutron.conf keystone_authtoken user_domain_id default
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set /etc/neutron/neutron.conf keystone_authtoken username neutron
crudini --set /etc/neutron/neutron.conf keystone_authtoken password ${ADMIN_PASSWORD}
crudini --set /etc/neutron/neutron.conf DEFAULT verbose True
echo "#Config linux bridge"
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs bridge_mappings provider:eth1
#crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini vxlan enable_vxlan True 
#crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini vxlan local_ip 192.168.0.31 
#crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini vxlan l2_population True

crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent prevent_arp_spoofing True

crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup enable_security_group True
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
echo "#Configure compute to use the network"
crudini --set /etc/nova/nova.conf neutron url http://controller:9696
crudini --set /etc/nova/nova.conf neutron auth_url http://controller:35357
crudini --set /etc/nova/nova.conf neutron auth_plugin password
crudini --set /etc/nova/nova.conf neutron project_domain_id default
crudini --set /etc/nova/nova.conf neutron user_domain_id default
crudini --set /etc/nova/nova.conf neutron region_name RegionOne
crudini --set /etc/nova/nova.conf neutron project_name service
crudini --set /etc/nova/nova.conf neutron username neutron
crudini --set /etc/nova/nova.conf neutron password ${ADMIN_PASSWORD}
service nova-compute restart
service neutron-plugin-openvswitch-agent restart


