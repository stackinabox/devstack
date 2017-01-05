#!/bin/bash

# setup operations tenant and user
source ~vagrant/admin-openrc.sh labstack

openstack user create --password labstack operator --or-show
operator_user_id=$(openstack user list | awk '/operator/ {print $2}')

admin_role_id=$(openstack role list | awk '/admin/ {print $2}')
admin_project_id=$(openstack project list | awk '/admin/ {print $2}')
demo_project_id=$(openstack project list | awk '/demo/ {print $2}')
openstack role add --user operator --project admin admin
openstack role add --user operator --project demo admin

cp /vagrant/scripts/operations/operator-openrc.sh ~vagrant/operator-openrc.sh
source ~vagrant/operator-openrc.sh labstack
export OS_TENANT_NAME="admin"

openstack project create --description 'Operations tenant.' operations --or-show
operations_project_id=$(openstack project list | awk '/operations/ {print $2}')

openstack role create operator --or-show
operator_role_id=$(openstack role list | awk '/operator/ {print $2}')

admin_role_id=$(openstack role list | awk '/admin/ {print $2}')
member_role_id=$(openstack role list | awk '/Member/ {print $2}')

openstack role add --user operator --project operations operator
openstack role add --user operator --project operations admin
openstack role add --user operator --project operations Member

# set operator user's default tenant to the operations project we just created
openstack user set operator --project operations --email "operator@stackinabox.io"

# now that we have a 'operations' tenant let's source that
source ~vagrant/operator-openrc.sh labstack

# create a new network in our operations tenant with it's own route to the public network
network_id=$(neutron net-create private | awk '/ id / {print $4}')
echo "network_id = $network_id"
subnet_id=$(neutron subnet-create --name private-subnet $network_id 10.0.4.0/24 \
  --gateway 10.0.4.1 \
  --host-route destination=0.0.0.0/0,nexthop=192.168.27.100 \
  --dns_nameservers list=true 8.8.8.8 8.8.4.4 \
  | awk '/ id / {print $4}')
echo "subnet_id = $subnet_id"
#neutron subnet-update $subnet_id --dns_nameservers list=true 8.8.8.8 8.8.4.4

#neutron router-create router2
neutron router-interface-add demorouter $subnet_id
#neutron router-gateway-set router2 public

# setup vagrant user with ssh keys
mkdir -p ~vagrant/.ssh
ssh-keygen -t rsa -N "" -f ~vagrant/.ssh/id_rsa -C "operator@stackinabox.io"

# create new keypair on openstack for the 'operator' user using vagrants ssh pub/priv keys
nova keypair-add --pub-key ~vagrant/.ssh/id_rsa.pub --key-type ssh operator

public_key=`cat ~vagrant/.ssh/id_rsa.pub`
private_key=`cat ~vagrant/.ssh/id_rsa`

# setup root and vagrant user's for no-password login via ssh keys
echo | sudo /bin/sh <<EOF
mkdir -p /root/.ssh
echo '#{private_key}' > /root/.ssh/id_rsa
chmod 600 /root/.ssh/id_rsa
echo '#{ops_private_key}' > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
echo '#{ops_private_key}' > /root/.ssh/id_rsa.pub
chmod 644 /root/.ssh/id_rsa.pub
EOF

# turn off strict host key checking for the vagrant user
echo 'Host *' > ~vagrant/.ssh/config
echo StrictHostKeyChecking no >> ~vagrant/.ssh/config
chown -R vagrant: ~vagrant/.ssh

echo 'Host *' > /root/.ssh/config
echo StrictHostKeyChecking no >> /root/.ssh/config
chown -R root: /root/.ssh

cat > ~vagrant/.operations <<EOF
#!/bin/bash
export ops_user_id=$operator_user_id
export ops_ssh_keypair=operator
export ops_project_id=$operations_project_id
export ops_network_id=$network_id
export ops_subnet_id=$subnet_id
EOF

