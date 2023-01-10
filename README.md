# Mailoptimizer in a docker image

Twiki: http://twiki/Comcard/MailOptimizer

## Build and run
```sh
cp ~/I/PROG/_post/Mailoptimizer/MO_Installer-2022-11-23.zip .
rm -rf mo-installer
mkdir -p mo-installer
unzip -d mo-installer MO_Installer-2022-11-23.zip
rm MO_Installer-2022-11-23.zip
docker-compose up --build
```

## Run as daemon per
```sh
docker-compose up -d
```

## Open browser interface

http://localhost:2511/mowebapp/

## save image to file
```sh
docker save mailoptimizer | xz -T $(nproc) --fast > ~/I/PROG/_post/Mailoptimizer/mailoptimizer-docker.tar.xz
```

## load image from file
```sh
xz -d < ~/I/PROG/_post/Mailoptimizer/mailoptimizer-docker.tar.xz | docker load
```

## Inspect the MYSQL database
```sh
docker exec -it mailoptimizer-docker-mysql-1 /bin/mysql mo
```
