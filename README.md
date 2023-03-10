# Mailoptimizer in a docker image

Twiki: http://twiki/Comcard/MailOptimizer


## Build and run
```sh
cp ~/I/PROG/_post/Mailoptimizer/MO_Installer-2023-03-10.zip .
rm -rf mo-installer
mkdir -p mo-installer
unzip -d mo-installer MO_Installer-2023-03-10.zip
rm MO_Installer-2023-03-10.zip
gem fetch mailoptimizer_server
docker-compose up --build
```

## Run as daemon and view the logs
```sh
docker-compose up -d
docker-compose logs -f
```

## Open browser interface

http://localhost:2511/mowebapp/

## save image to file
```sh
docker save mailoptimizer-docker_mailoptimizer | xz -T $(nproc) --fast > ~/L/HSB-IN/Dev/post/mailoptimizer-docker.tar.xz
docker save mariadb:10.6 | xz -T $(nproc) --fast > ~/L/HSB-IN/Dev/post/mysql.tar.xz
```

## load image from file

On comdb2 in the mailoptimizer-docker root directory:
```sh
xz -d < ~/L/HSB-IN/Dev/post/mailoptimizer-docker.tar.xz | docker load
xz -d < ~/L/HSB-IN/Dev/post/mysql.tar.xz | docker load
docker-compose up -d
```

On cppdb1 in the mailoptimizer-docker root directory:
```sh
xz -d < /production/data/cpp/HSB-IN/Dev/post/mailoptimizer-docker.tar.xz | docker load
xz -d < /production/data/cpp/HSB-IN/Dev/post/mysql.tar.xz | docker load
docker-compose up -d
```

## Inspect the MYSQL database
```sh
docker exec -it mailoptimizer-docker-mysql-1 /bin/mysql mo
```

Passwortänderung weit in die Zukunft schieben:
```sh
docker exec -it mailoptimizer-docker_mysql_1 /bin/mysql mo --execute "update benutzer set PW_GEAENDERT='2054-01-12 12:16:38';"
```

## Update to new version of Mailoptimizer

```sh
wget https://www.tc.dpcom.de/downloads/_AutoUpdate_Mailoptimizer/MO_Installer.zip
cp MO_Installer.zip ~/I/PROG/_post/Mailoptimizer/MO_Installer-2023-03-10.zip
rm MO_Installer.zip
```

Then update the date stamps of the zip file in this README and run commands above to build and start a new docker image.
