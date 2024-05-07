#!/bin/bash
#############################################################################################################################
#
#                           █████╗ ██████╗  ██████╗██╗  ██╗    ██╗     ██╗███╗   ██╗██╗   ██╗██╗  ██╗
#                          ██╔══██╗██╔══██╗██╔════╝██║  ██║    ██║     ██║████╗  ██║██║   ██║╚██╗██╔╝
#                          ███████║██████╔╝██║     ███████║    ██║     ██║██╔██╗ ██║██║   ██║ ╚███╔╝
#                          ██╔══██║██╔══██╗██║     ██╔══██║    ██║     ██║██║╚██╗██║██║   ██║ ██╔██╗
#                          ██║  ██║██║  ██║╚██████╗██║  ██║    ███████╗██║██║ ╚████║╚██████╔╝██╔╝ ██╗
#                          ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝
#   ███████╗██╗███╗   ███╗██████╗ ██╗     ███████╗    ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     ███████╗██████╗
#   ██╔════╝██║████╗ ████║██╔══██╗██║     ██╔════╝    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     ██╔════╝██╔══██╗
#   ███████╗██║██╔████╔██║██████╔╝██║     █████╗      ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     █████╗  ██████╔╝
#   ╚════██║██║██║╚██╔╝██║██╔═══╝ ██║     ██╔══╝      ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     ██╔══╝  ██╔══██╗
#   ███████║██║██║ ╚═╝ ██║██║     ███████╗███████╗    ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗███████╗██║  ██║
#   ╚══════╝╚═╝╚═╝     ╚═╝╚═╝     ╚══════╝╚══════╝    ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝
#
# Source: https://git.io/fluffeh-archsin
#
#############################################################################################################################

NC="\e[0m";
WHITE='\e[97m'
YELLOW='\e[33m'
RED='\e[31m'

exec &>> >(tee -a /root/arch-install.log)

usage() {
    echo -e "Usage: $(basename $0) -d <disk> -e <encryption-password> -m <country code> -t <timezone> -h <hostname> -u <username> -p <password> -g <graphics-driver> -w <kde/gnome>";
    echo -e "Options:";
    echo -e "\t-d\tDisk to install Arch Linux on";
    echo -e "\t-e\tEncryption password for the disk";
    echo -e "\t-m\tCountry code for mirrorlist (e.g. US)";
    echo -e "\t-t\tTimezone city (e.g. New_York)";
    echo -e "\t-h\tHostname for the system";
    echo -e "\t-u\tUsername for the system";
    echo -e "\t-p\tPassword for the user";
    echo -e "\t-g\tGraphics driver to install (e.g. nvidia)";
    echo -e "\t-w\tDesktop environment to install (e.g. kde, gnome)";
    echo -e "Example: $(basename $0) -d /dev/sda -e SecurePass123 -m US -t New_York -h archbox -u archuser -p SecureUserPass123 -g nvidia -w kde";
    exit 1;
}

while getopts "d:e:m:t:h:u:p:g:w:" opt; do
    case $opt in
        d) installDisk=$OPTARG;;
        e) encryptionPassword=$OPTARG;;
        m) mirrorlistCountry=$OPTARG;;
        t) timezoneCity=$OPTARG;;
        h) hostname=$OPTARG;;
        u) username=$OPTARG;;
        p) userPassword=$OPTARG;;
        g) graphicsDriver=$OPTARG;;
        w) desktopEnvironment=$OPTARG;;
        \?) usage;;
        :) usage;;
    esac
done

if [[ -z $installDisk || -z $encryptionPassword || -z $mirrorlistCountry || -z $timezoneCity || -z $hostname || -z $username || -z $userPassword || -z $desktopEnvironment ]]; then
    echo -e "${RED}[ERROR] -- Missing required arguments${NC}";
    usage;
fi

if [[ $EUID -ne 0 ]]; then
    echo "${RED}[ERROR] -- This script must be run as root${NC}";
    exit 1;
fi

if [[ ! -f /sys/firmware/efi/fw_platform_size ]]; then
    echo "${RED}[ERROR] -- Legacy system detected, exiting...${NC}"
    exit 1
fi

