FROM centos:7

WORKDIR /opt/gpdbmasterha

RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo 'Asia/Shanghai' > /etc/timezone \
    && mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup \
    && curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo \
    && yum install -y net-tools openssh-clients openssh-server epel-release sshpass \
    && yum clean all \
    && ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N "" \
    && ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N "" \
    && ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N "" \
    && curl -o node-v10.15.0-linux-x64.tar.xz https://nodejs.org/dist/v10.15.0/node-v10.15.0-linux-x64.tar.xz \
    && xz -d node-v10.15.0-linux-x64.tar.xz \
    && mkdir -p /opt/node \
    && tar -xvf node-v10.15.0-linux-x64.tar -C /opt/node --strip-components=1 \
    && rm node-v10.15.0-linux-x64.tar

COPY . .
RUN chmod +x *.sh

ENV LANG en_US.UTF-8
ENV PATH /opt/node/bin:$PATH

EXPOSE 9000

ENTRYPOINT [ "./entrypoint.sh" ]