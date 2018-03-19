FROM af6140/cent7-nifi:1.2


USER root

# RUN rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm && \
#     yum update -y && \
#     yum install -y openssh-server curl gcc git make rpm-build ruby ruby-devel tar sensu sudo which yum-plugin-versionlock && \
#     yum versionlock puppet* && \
#     systemctl enable sshd && \
#     echo "gem: --no-ri --no-rdoc" > /etc/gemrc && \
#     yum clean all

# pin to puppet 3

COPY puppet_3.repo /etc/yum.repos.d
RUN rm -f /etc/yum.repos.d/puppetlabs* && \
    yum update -y && \
    yum install -y nifi-docs && \
    rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    yum install -y openssh-server curl gcc git make rpm-build ruby ruby-devel tar sensu sudo which yum-plugin-versionlock && \
    yum install -y puppet-3.8.7 && \
    yum versionlock puppet && \
    systemctl enable sshd && \
    echo "gem: --no-ri --no-rdoc" > /etc/gemrc && \
    echo "gem: --no-ri --no-rdoc" > /root/.gemrc && \
    yum clean all

VOLUME /certs
VOLUME /modules

VOLUME /sys/fs/cgroup

ENV container=docker

WORKDIR /root

COPY entrypoint.sh /entrypoint.sh

# bootstrap with same flowfile, so the cluster nodes will see same
COPY flow.xml /flow.xml

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
