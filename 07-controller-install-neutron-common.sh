#!/bin/bash

#Add the Networking service
#Prerequisites
mysql -u root --password=amcc1234 <<MYSQL_SCRIPT
CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO neutron@'localhost' IDENTIFIED BY 'amcc1234';
GRANT ALL PRIVILEGES ON neutron.* TO neutron@'%' IDENTIFIED BY 'amcc1234';
MYSQL_SCRIPT


apt-get install openvswitch-switch -y

ovs-vsctl add-br br-provider
ovs-vsctl add-port br-provider eth1


ovs-vsctl show


source admin-openrc.sh
#To create the service credentials, complete these steps:
openstack user create --domain default --password amcc1234 neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron \
	  --description "OpenStack Networking" network
openstack endpoint create --region RegionOne \
	  network public http://controller:9696
openstack endpoint create --region RegionOne \
	  network internal http://controller:9696
openstack endpoint create --region RegionOne \
	  network admin http://controller:9696
#Networking Option 2: Self-service networks
#Instal and config neutron on controller
apt-get install neutron-server neutron-plugin-ml2 \
	neutron-plugin-openvswitch-agent neutron-l3-agent neutron-dhcp-agent \
	neutron-metadata-agent python-neutronclient conntrack -y
#Configure the api and nova for neutron
crudini --set /etc/neutron/neutron.conf database connection mysql+pymysql://neutron:amcc1234@controller/neutron

crudini --set /etc/neutron/neutron.conf DEFAULT verbose True
crudini --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
crudini --set /etc/neutron/neutron.conf DEFAULT service_plugins router

crudini --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips True

crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True
crudini --set /etc/neutron/neutron.conf DEFAULT nova_url http://controller:8774/v2


crudini --set /etc/neutron/neutron.conf DEFAULT rpc_backend rabbit
crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_host controller
crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_password amcc1234

crudini --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
crudini --del /etc/neutron/neutron.conf keystone_authtoken
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://controller:5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://controller:35357
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_plugin password
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_domain_id default
crudini --set /etc/neutron/neutron.conf keystone_authtoken user_domain_id default
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set /etc/neutron/neutron.conf keystone_authtoken username neutron
crudini --set /etc/neutron/neutron.conf keystone_authtoken password amcc1234

crudini --set /etc/neutron/neutron.conf nova auth_url http://controller:35357
crudini --set /etc/neutron/neutron.conf nova auth_plugin password
crudini --set /etc/neutron/neutron.conf nova project_domain_id default
crudini --set /etc/neutron/neutron.conf nova user_domain_id default
crudini --set /etc/neutron/neutron.conf nova region_name RegionOne
crudini --set /etc/neutron/neutron.conf nova project_name service
crudini --set /etc/neutron/neutron.conf nova username nova
crudini --set /etc/neutron/neutron.conf nova password amcc1234

#Ml2 plugin config, layer 3 and dhcp
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types 
#The Linux bridge agent only supports VXLAN overlay networks.
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks provider
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vlan network_vlan_ranges provider
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True
#Configure the Linux bridge agent
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini ovs bridge_mappings provider:br-provider
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini agent prevent_arp_spoofing True
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup enable_security_group True
crudini --set /etc/neutron/plugins/ml2/openvswitch_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
#Configure the layer-3 agent
crudini --set /etc/neutron/l3_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
crudini --set /etc/neutron/l3_agent.ini DEFAULT external_network_bridge
crudini --set /etc/neutron/l3_agent.ini DEFAULT router_delete_namespaces True
crudini --set /etc/neutron/l3_agent.ini DEFAULT verbose True
#Configure the DHCP agent
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata True
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT verbose True
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT dnsmasq_config_file /etc/neutron/dnsmasq-neutron.conf
#Create and set DHCP
touch /etc/neutron/dnsmasq-neutron.conf
echo "dhcp-option-force=26,1450" >> /etc/neutron/dnsmasq-neutron.conf
#Config metadata
crudini --set /etc/neutron/metadata_agent.ini DEFAULT auth_uri http://controller:5000
crudini --set /etc/neutron/metadata_agent.ini DEFAULT auth_url http://controller:35357
crudini --set /etc/neutron/metadata_agent.ini DEFAULT auth_region RegionOne
crudini --set /etc/neutron/metadata_agent.ini DEFAULT auth_plugin password
crudini --set /etc/neutron/metadata_agent.ini DEFAULT project_domain_id default
crudini --set /etc/neutron/metadata_agent.ini DEFAULT user_domain_id default
crudini --set /etc/neutron/metadata_agent.ini DEFAULT project_name service
crudini --set /etc/neutron/metadata_agent.ini DEFAULT username neutron
crudini --set /etc/neutron/metadata_agent.ini DEFAULT password amcc1234
crudini --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_ip controller
crudini --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret amcc1234
crudini --set /etc/neutron/metadata_agent.ini DEFAULT verbose True
#Configure compute to use the network
crudini --set /etc/nova/nova.conf neutron url http://controller:9696
crudini --set /etc/nova/nova.conf neutron auth_url http://controller:35357
crudini --set /etc/nova/nova.conf neutron auth_plugin password
crudini --set /etc/nova/nova.conf neutron project_domain_id default
crudini --set /etc/nova/nova.conf neutron user_domain_id default
crudini --set /etc/nova/nova.conf neutron region_name RegionOne
crudini --set /etc/nova/nova.conf neutron project_name service
crudini --set /etc/nova/nova.conf neutron username neutron
crudini --set /etc/nova/nova.conf neutron password amcc1234
crudini --set /etc/nova/nova.conf neutron service_metadata_proxy True
crudini --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret amcc1234

#Finalize installation
#Populate neutron
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
	  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
#Restart the Networking and Compute services.
service nova-api restart
service neutron-server restart
service neutron-plugin-openvswitch-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service neutron-l3-agent restart
rm -f /var/lib/neutron/neutron.sqlite
#Neutron verification
source admin-openrc.sh
neutron agent-list
neutron ext-list

ovs-vsctl show

