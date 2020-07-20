FROM ubuntu:18.04

COPY MO_v4.3.08_Build-01 /mo-installer
RUN apt-get update -y && \
    apt-get install -y openjdk-11-jre-headless mariadb-server

COPY ["2020-07-10_Mo_config_10000_5046577760.xml", "/mo-installer/"]

RUN service mysql start && \
echo "\
  CREATE DATABASE mo CHARACTER SET utf8 COLLATE utf8_general_ci; \
  CREATE USER 'mo'@'localhost' IDENTIFIED BY 'mopw'; \
  GRANT ALL PRIVILEGES ON * . * TO 'mo'@'localhost'; \
  FLUSH PRIVILEGES; \
" | mysql -h localhost

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
Mailoptimizer\n\
" | bash /mo-installer/Setup_MO.sh -c


# service mysql start
# bash /mo-installer/Setup_MO.sh -c
# 1
# 1
# 1
# /mo-installer/2020-07-10_Mo_config_10000_5046577760.xml
# 1
# /
# n
# MySQL via JDBC
# jdbc:mysql://localhost:3306/mo?useSSL=false&serverTimezone=CET
# mo
# mopw
