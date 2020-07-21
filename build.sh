
cp ~/I/PROG/_post/Mailoptimizer/MO_Installer.exe .
wine MO_Installer.exe
docker build . --build-arg http_proxy --build-arg https_proxy --tag mailoptimizer

# Run interactive per:
docker run -it --rm -p 2511:2511 -p 8765:8765 -v mailoptimizer-kunden:/opt/mailoptimizer/Kunden -v mailoptimizer-mysql:/var/lib/mysql mailoptimizer

# Run as daemon per:
docker run -p 2511:2511 -p 8765:8765 -v mailoptimizer-kunden:/opt/mailoptimizer/Kunden -v mailoptimizer-mysql:/var/lib/mysql -d --restart unless-stopped --memory-swappiness=0 mailoptimizer
