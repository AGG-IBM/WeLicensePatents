FROM registry.access.redhat.com/ubi7/ubi

# Install necessary packages
RUN yum repolist > /dev/null && \
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
     yum clean all

# Create jmeter directory with tests and results folder
RUN mkdir -p /jmeter/
# Install JMeter
RUN wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-3.1.tgz
RUN wget https://jmeter-plugins.org/downloads/file/JMeterPlugins-ExtrasLibs-1.4.0.zip

RUN mv apache-jmeter-3.1.tgz /jmeter/

RUN gzip -d /jmeter/apache-jmeter-3.1.tgz

RUN mkdir -p /jmeter/apache-jmeter-3.1

RUN tar xvf /jmeter/apache-jmeter-3.1.tar -C /jmeter/apache-jmeter-3.1

RUN rm /jmeter/apache-jmeter-3.1.tar

RUN mv JMeterPlugins-ExtrasLibs-1.4.0.zip /jmeter/apache-jmeter-3.1/

RUN unzip -o /jmeter/apache-jmeter-3.1/JMeterPlugins-ExtrasLibs-1.4.0.zip -d /jmeter/apache-jmeter-3.1/ \
    && rm -rf /jmeter/apache-jmeter-3.1/JMeterPlugins-ExtrasLibs-1.4.0.zip

# Set JMeter Home
ENV JMETER_HOME /jmeter/apache-jmeter-3.1/

# Add JMeter to the Path
ENV PATH $JMETER_HOME/bin:$PATH

# Additional jars (ex. ActiveMQ) can be copied into $JMETER_HOME/bin
# COPY activemq-all-5.10.1.jar $JMETER_HOME/bin

# Copy custom user.properties file for reports dashboard to be generated
COPY user.properties $JMETER_HOME/bin/user.properties

# Set working directory
WORKDIR /jmeter
