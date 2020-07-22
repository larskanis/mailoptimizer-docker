# Mailoptimizer in a docker image

## Build per Dockerfile
cp ~/I/PROG/_post/Mailoptimizer/MO_Installer.exe .
wine MO_Installer.exe
docker build . --build-arg http_proxy --build-arg https_proxy --tag mailoptimizer

## Run in foreground per:
docker run -it --rm -p 2511:2511 -p 8765:8765 -v mailoptimizer-kunden:/opt/mailoptimizer/Kunden -v mailoptimizer-mysql:/var/lib/mysql mailoptimizer

## Run as daemon per:
docker run -p 2511:2511 -p 8765:8765 -v mailoptimizer-kunden:/opt/mailoptimizer/Kunden -v mailoptimizer-mysql:/var/lib/mysql -d --restart unless-stopped --memory-swappiness=0 mailoptimizer

## save image to file
docker save mailoptimizer | xz -T $(nproc) --fast > ~/I/PROG/_post/Mailoptimizer/mailoptimizer-docker.tar.xz

## load image from file
xz -d < ~/I/PROG/_post/Mailoptimizer/mailoptimizer-docker.tar.xz | docker load
