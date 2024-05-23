# Arch Linux Simple Installer

A shell script which automates the installation of Arch Linux system with BTRFS on LUKS2 encrypted disk and systemd-boot.

## Features

- Full disk encryption using LUKS2
- BTRFS filesystem
- btsnap custom script for snapshotting
- systemd-boot with snapshot entries
- Automatic AMD/Intel microcode
- Automatic snapshots before package installation/uninstallation using btsnap
- firewalld enabled by default
- Neovim IDE with LazyVim
- Allacritty terminal with catppuccin themes
- Nushell with starship
- Extra utilities: bat, dust, fd, fzf, podman, ripgrep, sd, zoxide

## Usage
Execute these commands from live ISO:
```shell
- curl "https://raw.githubusercontent.com/f1uff3h/archsin/main/archsin.sh" > archsin.sh
- /bin/bash -e archsin.sh -d <disk> -e <encryption-password> -m <country code> -t <timezone> -h <hostname> -u <username> -p <password> -g <graphics-driver> -w <kde/gnome>
```

## Requirements

- This script must be run as root from live ISO
- The system must support UEFI
