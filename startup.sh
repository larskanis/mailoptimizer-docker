#!/bin/bash

# Echo und Abbruch bei Fehler
set -xe

# Neue MySQL-Datenbank anlegen (falls noch nicht vorhanden)
(echo "
  CREATE DATABASE mo CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci;
  CREATE USER 'mo' IDENTIFIED BY 'mopw';
" | mysql -h mysql) || true

# Berechtigungen in MySQL-Datenbank vorbereiten
echo "
  GRANT ALL PRIVILEGES ON *.* TO 'mo';
  FLUSH PRIVILEGES;
" | mysql -h mysql

# Netzwerk temporär abschalten, damit Installer schneller läuft
iptables -A OUTPUT -p tcp --destination-port 443 -j REJECT

# Installation über simulierte Konsoleneingaben:
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
MySQL via JDBC\n\
jdbc:mysql://mysql:3306/mo?useSSL=false&serverTimezone=CET\n\
mo\n\
mopw\n\
1\n\
\n\
1\n\
/\n\
y\n\
\n\
" | bash /mo-installer/Setup_MO_x32_x64.sh -c -Dinstall4j.keepLog=true -Dinstall4j.debug=false -Dinstall4j.alternativeLogfile=/mo-unattended.log || (cat /mo-unattended.log; false)

# Die Variante über prop-Datei funktioniert leider nicht -> Abbruch ohne Fehlermeldung:
# bash /mo-installer/Setup_MO_x32_x64.sh -q -console -varfile /mo-installer/MO_Classic_Installation_Linux.prop -Dinstall4j.keepLog=true -Dinstall4j.debug=true

# Netzwerk nach Installation wieder einschalten
iptables -D OUTPUT -p tcp --destination-port 443 -j REJECT

# UI-Sprache auf Deutsch stellen (direkte Installation auf Deutsch schlägt fehl wegen Umlaut in "MySQL über JDBC")
echo "
  UPDATE mo.anwendungskonfiguration SET wert='DE' WHERE schluessel='user.str.conf.language';
" | mysql -h mysql

# Proxy-SSL-Zertifikat eintragen, damit Mailoptimizer für Listenupdates per HTTPS ins Internet kommt
keytool -delete -keystore /opt/mailoptimizer/Software/Tomcat/conf/MoTrustStore.jks -storepass changeit -alias sinc-root-02 || true
keytool -importcert -trustcacerts -keystore /opt/mailoptimizer/Software/Tomcat/conf/MoTrustStore.jks -file /usr/local/share/ca-certificates/sinc-root-02.crt -storepass changeit -alias sinc-root-02 -no-prompt

# Tomcat und mailoptimizer_server starten
/bin/bash /opt/mailoptimizer/Software/Tomcat/bin/startup.sh && \
    if [ -z "$WITH_CCRPC" ] ; then \
        sleep infinity ; \
    else \
        mailoptimizer_server -s tcpserver://0.0.0.0 -v -d /opt/mailoptimizer/Kunden/15420 ; \
    fi