if ! $(timedatectl list-timezones | grep -qi $timezoneCity); then
    echo "${RED}[ERROR] -- Timezone city $timezoneCity not found${NC}";
    exit 1;
fi

echo -e "\n[INFO] -- Enabling NTP..."
timedatectl set-ntp true

echo -e "${YELLOW}[WARNING] -- This script will erase all data on $installDisk. Do you want to continue? (y/n)${NC}";
read answer
if [[ $answer == "n" ]]; then
    echo "Exiting..."
    exit 0
fi

echo -e "\n[INFO] -- Partitioning $installDisk..."
echo -e "g\nn\n\n\n+1G\nt\n1\nn\n\n\n\nt\n2\n44\nw" | fdisk $installDisk

echo -e "\n[INFO] -- Creating boot partition..."
mkfs.fat -F32 $installDisk"1"

echo -e "\n[INFO] -- Encrypting partition ${installDisk}2..."
echo -n $encryptionPassword | cryptsetup luksFormat --type luks2 $installDisk"2"
echo -n $encryptionPassword | cryptsetup open --type=luks2 $installDisk"2" root

echo -e "\n[INFO] -- BTRFS setup..."
mkfs.btrfs /dev/mapper/root
mount /dev/mapper/root /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
btrfs su cr /mnt/@var
btrfs su cr /mnt/@tmp
btrfs su cr /mnt/@snapshots
btrfs su cr /mnt/@swap
umount /mnt

echo -e "\n[INFO] -- Mounting filesystems..."
mount -o rw,noatime,compress=zstd,space_cache=v2,subvol=@ /dev/mapper/root /mnt
mkdir -p /mnt/{boot,var,tmp,home,.snapshots,swap}
mount -o rw,noatime,compress=zstd,space_cache=v2,subvol=@home /dev/mapper/root /mnt/home
mount -o rw,noatime,compress=zstd,space_cache=v2,subvol=@snapshots /dev/mapper/root /mnt/.snapshots
mount -o rw,noatime,compress=zstd,space_cache=v2,subvol=@tmp /dev/mapper/root /mnt/tmp
mount -o rw,noatime,nodatacow,compress=zstd,space_cache=v2,subvol=@var /dev/mapper/root /mnt/var
mount -o rw,noatime,nodatacow,compress=zstd,space_cache=v2,subvol=@swap /dev/mapper/root /mnt/swap
mount $installDisk"1" /mnt/boot

echo -e "\n[INFO] -- Enabling swap..."
btrfs filesystem mkswapfile --size 8G --uuid clear /mnt/swap/swapfile
swapon /mnt/swap/swapfile

echo -e "\n[INFO] -- Check CPU vendor..."
cpuVendor=$(lscpu | grep -i vendor | awk 'NR==1 {print $3}')
if [[ $cpuVendor == "AuthenticAMD" ]];
then
    echo -e "\n[INFO] -- AMD CPU detected, installing amd-ucode..."
    ucodePackage="amd-ucode"
elif [[ $cpuVendor == "GenuineIntel" ]];
then
    echo -e "\n[INFO] -- Intel CPU detected, installing intel-ucode..."
    ucodePackage="intel-ucode"
fi

echo -e "\n[INFO] -- Installing base system..."
pacstrap /mnt base base-devel btrfs-progs linux linux-firmware $ucodePackage lvm2 rsync git vim git networkmanager man-pages man-db firewalld

