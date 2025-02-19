#!/bin/bash

echo "Turning off security:"
sudo setsebool httpd_unified on

cd /var/www/html/nextcloud
sudo chmod +x occ
sudo -u apache ./occ upgrade
sudo -u apache ./occ maintenance:repair --include-expensive
sudo -u apache ./occ db:add-missing-indices
cd -

sudo setsebool -P httpd_unified off
