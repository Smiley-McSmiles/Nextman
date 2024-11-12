> Nextman v0.1.0 - A Nextcloud manager written in BASH

> Tested on Fedora 41 | Ubuntu 24.04

> Should work on Any Debian, Arch, or RHEL Based Distribution **with SystemD**

# Description

Nextman is a lightweight BASH CLI (Command Line Interface) tool for installing and managing Nextcloud (with Apache).

# Getting Started

```sh
git clone https://github.com/Smiley-McSmiles/Nextman
cd Nextman
chmod ug+x setup.sh
sudo ./setup.sh
# sudo ./setup.sh -I /path/to/Nextman-backup.tar
cd ~/
```

# Features

* **Setup** - Install Nextcloud, Apache, and php-fpm at once
* **Update** - Downloads and updates to the latest Ollama, Open-WebUI, OpendAI-Speech versions
* **Disable** - Disable Nextcloud, Apache, and php-fpm
* **Enable** - Enable Nextcloud, Apache, and php-fpm
* **Start** - Start Nextcloud, Apache, and php-fpm
* **Stop** - Stop Nextcloud, Apache, and php-fpm
* **Restart** - Restart Nextcloud, Apache, and php-fpm
* **Status** - Get status of Nextcloud, Apache, and php-fpm
* **Change Port** - Change the default port for Nextcloud
* **Backup** - Input a directroy to output a backup archive
* **Backup Utility** - Start the Backup Utility to set up automatic backups
* **Import** - Import a .tar file to pick up where you left off on another system
  - _Use `sudo ./setup.sh /path/to/nextman-backup.tar` to import/restore a backup_
* **Get Version** - Get the current installed version of Nextman and Nextcloud
* **View Logs** - Select from a list of logs to view
* **Uninstall** - Uninstalls Nextman and Nextcloud completely

# Usage
```
nextman [PARAMETER]

PARAMETERS:
-b,    --backup             Backup Nextcloud
-bu,   --backup-utility     Start the backup utility
-i,    --import             Import Nextman archive
-e,    --enable             Enable Nextcloud, Apache, and php-fpm
-d,    --disable            Disable Nextcloud, Apache, and php-fpm
-s,    --start              Start Nextcloud, Apache, and php-fpm
-S,    --stop               Stop Nextcloud, Apache, and php-fpm
-r,    --restart            Restart Nextcloud, Apache, and php-fpm
-t,    --status             Get status of ollama.service and open-webui.service.
-u,    --update             Update Nextcloud, Apache, and php-fpm
-cp,   --change-port        Change the Nextcloud port
-v,    --version            Get Nextman and Nextcloud versions
-vl,   --view-logs          View Nextman logs
-h,    --help               Display this help menu
-X,    --uninstall          Uninstall Nextman, Ollama, and Open-Webui
Example: sudo Nextman -e -s -t
```

### License
   This project is licensed under the [GPL V3.0 License](https://github.com/Smiley-McSmiles/Nextman/blob/main/LICENSE).