genfstab -U /mnt >> /mnt/etc/fstab
sed -i 's/fmask=0022,dmask=0022/fmask=0077,dmask=0077/' /mnt/etc/fstab
echo -e "/swap/swapfile none swap defaults 0 0" >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash -- <<EOT
    exec &>> >(tee -a /var/log/arch-install-chroot.log)

    set -e

    echo -e "\n[INFO] -- Setting up timezone..."
    ln -sf /usr/share/zoneinfo/$timezoneCity /etc/localtime
    hwclock --systohc

    echo -e "\n[INFO] -- Setting up locale..."
    sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf

    echo -e "\n[INFO] -- Setting up hostname..."
    echo "$hostname" > /etc/hostname

    echo -e "\n[INFO] -- Setting up hosts file..."
    echo -e "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t$hostname.localdomain\t$hostname" > /etc/hosts

    echo -e "\n[INFO] -- Setting up initramfs..."
    sed -i 's/^HOOKS.*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt btrfs filesystems fsck resume)/' /etc/mkinitcpio.conf
    sed -i 's/^MODULES.*/MODULES=(btrfs)/' /etc/mkinitcpio.conf
    sed -i 's/^BINARIES.*/BINARIES=(btrfs)/' /etc/mkinitcpio.conf
    mkinitcpio -P

    echo -e "\n[INFO] -- Setting up user $username..."
    useradd -m -G wheel -s /bin/bash $username
    echo -e "$userPassword\n$userPassword" | passwd $username
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

    echo -e "\n[INFO] -- Installing systemd-boot..."
    bootctl --path=/boot/ install

    echo -e "\n[INFO] -- Setting up systemd-boot..."
    mkdir -p /boot/loader/entries
    echo -e "default arch.conf\ntimeout 4\neditor no" > /boot/loader/loader.conf

    echo -e "\n[INFO] -- Setting up systemd-boot default entry..."
    echo -e "title Arch Linux\nlinux /vmlinuz-linux\ninitrd /$ucodePackage.img\ninitrd /initramfs-linux.img\noptions cryptdevice=UUID=$(blkid -s UUID -o value $installDisk"2"):root root=/dev/mapper/root rootflags=subvol=@ rw" > /boot/loader/entries/arch.conf

    echo -e "\n[INFO] -- Enabling services..."
    systemctl enable NetworkManager
    systemctl enable fstrim.timer
    systemctl enable firewalld

    echo -e "\n[INFO] -- Tune pacman..."
    sed -i 's/^#Color/Color/' /etc/pacman.conf
    sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
    pacman -Syy --noconfirm reflector
    reflector --country $mirrorlistCountry --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

    echo -e "\n[INFO] -- Installing base tools..."
    pacman -S --noconfirm alacritty android-tools bash-completion bat bitwarden curl chromium dosfstools dust exfatprogs fd firefox fwupd fzf neofetch net-tools nfs-utils ntfs-3g nushell otf-firamono-nerd p7zip procs podman podman-compose pkgfile rsync ripgrep sd starship tokei tlp unrar unzip wget wl-clipboard zoxide $graphicsDriver

    echo -e "\n[INFO] -- Installing paru..."
    sudo -u $username /bin/bash -- <<EOF
set -ex
mkdir -p ~/bin
git clone https://aur.archlinux.org/paru.git ~/bin/paru
pushd ~/bin/paru
makepkg -si --noconfirm
EOF

    echo -e "\n[INFO] -- Installing AUR packages..."
    sudo -u $username paru -S --noconfirm brave-bin freetube-bin visual-studio-code-bin waterfox-bin

    echo -e "\n[INFO] -- Checking for battery..."
    if [[ -d /sys/class/power_supply/BAT0 ]]; then
        echo -e "\n[INFO] -- Battery found, installing tlp..."
        sudo -u $username paru -S --noconfirm tlp tlpui
        systemctl enable tlp
    fi

    if [[ $desktopEnvironment == "kde" ]]; then
        echo -e "\n[INFO] -- Installing KDE..."
        pacman -S --noconfirm plasma libdbusmenu-glib libblockdev-btrfs udisks2-btrfs kdeconnect
        systemctl enable sddm
    elif [[ $desktopEnvironment == "gnome" ]]; then
        echo -e "\n[INFO] -- Installing GNOME..."
        pacman -S --noconfirm gnome
        systemctl enable gdm
    fi

    echo -e "\n[INFO] -- Taking initial snapshot..."
    name="root-$(date +%Y%m%d%H%M%S)"
    btrfs su snapshot -r / /.snapshots/\$name
    echo -e "\n[INFO] -- Setting up systemd-boot snapshot entry..."
    echo -e "title Arch Linux (\$name)\nlinux /vmlinuz-linux\ninitrd /$ucodePackage.img\ninitrd /initramfs-linux.img\noptions cryptdevice=UUID=$(blkid -s UUID -o value $installDisk"2"):root root=/dev/mapper/root rootflags=subvol=@snapshots/\$name ro" > /boot/loader/entries/\$name.conf
EOT

