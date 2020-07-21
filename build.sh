
cp ~/I/PROG/_post/Mailoptimizer/MO_Installer.exe .
wine MO_Installer.exe
docker build . --build-arg http_proxy --build-arg https_proxy --tag mailoptimizer

# Run per:

docker run -it --rm -p 2511:2511 -p 8765:8765 -v mailoptimizer-kunden:/opt/mailoptimizer/Kunden -v mailoptimizer-mysql:/var/lib/mysql mailoptimizer

