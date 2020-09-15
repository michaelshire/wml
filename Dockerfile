FROM centos/s2i-base-centos7
ADD ./init.sh ./
ENV PYTHON_VERSION=3.8 \
    PATH=$HOME/.local/bin/:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    PIP_NO_CACHE_DIR=off


ENV SUMMARY="Platform for building and running Python $PYTHON_VERSION applications" \
    DESCRIPTION="Python $PYTHON_VERSION available as container is a base platform for \
building and running various Python $PYTHON_VERSION applications and frameworks. \
Python is an easy to learn, powerful programming language. It has efficient high-level \
data structures and a simple but effective approach to object-oriented programming. \
Python's elegant syntax and dynamic typing, together with its interpreted nature, \
make it an ideal language for scripting and rapid application development in many areas \
on most platforms."

LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="Python 3.8" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,python,python38,python-38,rh-python38" \
      com.redhat.component="python38-container" \
      name="centos/python-38-centos7" \
      version="1" \
      usage="s2i build https://github.com/sclorg/s2i-python-container.git --context-dir=3.8/test/setup-test-app/ centos/python-38-centos7 python-sample-app" \
      maintainer="SoftwareCollections.org <sclorg@redhat.com>"

RUN INSTALL_PKGS="rh-python38 rh-python38-python-devel rh-python38-python-setuptools rh-python38-python-pip nss_wrapper \
        httpd24 httpd24-httpd-devel httpd24-mod_ssl httpd24-mod_auth_kerb httpd24-mod_ldap \
        httpd24-mod_session atlas-devel gcc-gfortran libffi-devel libtool-ltdl enchant" && \
    yum install -y centos-release-scl && \
    yum -y --setopt=tsflags=nodocs install --enablerepo=centosplus $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    # Remove centos-logos (httpd dependency) to keep image size smaller.
    rpm -e --nodeps centos-logos && \
    yum -y clean all --enablerepo='*'

# - Create a Python virtual environment for use by any application to avoid
#   potential conflicts with Python packages preinstalled in the main Python
#   installation.
# - In order to drop the root user, we have to make some directories world
#   writable as OpenShift default security model is to run the container
#   under random UID.
RUN source scl_source enable rh-python38 && \
    python3.8 -m venv ${APP_ROOT} && \
    chown -R 1001:0 ${APP_ROOT} && \
    fix-permissions ${APP_ROOT} -P && \
    rpm-file-permissions

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
