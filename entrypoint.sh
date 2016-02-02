#!/bin/bash

if [ -z "$NOVA_PASS" ];then
  echo "error: NOVA_PASS not set"
  exit 1
fi
if [ -z "$NEUTRON_DBPASS" ];then
  echo "error: NEUTRON_DBPASS not set"
  exit 1
fi

if [ -z "$NEUTRON_DB" ];then
  echo "error: NEUTRON_DB not set"
  exit 1
fi

if [ -z "$RABBIT_HOST" ];then
  echo "error: RABBIT_HOST not set"
  exit 1
fi

if [ -z "$RABBIT_USERID" ];then
  echo "error: RABBIT_USERID not set"
  exit 1
fi

if [ -z "$RABBIT_PASSWORD" ];then
  echo "error: RABBIT_PASSWORD not set"
  exit 1
fi

if [ -z "$KEYSTONE_INTERNAL_ENDPOINT" ];then
  echo "error: KEYSTONE_INTERNAL_ENDPOINT not set"
  exit 1
fi

if [ -z "$KEYSTONE_ADMIN_ENDPOINT" ];then
  echo "error: KEYSTONE_ADMIN_ENDPOINT not set"
  exit 1
fi

if [ -z "$NEUTRON_PASS" ];then
  echo "error: NEUTRON_PASS not set. user nova password."
  exit 1
fi

# NOVA_URL pillar['nova']['INTERNAL_ENDPOINT']
if [ -z "$NOVA_URL" ];then
  echo "error: NOVA_URL not set. user nova password."
  exit 1
fi

if [ -z "$REGION_NAME" ];then
  echo "error: REGION_NAME not set."
  exit 1
fi

CRUDINI='/usr/bin/crudini'

CONNECTION=mysql://neutron:$NEUTRON_DBPASS@$NEUTRON_DB/neutron
if [ ! -f /etc/neutron/.complete ];then
    cp -rp /neutron/* /etc/neutron
    
    $CRUDINI --set /etc/neutron/neutron.conf DEFAULT state_path /var/lib/neutron
    $CRUDINI --set /etc/neutron/neutron.conf DEFAULT lock_path /var/lib/neutron/lock

    $CRUDINI --set /etc/neutron/neutron.conf database connection $CONNECTION

    $CRUDINI --set /etc/neutron/neutron.conf DEFAULT rpc_backend rabbit

    $CRUDINI --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_host $RABBIT_HOST
    $CRUDINI --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_userid $RABBIT_USERID
    $CRUDINI --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_password $RABBIT_PASSWORD

    $CRUDINI --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone

    $CRUDINI --del /etc/neutron/neutron.conf keystone_authtoken

    $CRUDINI --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://$KEYSTONE_INTERNAL_ENDPOINT:5000
    $CRUDINI --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://$KEYSTONE_ADMIN_ENDPOINT:35357
    $CRUDINI --set /etc/neutron/neutron.conf keystone_authtoken auth_plugin password
    $CRUDINI --set /etc/neutron/neutron.conf keystone_authtoken project_domain_id default
    $CRUDINI --set /etc/neutron/neutron.conf keystone_authtoken user_domain_id default
    $CRUDINI --set /etc/neutron/neutron.conf keystone_authtoken project_name service
    $CRUDINI --set /etc/neutron/neutron.conf keystone_authtoken username neutron
    $CRUDINI --set /etc/neutron/neutron.conf keystone_authtoken password $NEUTRON_PASS
    
    $CRUDINI --set /etc/neutron/neutron.conf DEFAULT core_plugin neutron.plugins.ml2.plugin.Ml2Plugin
    $CRUDINI --set /etc/neutron/neutron.conf DEFAULT service_plugins router,qos
    $CRUDINI --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips True
    
    $CRUDINI --set /etc/neutron/neutron.conf qos notification_drivers message_queue
    
    # dvr
    $CRUDINI --set /etc/neutron/neutron.conf DEFAULT router_distributed True
    
    $CRUDINI --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
    $CRUDINI --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True
    $CRUDINI --set /etc/neutron/neutron.conf DEFAULT nova_url http://${NOVA_URL}:8774/v2
    
    # dhcp
    $CRUDINI --set /etc/neutron/neutron.conf DEFAULT dhcp_agents_per_network 2
    
    $CRUDINI --set /etc/neutron/neutron.conf nova auth_url http://$KEYSTONE_ADMIN_ENDPOINT:35357
    $CRUDINI --set /etc/neutron/neutron.conf nova auth_plugin password
    $CRUDINI --set /etc/neutron/neutron.conf nova project_domain_id default
    $CRUDINI --set /etc/neutron/neutron.conf nova user_domain_id default
    $CRUDINI --set /etc/neutron/neutron.conf nova region_name $REGION_NAME
    $CRUDINI --set /etc/neutron/neutron.conf nova project_name service
    $CRUDINI --set /etc/neutron/neutron.conf nova username nova
    $CRUDINI --set /etc/neutron/neutron.conf nova password $NOVA_PASS


    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,vlan,gre,vxlan
    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types vxlan
    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers openvswitch,l2population
    # liberty中增加了port_security参数，kilo可以支持此参数，但未设置
    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security,qos
    
    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vlan network_vlan_ranges external:2:2999,private:2:2999

    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vni_ranges 10:10000
    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_vxlan vxlan_group 224.0.0.1
    
    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_security_group True
    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True
    $CRUDINI --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
    
    touch /etc/neutron/.complete
fi

chown -R neutron:neutron /var/log/neutron/

# 同步数据库
echo 'select * from agents limit 1;' | mysql -h$NEUTRON_DB  -uneutron -p$NEUTRON_DBPASS neutron
if [ $? != 0 ];then
    su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
fi

/usr/bin/supervisord -n