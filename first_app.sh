#! /bin/bash
sudo yum update -y
sudo yum install httpd -y
sudo systemctl start httpd
sudo systemctl enable httpd
cd /tmp/
mkdir web
cd web/
sudo wget https://www.free-css.com/assets/files/free-css-templates/download/page259/volim.zip
unzip volim.zip
sudo cp -r volim /var/www/html/
cd /var/www/html/
cd volim/
sudo cp -r * /var/www/html/
