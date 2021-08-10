# Arch Linux Simple Installer
This is a simple installation script for Arch Linux. It's aimed to be minimalistic and reduce stress of disk changing or machine hopping.

Execute these commands from live ISO:
- curl --location "https://git.io/fluffeh-archsin"
- /bin/bash archsin


***

This script is suitable for both workstations and servers. Consider using a different disk layout ( manual partitioning ) for servers. I will be uploading a few other options at some point in the future.

This will remain a BTRFS only install!


To-Do's:

- [ ] Add support for MBR installation
- ~~[ ] Add support for more filesystems~~
- [ ] Add multiple variants for disk layouting
  - [x] Add support for NVMe drives
