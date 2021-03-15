#! /bin/bash
sudo yum update -y
sudo yum install httpd -y
sudo systemctl start httpd
sudo systemctl enable httpd
cd /tmp/
mkdir web
cd web/
sudo wget https://www.free-css.com/assets/files/free-css-templates/download/page264/daraz.zip
unzip daraz.zip
sudo cp -r daraz /var/www/html/
cd /var/www/html/
cd daraz/
sudo cp -r * /var/www/html/
