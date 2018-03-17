#!/bin/bash
HOSTNAME=$(hostname -f)
CA_CERT=${CA_CERT-/certs/ca.pem}
CA_KEY=${CA_KEY-/certs/ca-key.pem}
CERT_PATH=/certs/${HOSTNAME}.pem
KEY_PATH=/certs/${HOSTNAME}.key
ADMIN_CERT=/certs/docker-nifi-admin.pem
ADMIN_KEY=/certs/docker-nifi-admin.key
SRC_MODULE=${SRC_MODULE-/modules}
MODULES_DIR=/etc/puppet/modules

# install r10k
gem install r10k

cat << EOF > /root/Puppetfile
mod 'puppetlabs/stdlib', '4.6.0'
mod 'puppetlabs/inifile'
mod 'puppetlabs/concat', '1.2.5'
mod 'puppetlabs/java_ks', '1.4.1'
EOF

cat << EOF > /root/manifest.pp
\$id_mappings =[
  {
    'pattern' => '^CN=(.*?)\$',
    'value' => '\$1'
  }
]
class {'::nifi':
  config_cluster => true,
  cluster_members => ['nifi-as01a.docker_nificluster','nifi-as02a.docker_nificluster','nifi-as03a.docker_nificluster'],
  cluster_identities => ['nifi-as01a.docker_nificluster','nifi-as02a.docker_nificluster','nifi-as03a.docker_nificluster'],
  cluster_zookeeper_ids => [1,2,3],
  id_mappings => \$id_mappings,
  config_ssl => true,
  cacert_path => '${CA_CERT}',
  node_cert_path => '${CERT_PATH}',
  node_private_key_path => '${KEY_PATH}',
  initial_admin_identity => 'docker-nifi-admin',
  initial_admin_cert_path => '${ADMIN_CERT}',
  initial_admin_key_path => '${ADMIN_KEY}',
  keystore_password => 'changeit',
  key_password => 'changeit',
  client_auth => true,
  min_heap => "512m",
  max_heap => "512m",
}
EOF

r10k puppetfile install --puppetfile /root/Puppetfile --moduledir ${MODULES_DIR}
if [ -d ${SRC_MODULE}/nifi ]; then
  cp -r ${SRC_MODULE}/nifi ${MODULES_DIR}/nifi
else
  echo "Cannot find nifi module at ${SRC_MODULE}/nifi"
fi

puppet apply --parser future --modulepath=${MODULES_DIR} /root/manifest.pp

exec /usr/sbin/init