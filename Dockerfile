# Ubuntu-18.04 für Mysql-5.7
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -y && \
    apt-get install -y openjdk-11-jre-headless ruby ranger mariadb-client iptables
#    apt-get install -y openjdk-11-jre-headless mysql-server ruby ranger  # Ubuntu-18.04


COPY mo-installer /mo-installer
COPY ["2022-02-23_Mo_config_15420_5046577760.xml", "/mo-installer/"]


# RUN sed -i 's/MySQL 5.7/\*/g' /mo-installer/Setup/morequirements.xml

COPY comcard-proxy-2022.crt /

# Zum testen von pre-release Gems:
COPY mailoptimizer_server-*.gem /
RUN gem sources -a http://ccgems && \
    gem inst --no-doc mailoptimizer_server --verbose

EXPOSE 2511/tcp
EXPOSE 8765/tcp

VOLUME /opt/mailoptimizer

ENV CATALINA_PID /opt/mailoptimizer/Software/Tomcat/tomcat.pid
ENV CATALINA_HOME /opt/mailoptimizer/Software/Tomcat
ENV CATALINA_BASE /opt/mailoptimizer/Software/Tomcat
ENV LANG=de_DE.UTF-8
ENV LANGUAGE=de

COPY startup.sh /
CMD /bin/bash /startup.sh
