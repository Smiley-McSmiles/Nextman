#!/bin/bash

echo "Turning off security:"
sudo setsebool httpd_unified on

read -p "Press enter to turn security back on once update is finished" ENTER

sudo setsebool -P httpd_unified off

cd /var/www/nextcloud
sudo chmod +x occ
sudo -u apache ./occ maintenance:repair --include-expensive
sudo -u apache ./occ db:add-missing-indices
cd -
