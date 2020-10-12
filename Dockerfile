##############################################
# Stage 1 : Build go-init
##############################################
FROM openshift/golang-builder:1.13 AS go-init-builder
ENV __doozer=update BUILD_RELEASE=202009251759.p0 BUILD_VERSION=v4.5.0 OS_GIT_MAJOR=4 OS_GIT_MINOR=5 OS_GIT_PATCH=0 OS_GIT_TREE_STATE=clean OS_GIT_VERSION=4.5.0-202009251759.p0 SOURCE_GIT_TREE_STATE=clean 
ENV __doozer=merge OS_GIT_COMMIT=bff8501 OS_GIT_VERSION=4.5.0-202009251759.p0-bff8501 SOURCE_DATE_EPOCH=1600360279 SOURCE_GIT_COMMIT=bff850168142a6de2716bf14aa09bcfb40e5eb78 SOURCE_GIT_TAG=bff8501 SOURCE_GIT_URL=https://github.com/openshift/jenkins 
WORKDIR  /go/src/github.com/openshift/jenkins
COPY . .
WORKDIR  /go/src/github.com/openshift/jenkins/go-init
RUN go build . && cp go-init /usr/bin

##############################################
# Stage 2 : Build slave-base with go-init
##############################################
FROM openshift/ose-cli:v4.5.0-202009161248.p0
ENV __doozer=update BUILD_RELEASE=202009251759.p0 BUILD_VERSION=v4.5.0 OS_GIT_MAJOR=4 OS_GIT_MINOR=5 OS_GIT_PATCH=0 OS_GIT_TREE_STATE=clean OS_GIT_VERSION=4.5.0-202009251759.p0 SOURCE_GIT_TREE_STATE=clean 
ENV __doozer=merge OS_GIT_COMMIT=bff8501 OS_GIT_VERSION=4.5.0-202009251759.p0-bff8501 SOURCE_DATE_EPOCH=1600360279 SOURCE_GIT_COMMIT=bff850168142a6de2716bf14aa09bcfb40e5eb78 SOURCE_GIT_TAG=bff8501 SOURCE_GIT_URL=https://github.com/openshift/jenkins 
MAINTAINER Akram Ben Aissi <abenaiss@redhat.com>
COPY --from=go-init-builder /usr/bin/go-init /usr/bin/go-init

# Jenkins image for OpenShift
#
# This image provides a Jenkins server, primarily intended for integration with
# OpenShift v3.
#
# Volumes: 
# * /var/jenkins_home
# Environment:
# * $JENKINS_PASSWORD - Password for the Jenkins 'admin' user.

MAINTAINER Akram Ben Aissi <abenaiss@redhat.com>

ENV JENKINS_VERSION=2 \
    HOME=/var/lib/jenkins \
    JENKINS_HOME=/var/lib/jenkins \
    JENKINS_UC=https://updates.jenkins.io \
    OPENSHIFT_JENKINS_IMAGE_VERSION=4.5 \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    INSTALL_JENKINS_VIA_RPMS=true
# openshift/ocp-build-data will change INSTALL_JENKINS_VIA_RPMS to true
# so that the osbs/brew builds will install via RPMs; when this runs 
# in api.ci, it will employ the old centos style, download the plugins and
# redhat-stable core RPM for download


# Labels consumed by Red Hat build service

# 8080 for main web interface, 50000 for slave agents
EXPOSE 8080 50000

# for backward compatibility with pre-3.6 installs leveraging a PV, where rpm installs went to /usr/lib64/jenkins, we are
# establishing a symbolic link for that guy as well, so that existing plugins in JENKINS_HOME/plugins pointing to 
# /usr/lib64/jenkins will subsequently get redirected to /usr/lib/jenkins; it is confirmed that the 3.7 jenkins RHEL images 
# do *NOT* have a /usr/lib64/jenkins path
RUN ln -s /usr/lib/jenkins /usr/lib64/jenkins && \
    INSTALL_PKGS="dejavu-sans-fonts wget rsync gettext git tar zip unzip openssl bzip2 java-11-openjdk java-11-openjdk-devel java-1.8.0-openjdk java-1.8.0-openjdk-devel jq" && \
    yum install -y $INSTALL_PKGS && \
    rpm -V  $INSTALL_PKGS && \
    yum clean all  && \
    localedef -f UTF-8 -i en_US en_US.UTF-8

COPY ./contrib/openshift /opt/openshift
COPY ./contrib/jenkins /usr/local/bin
ADD ./contrib/s2i /usr/libexec/s2i
ADD release.version /tmp/release.version

RUN /usr/local/bin/install-jenkins-core-plugins.sh /opt/openshift/base-plugins.txt && \
    rmdir /var/log/jenkins && \
    chmod -R 775 /etc/alternatives && \
    chmod -R 775 /var/lib/alternatives && \
    chmod -R 775 /usr/lib/jvm && \
    chmod 775 /usr/bin && \
    chmod 775 /usr/lib/jvm-exports && \
    chmod 775 /usr/share/man/man1 && \
    mkdir -p /var/lib/origin && \
    chmod 775 /var/lib/origin && \
    unlink /usr/bin/java && \
    unlink /usr/bin/jjs && \
    unlink /usr/bin/keytool && \
    unlink /usr/bin/pack200 && \
    unlink /usr/bin/rmid && \
    unlink /usr/bin/rmiregistry && \
    unlink /usr/bin/unpack200 && \
    unlink /usr/share/man/man1/java.1.gz && \
    unlink /usr/share/man/man1/jjs.1.gz && \
    unlink /usr/share/man/man1/keytool.1.gz && \
    unlink /usr/share/man/man1/pack200.1.gz && \
    unlink /usr/share/man/man1/rmid.1.gz && \
    unlink /usr/share/man/man1/rmiregistry.1.gz && \
    unlink /usr/share/man/man1/unpack200.1.gz && \
    chown -R 1001:0 /opt/openshift && \
    /usr/local/bin/fix-permissions /opt/openshift && \
    /usr/local/bin/fix-permissions /opt/openshift/configuration/init.groovy.d && \
    /usr/local/bin/fix-permissions /var/lib/jenkins && \
    /usr/local/bin/fix-permissions /var/log

VOLUME ["/var/lib/jenkins"]

USER 1001
ENTRYPOINT ["/usr/bin/go-init", "-main", "/usr/libexec/s2i/run"]

LABEL \
        io.k8s.description="Jenkins is a continuous integration server" \
        io.k8s.display-name="Jenkins 2" \
        io.openshift.tags="jenkins,jenkins2,ci" \
        io.openshift.expose-services="8080:http" \
        io.jenkins.version="2.235.5" \
        io.openshift.s2i.scripts-url="image:///usr/libexec/s2i" \
        com.redhat.component="openshift-jenkins-2-container" \
        name="openshift/ose-jenkins" \
        version="v4.5.0" \
        architecture="x86_64" \
        License="GPLv2+" \
        vendor="Red Hat" \
        io.openshift.maintainer.product="OpenShift Container Platform" \
        io.openshift.maintainer.component="Jenkins" \
        release="202009251759.p0" \
        io.openshift.build.commit.id="bff850168142a6de2716bf14aa09bcfb40e5eb78" \
        io.openshift.build.source-location="https://github.com/openshift/jenkins" \
        io.openshift.build.commit.url="https://github.com/openshift/jenkins/commit/bff850168142a6de2716bf14aa09bcfb40e5eb78"
