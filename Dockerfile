source:
  dockerfile: "FROM rhel7\nRUN yum repolist > /dev/null && \
     yum-config-manager --enable rhel-7-server-optional-rpms && \
     yum clean all && \
     INSTALL_PKGS="tar \
        unzip \
        wget \
        which \
        yum-utils \
        java-1.8.0-openjdk-devel" && \
     yum install -y --setopt=tsflags=nodocs install $INSTALL_PKGS && \
     rpm -V $INSTALL_PKGS && \
     yum clean all"
