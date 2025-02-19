#!/bin/bash

sudo chown -Rf apache:apache /shared/nextcloud/data
sudo chmod -Rf 770 /shared/nextcloud/data
sudo -u apache php /var/www/html/nextcloud/occ files:scan --all
