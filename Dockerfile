FROM ubuntu:18.04

RUN apt-get update -y && \
    apt-get install -y openjdk-11-jre-headless mysql-server-5.7 ruby

COPY MO_v4.3.08_Build-01 /mo-installer
COPY ["2020-07-10_Mo_config_10000_5046577760.xml", "/mo-installer/"]

RUN echo "\n\
[mysqld]\n\
lower_case_table_names = 1\n\
" > /etc/mysql/mysql.conf.d/case_insensitive.cnf

RUN service mysql start && \
echo "\
  CREATE DATABASE mo CHARACTER SET utf8 COLLATE utf8_general_ci; \
  CREATE USER 'mo'@'localhost' IDENTIFIED BY 'mopw'; \
  GRANT ALL PRIVILEGES ON *.* TO 'mo'@'localhost'; \
  FLUSH PRIVILEGES; \
" | mysql -h localhost


RUN sed -i 's/MySQL 5.7/\*/g' /mo-installer/Setup/morequirements.xml

RUN service mysql start && \
echo "1\n\
1\n\
1\n\
/mo-installer/2020-07-10_Mo_config_10000_5046577760.xml\n\
1\n\
/\n\
n\n\
MySQL via JDBC\n\
jdbc:mysql://localhost:3306/mo?useSSL=false&serverTimezone=CET\n\
mo\n\
mopw\n\
\n\
\n\
" | bash /mo-installer/Setup_MO.sh -c


RUN service mysql start && \
    echo "\
      UPDATE mo.anwendungskonfiguration SET wert='DE' WHERE schluessel='user.str.conf.language'; \
    " | mysql -h localhost

RUN gem sources -a http://ccgems && \
    gem inst mailoptimizer_server

EXPOSE 2511/tcp
EXPOSE 8765/tcp

VOLUME /opt/mailoptimizer/Kunden
VOLUME /var/lib/mysql

ENV CATALINA_PID /opt/mailoptimizer/Software/Tomcat/tomcat.pid
ENV CATALINA_HOME /opt/mailoptimizer/Software/Tomcat
ENV CATALINA_BASE /opt/mailoptimizer/Software/Tomcat
ENV LANG=de_DE.UTF-8
ENV LANGUAGE=de

CMD service mysql start && \
    (/bin/bash /opt/mailoptimizer/Software/Tomcat/bin/startup.sh &) && \
    mailoptimizer_server -s druby://0.0.0.0:8765 -v -d /opt/mailoptimizer/Kunden/10000
