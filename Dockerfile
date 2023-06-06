FROM ubuntu:22.04

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -y && \
    apt-get install -y openjdk-11-jre-headless ruby ranger mariadb-client iptables

# Installer und Lizenzdatei ins Image holen
COPY mo-installer /mo-installer
COPY ["2022-02-23_Mo_config_15420_5046577760.xml", "/mo-installer/"]

# Falls die erwartete MySQL-Version nicht mit der installierten überein stimmt:
# RUN sed -i 's/MySQL 5.7/\*/g' /mo-installer/Setup/morequirements.xml

# Firmeninternes SSL-Zertifikat holen
COPY comcard-proxy-2022.crt /
# Property-Datei für Installer holen (wird aktuell nicht genutzt)
COPY MO_Classic_Installation_Linux.prop /mo-installer/

ARG WITH_CCRPC
ENV WITH_CCRPC=${WITH_CCRPC}

# Zum testen von pre-release Gems:
# COPY mailoptimizer_server-*.gem /

# Eigenes Gem installieren für Up- und Download von Freimachungsdaten
RUN if [ -z "$WITH_CCRPC" ] ; then \
        echo ccrpc Interface deaktiviert! ; \
    else \
        gem sources -a http://ccgems && \
        gem inst --no-doc mailoptimizer_server --verbose ; \
    fi

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
