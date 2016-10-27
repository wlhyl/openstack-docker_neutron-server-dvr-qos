# 环境变量
- NOVA_PASS: openstack nova密码
- NEUTRON_DB: neutron数据库IP
- NEUTRON_DBPASS： neutron数据库密码
- RABBIT_HOST: rabbitmq IP
- RABBIT_USERID: rabbitmq user
- RABBIT_PASSWORD: rabbitmq user 的 password
- KEYSTONE_INTERNAL_ENDPOINT: keystone internal endpoint
- KEYSTONE_ADMIN_ENDPOINT: keystone admin endpoint
- NEUTRON_PASS: openstack neutron密码
- NOVA_URL: nova internal endpoint
- REGION_NAME: RegionOne

# volumes:
- /opt/openstack/neutron-server-dvr/: /etc/neutron
- /opt/openstack/log/neutron-server-dvr/: /var/log/neutron/

# 启动neutron-server
```bash
docker run -d --name neutron-server -p 9696:9696 \
    -v /opt/openstack/neutron-server/:/etc/neutron \
    -v /opt/openstack/log/neutron-server/:/var/log/neutron/ \
    -e NOVA_PASS=nova_pass \
    -e NEUTRON_DB=10.64.0.52 \
    -e NEUTRON_DBPASS=neutron_dbpass \
    -e RABBIT_HOST=10.64.0.52 \
    -e RABBIT_USERID=openstack \
    -e RABBIT_PASSWORD=openstack \
    -e KEYSTONE_INTERNAL_ENDPOINT=10.64.0.52 \
    -e KEYSTONE_ADMIN_ENDPOINT=10.64.0.52 \
    -e NEUTRON_PASS=neutron_pass \
    -e NOVA_URL=10.64.0.52 \
    -e REGION_NAME=RegionOne \
    10.64.0.50:5000/lzh/neutron-server:kilo
```