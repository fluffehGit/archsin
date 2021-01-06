# Arch Linux Simple Installer
This is a simple installation script for Arch Linux. It's aimed to be minimalistic. It only supports a BTRFS installation.

## Caveats
- MBR is not yet supported
- For the moment it does not work out of the box. I still have to find a way to pass the environment to chroot. (Right now you have to re-run getEnvironment inside chroot and then execute the rest of the script which is a chore and will be fixed.)
