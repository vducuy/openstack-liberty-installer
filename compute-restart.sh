service nova-compute stop
service neutron-plugin-openvswitch-agent stop

rm -f /var/log/nova/*
rm -f /var/log/neutron/*

service nova-compute start
service neutron-plugin-openvswitch-agent start