echo -e "\n[INFO] -- Installing pacman hook for systemd-boot upgrade..."
mkdir -p /mnt/etc/pacman.d/hooks
cat <<-EOT > /mnt/etc/pacman.d/hooks/95-systemd-boot.hook
	[Trigger]
	Type = Package
	Operation = Upgrade
	Target = systemd

	[Action]
	Description = Gracefully upgrading systemd-boot...
	When = PostTransaction
	Exec = /usr/bin/systemctl restart systemd-boot-update.service
EOT

echo -e "\n[INFO] -- Installing snapshotting script..."
cat <<-'EOT' > /mnt/usr/local/bin/btsnap
	#!/bin/bash

	set -e

	usage() {
	    echo -e "Usage: $(basename $0) -p <subvolume-path> ";
	    echo -e "Options:";
	    echo -e "\t-p\tPath to snapshot";
	    echo -e "Example: $(basename $0) -p /var";
	    exit 1;
	}

	while getopts "p:" opt; do
	    case $opt in
	        p) path=$OPTARG;;
	        \?) echo -e "[ERROR] -- Invalid option: $OPTARG";
	        usage;;
	        :) echo -e "[ERROR] -- Option -$OPTARG requires an argument.";
	        usage;;
	    esac
	done

	if [[ -z $path ]]; then
	    echo -e "[ERROR] -- Missing required argument!";
	    usage;
	fi

	prefix=$(btrfs su show $path | awk '/Name:/{gsub(/@/, ""); print $2}')
	if [[ -z $prefix ]]; then
	    prefix="root"
	fi
	name="$prefix-$(date +%Y%m%d%H%M%S)"

	echo -e "\n[INFO] -- Taking snapshot of $path"
	btrfs su snapshot -r $path /.snapshots/$name

	echo -e "\n[INFO] -- Setting up systemd-boot snapshot entry..."
	cat /boot/loader/entries/arch.conf | sed "s/Arch Linux/Arch Linux ($name)/; s#rootflags.*#rootflags=subvol=@snapshots/$name ro#" > /boot/loader/entries/$name.conf
EOT
chmod +x /mnt/usr/local/bin/btsnap

echo -e "\n[INFO] -- Installing pacman snapshot hook..."
cat <<-'EOT' > /mnt/etc/pacman.d/hooks/99-btrfs-snap.hook
	[Trigger]
	Operation = Upgrade
	Operation = Install
	Operation = Remove
	Type = Package
	Target = *

	[Action]
	Description = Taking root filesystem snapshot...
	When = PreTransaction
	Exec = /usr/local/bin/btsnap -p /
EOT

echo -e "\n[INFO] -- Update bashrc for $username..."
cat <<-'EOT' > /mnt/home/$username/.bashrc
	#
	# ~/.bashrc
	#

	# If not running interactively, don't do anything
	[[ $- != *i* ]] && return

	set -o noclobber
	set -o vi

	shopt -s autocd
	shopt -s cdspell
	shopt -s checkwinsize
	shopt -s cmdhist
	shopt -s direxpand
	shopt -s dotglob
	shopt -s expand_aliases
	shopt -s histappend
	shopt -s histverify
	shopt -s lithist

	alias ls='ls --color=auto'
	alias ll='ls -l --color=auto'
	alias la='ls -la --color=auto'
	alias cp='cp -i'
	alias mv='mv -i'
	alias rm='rm -i'
	alias nv='nvim $@'
	alias grep='grep --color=auto'
	alias rmswap='rm -i $(find $HOME -name "*.swp")'
	alias suspend='systemctl suspend'
	alias open='xdg-open'
	alias glog='git log --all --oneline --decorate --graph'
	alias rr='curl -s -L https://raw.githubusercontent.com/keroserene/rickrollrc/master/roll.sh | bash'

	bind "set completion-ignore-case on"
	bind "set show-all-if-ambiguous on"
	bind "set colored-stats on"
	bind "set visible-stats on"
	bind "set mark-symlinked-directories on"
	bind "set colored-completion-prefix on"
	bind "set menu-complete-display-prefix on"

	export HISTCONTROL="erasedups:ignorespace"

	source /usr/share/doc/pkgfile/command-not-found.bash

	PS1='[\u@\h \W]\$ '

	eval "$(starship init bash)"
EOT