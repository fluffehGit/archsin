# Arch Linux Simple Installer

A shell script for setting up an Arch Linux system with BTRFS on LUKS2, systemd-boot, and a number of useful tools and configurations.

Execute these commands from live ISO:
```shell
- curl "https://raw.githubusercontent.com/f1uff3h/archsin/main/archsin.sh" > archsin.sh
- /bin/bash -e archsin.sh -d <disk> -e <encryption-password> -m <country code> -t <timezone> -h <hostname> -u <username> -p <password> -g <graphics-driver> -w <kde/gnome>
```