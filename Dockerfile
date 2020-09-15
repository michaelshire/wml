FROM registry.redhat.io/ubi8
ADD ./init.sh ./

ENV HOME=/tmp/

RUN yum install wget -y
# RUN yum install wget -y && yum clean all -y
# RUN wget -O /dev/null http://speedtest.wdc01.softlayer.com/downloads/test10.zip

# Install python3 for AZ CLI and ansible
RUN yum install -y python3 python3-virtualenv python3-pip
#RUN yum install -y python3 python3-virtualenv python3-pip && yum clean all -y
# RUN python3 --version

RUN yum install iputils -y
RUN yum install nmap-ncat -y
RUN yum install net-tools -y
RUN yum install bind-utils -y
RUN yum install mod_ssl -y
RUN yum install openssl -y && yum clean all -y

RUN chown 1001:1001 init.sh && chmod o+w init.sh
USER 1001

CMD ["./init.sh"]
