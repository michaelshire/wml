FROM image-registry.openshift-image-registry.svc:5000/openshift/python-36-rhel7
ADD ./init.sh ./

ENV HOME=/tmp/
RUN python3 --version

#RUN yum install iputils -y
RUN yum install nmap-ncat -y
#RUN yum install net-tools -y
#RUN yum install bind-utils -y
#RUN yum install mod_ssl -y
#RUN yum install openssl -y && yum clean all -y

## Install ML Server
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc

# Create local `azure-cli` repository
RUN sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'

# Set the location of the package repo at the "prod" directory
# The following command is for version 7.x
# For 6.x, replace 7 with 6 to get that version
RUN rpm -Uvh https://packages.microsoft.com/config/rhel/7/packages-microsoft-prod.rpm

# Verify that the "microsoft-prod.repo" configuration file exists
RUN ls -la /etc/yum.repos.d/

# Update packages on your system:
RUN yum update -y

# Install the server
# The following command is for version 7.x
# For 6.x: yum install microsoft-mlserver-el6-9.4.7
RUN yum install microsoft-mlserver-all-9.4.7 -y

# Activate the server
RUN /opt/microsoft/mlserver/9.4.7/bin/R/activate.sh

# List installed packages as a verification step
RUN rpm -qa | grep microsoft

# Choose a package name and obtain verbose version information
RUN rpm -qi microsoft-mlserver-packages-r-9.4.7

RUN chown 1001:1001 init.sh && chmod 755 init.sh
RUN ls -al init.sh
USER 1001

CMD ["./init.sh"]
