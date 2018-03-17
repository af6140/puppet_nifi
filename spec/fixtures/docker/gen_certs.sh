#!/bin/bash
PWD=$(pwd)
echo "certs dir: ${PWD}/ssl"
if [ ! -d ${PWD}/ssl ]; then
  mkdir ${PWD}/ssl
fi

HOSTS="nifi-as01a.docker_nificluster nifi-as02a.docker_nificluster nifi-as03a.docker_nificluster docker-nifi-admin"
for HOST in ${HOSTS} ; do
  echo "For host: ${HOST}"
  if [ ! -f ${PWD}/ssl/${HOST}.pem ]; then
    docker run --rm -v ${PWD}/ssl:/certs -e CA_SUBJECT="docker_nificluster" -e SSL_KEY="${HOST}.key" -e SSL_CSR="${HOST}.csr" -e SSL_CERT="${HOST}.pem" -e SSL_EXPIRE=3650 -e SSL_SUBJECT="${HOST}" paulczar/omgwtfssl
  else
    echo "Certificate exists"
  fi
done
