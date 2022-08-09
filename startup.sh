#!/bin/bash

set -xe

(echo "
  CREATE DATABASE mo CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci;
  CREATE USER 'mo' IDENTIFIED BY 'mopw';
" | mysql -h mysql) || true

echo "
  GRANT ALL PRIVILEGES ON *.* TO 'mo';
  FLUSH PRIVILEGES;
" | mysql -h mysql

# Netzwerk temporär abschalten, damit Installer schneller läuft
iptables -A OUTPUT -p tcp --destination-port 443 -j REJECT

echo -e "1\n\
1\n\
1\n\
/mo-installer/2022-02-23_Mo_config_15420_5046577760.xml\n\
1\n\
2511\n\
80\n\
mailoptimizer\n\
mailoptimizer\n\
/\n\
n\n\
MySQL via JDBC\n\
jdbc:mysql://mysql:3306/mo?useSSL=false&serverTimezone=CET\n\
mo\n\
mopw\n\
1\n\
\n\
\n\
" | bash /mo-installer/Setup_MO_x32_x64.sh -c -Dinstall4j.keepLog=true -Dinstall4j.debug=true -Dinstall4j.alternativeLogfile=/mo-unattended.log

iptables -D OUTPUT -p tcp --destination-port 443 -j REJECT

# COPY MO_Classic_Installation_Linux.prop /mo-installer/
# RUN service mariadb start && bash /mo-installer/Setup_MO_x32_x64.sh -q -console -varfile /mo-installer/MO_Classic_Installation_Linux.prop -Dinstall4j.keepLog=true -Dinstall4j.debug=true

echo "
  UPDATE mo.anwendungskonfiguration SET wert='DE' WHERE schluessel='user.str.conf.language';
" | mysql -h mysql

keytool -delete -keystore /opt/mailoptimizer/Software/Tomcat/conf/MoTrustStore.jks -storepass changeit -alias comcard-2022 || true
# keytool -delete -keystore /opt/mailoptimizer/Software/Tomcat/conf/cacerts.jks -storepass changeit -alias comcard-2022
keytool -importcert -trustcacerts -keystore /opt/mailoptimizer/Software/Tomcat/conf/MoTrustStore.jks -file /comcard-proxy-2022.crt -storepass changeit -alias comcard-2022 -no-prompt
# die Beiden auch zur Sicherheit noch mit unserem Zertifikat impfen:
# keytool -importcert -trustcacerts -keystore /opt/mailoptimizer/Software/Tomcat/conf/cacerts.jks -file /comcard-proxy-2022.crt -storepass changeit -alias comcard-2022 -no-prompt
# keytool -importcert -trustcacerts -cacerts -file /comcard-proxy-2022.crt -storepass changeit -alias comcard-2022 -no-prompt

/bin/bash /opt/mailoptimizer/Software/Tomcat/bin/startup.sh && \
  mailoptimizer_server -s tcpserver://0.0.0.0 -v -d /opt/mailoptimizer/Kunden/15420
