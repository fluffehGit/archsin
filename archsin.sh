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
#############################################################################################################################

NC='\e[0m'
YELLOW='\e[33m'
RED='\e[31m'

exec &>> >(tee -a /root/arch-install.log)

usage() {
	echo -e "Usage: $(basename $0) -d <disk> -e <encryption-password> -m <country code> -t <timezone> -h <hostname> -u <username> -p <password> -g <graphics-driver> -w <kde/gnome>"
	echo -e "Options:"
	echo -e "\t-d\tDisk to install Arch Linux on"
	echo -e "\t-e\tEncryption password for the disk"
	echo -e "\t-m\tCountry code for mirrorlist (e.g. US)"
	echo -e "\t-t\tTimezone city (e.g. New_York)"
	echo -e "\t-h\tHostname for the system"
	echo -e "\t-u\tUsername for the system"
	echo -e "\t-p\tPassword for the user"
	echo -e "\t-g\tGraphics driver to install (e.g. nvidia)"
	echo -e "\t-w\tDesktop environment to install (e.g. kde, gnome)"
	echo -e "Example: $(basename $0) -d /dev/sda -e SecurePass123 -m US -t New_York -h archbox -u archuser -p SecureUserPass123 -g nvidia -w kde"
	exit 1
}

while getopts "d:e:m:t:h:u:p:g:w:" opt; do
	case $opt in
	d) installDisk=$OPTARG ;;
	e) encryptionPassword=$OPTARG ;;
	m) mirrorlistCountry=$OPTARG ;;
	t) timezoneCity=$OPTARG ;;
	h) hostname=$OPTARG ;;
	u) username=$OPTARG ;;
	p) userPassword=$OPTARG ;;
	g) graphicsDriver=$OPTARG ;;
	w) desktopEnvironment=$OPTARG ;;
	\?) usage ;;
	:) usage ;;
	esac
done

if [[ -z $installDisk || -z $encryptionPassword || -z $mirrorlistCountry || -z $timezoneCity || -z $hostname || -z $username || -z $userPassword || -z $desktopEnvironment ]]; then
	echo -e "${RED}[ERROR] -- Missing required arguments${NC}"
	usage
fi

if [[ $EUID -ne 0 ]]; then
	echo "${RED}[ERROR] -- This script must be run as root${NC}"
	exit 1
fi

if [[ ! -f /sys/firmware/efi/fw_platform_size ]]; then
	echo "${RED}[ERROR] -- Legacy system detected, exiting...${NC}"
	exit 1
fi

if ! timedatectl list-timezones | grep -qi $timezoneCity; then
	echo "${RED}[ERROR] -- Timezone city $timezoneCity not found${NC}"
	exit 1
fi

echo -e "\n[INFO] -- Enabling NTP..."
timedatectl set-ntp true

echo -e "${YELLOW}[WARNING] -- This script will erase all data on $installDisk. Do you want to continue? (y/n)${NC}"
read -r answer
if [[ $answer == "n" ]]; then
	echo "Exiting..."
	exit 0
fi

echo -e "\n[INFO] -- Partitioning $installDisk..."
echo -e "g\nw\n" | fdisk $installDisk
echo -e "n\n\n\n+1G\nn\n\n\n\nt\n1\n1\nw\n" | fdisk $installDisk

echo -e "\n[INFO] -- Creating boot partition..."
if [[ $installDisk == "/dev/nvme"* ]]; then
	bootPartition="${installDisk}p1"
	rootPartition="${installDisk}p2"
else
	bootPartition="${installDisk}1"
	rootPartition="${installDisk}2"
fi
mkfs.fat -F32 $bootPartition

echo -e "\n[INFO] -- Encrypting partition ${rootPartition}..."
echo -n $encryptionPassword | cryptsetup luksFormat --type luks2 $rootPartition
echo -n $encryptionPassword | cryptsetup open --type=luks2 $rootPartition root

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
mount $bootPartition /mnt/boot

echo -e "\n[INFO] -- Enabling swap..."
btrfs filesystem mkswapfile --size 8G --uuid clear /mnt/swap/swapfile
swapon /mnt/swap/swapfile

echo -e "\n[INFO] -- Check CPU vendor..."
cpuVendor=$(lscpu | grep -i vendor | awk 'NR==1 {print $3}')
if [[ $cpuVendor == "AuthenticAMD" ]]; then
	echo -e "\n[INFO] -- AMD CPU detected, installing amd-ucode..."
	ucodePackage="amd-ucode"
elif [[ $cpuVendor == "GenuineIntel" ]]; then
	echo -e "\n[INFO] -- Intel CPU detected, installing intel-ucode..."
	ucodePackage="intel-ucode"
fi

echo -e "\n[INFO] -- Installing base system..."
pacstrap /mnt base base-devel btrfs-progs linux linux-firmware $ucodePackage git vim networkmanager man-pages man-db firewalld rsync

genfstab -U /mnt >>/mnt/etc/fstab
sed -i 's/fmask=0022,dmask=0022/fmask=0077,dmask=0077/' /mnt/etc/fstab
echo -e "/swap/swapfile none swap defaults 0 0" >>/mnt/etc/fstab

arch-chroot /mnt /bin/bash -- <<EOT
    exec &>> >(tee -a /var/log/arch-install-chroot.log)

    set -e

    echo -e "\n[INFO] -- Configuring timezone..."
    ln -sf /usr/share/zoneinfo/$timezoneCity /etc/localtime
    hwclock --systohc

    echo -e "\n[INFO] -- Configuring locale..."
    sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    echo "C.UTF-8 UTF-8" >> /etc/locale.gen
    locale-gen
    echo -e "LANG=en_US.UTF-8"> /etc/locale.conf

    echo -e "\n[INFO] -- Configuring hostname..."
    echo "$hostname" > /etc/hostname

    echo -e "\n[INFO] -- Configuring hosts file..."
    echo -e "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\t$hostname.localdomain\t$hostname" > /etc/hosts

    echo -e "\n[INFO] -- Configuring initramfs..."
    sed -i 's/^HOOKS.*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt btrfs filesystems fsck resume)/' /etc/mkinitcpio.conf
    sed -i 's/^MODULES.*/MODULES=(btrfs)/' /etc/mkinitcpio.conf
    sed -i 's/^BINARIES.*/BINARIES=(btrfs)/' /etc/mkinitcpio.conf
    mkinitcpio -P

    echo -e "\n[INFO] -- Configuring user $username..."
    useradd -m -G wheel -s /bin/bash $username
    echo -e "$userPassword\n$userPassword" | passwd $username
    sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

    echo -e "\n[INFO] -- Installing systemd-boot..."
    bootctl --path=/boot/ install

    echo -e "\n[INFO] -- Configuring systemd-boot..."
    mkdir -p /boot/loader/entries
    echo -e "default arch.conf\ntimeout 4\neditor no" > /boot/loader/loader.conf

    echo -e "\n[INFO] -- Configuring systemd-boot default entry..."
    echo -e "title Arch Linux\nlinux /vmlinuz-linux\ninitrd /$ucodePackage.img\ninitrd /initramfs-linux.img\noptions cryptdevice=UUID=$(blkid -s UUID -o value $rootPartition):root root=/dev/mapper/root rootflags=subvol=@ rw" > /boot/loader/entries/arch.conf

    echo -e "\n[INFO] -- Setting suspend then hibernate delay to 2 hours..."
    sed -i 's/#HibernateDelaySec.*/HibernateDelaySec=7200/' /etc/systemd/sleep.conf

    echo -e "\n[INFO] -- Enabling services..."
    systemctl enable NetworkManager
    systemctl enable fstrim.timer
    systemctl enable firewalld

    echo -e "\n[INFO] -- Tune pacman..."
    sed -i 's/^#Color/Color/' /etc/pacman.conf
    sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
    pacman -Syy --noconfirm reflector
    reflector --country $mirrorlistCountry --latest 10 --fastest 5 --protocol http,https --sort rate --save /etc/pacman.d/mirrorlist

    echo -e "\n[INFO] -- Installing base tools..."
		pacman -S --noconfirm alacritty android-tools bash-completion bat bitwarden chromium curl dosfstools dust efibootmgr exfatprogs fd firefox fwupd fzf lazygit markdownlint net-tools nfs-utils nodejs npm ntfs-3g nushell neovim otf-firamono-nerd p7zip pkgfile podman podman-compose procs ripgrep sd starship thunderbird tlp tokei ttf-firacode-nerd unrar unzip wget wl-clipboard zoxide $graphicsDriver

    echo -e "\n[INFO] -- Installing LazyVim..."
    sudo -u $username /bin/bash -e -- <<-EOF
			rm -rf ~/.config/nvim ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim 2> /dev/null
			git clone https://github.com/LazyVim/starter ~/.config/nvim
			rm -rf ~/.config/nvim/.git
EOF

    echo -e "\n[INFO] -- Installing catppuccin alacritty themes..."
    sudo -u $username /bin/bash -e -- <<-EOF
			mkdir -p ~/.config/alacritty/
			curl -LO --output-dir ~/.config/alacritty https://github.com/catppuccin/alacritty/raw/main/catppuccin-mocha.toml
			curl -LO --output-dir ~/.config/alacritty https://github.com/catppuccin/alacritty/raw/main/catppuccin-latte.toml
EOF

    echo -e "\n[INFO] -- Installing paru..."
    echo "$username ALL=(ALL) NOPASSWD: /usr/bin/pacman" >> /etc/sudoers
    sudo -u $username /bin/bash -e -- <<-EOF
			mkdir -p ~/bin
			git clone https://aur.archlinux.org/paru.git ~/bin/paru
			pushd ~/bin/paru
			makepkg -si --noconfirm
EOF

    echo -e "\n[INFO] -- Installing AUR packages..."
    sudo -u $username paru -S --noconfirm brave-bin freetube-bin localsend-bin waterfox-bin

if [[ $desktopEnvironment == "kde" ]]; then
    echo -e "\n[INFO] -- Installing KDE..."
    pacman -S --noconfirm plasma dolphin libdbusmenu-glib libblockdev-btrfs power-profiles-daemon udisks2-btrfs kdeconnect
    sudo -u $username /bin/bash -e -- <<-EOF
			paru -S --noconfirm plasma6-applets-window-title
			git clone https://github.com/boraerciyas/kde_controlcentre ~/.local/share/plasma/plasmoids/kde_controlcentre
			pushd ~/.local/share/plasma/plasmoids/kde_controlcentre
			kpackagetool6 -i package
			ln -s ~/.local/share/kpackage/generic/com.github.boraerciyas.kde_controlcentre ~/.local/share/plasma/plasmoids/
			popd
EOF
    systemctl enable sddm
    mkdir -p /etc/sddm.conf.d
    cat <<-EOF > /etc/sddm.conf.d/kde_settings.conf
			[Autologin]
			Relogin=false
			Session=
			User=

			[General]
			HaltCommand=/usr/bin/systemctl poweroff
			RebootCommand=/usr/bin/systemctl reboot

			[Theme]
			Current=breeze
			CursorSize=
			CursorTheme=breeze_cursors
			Font=Cantarell,12,-1,5,50,0,0,0,0,0

			[Users]
			MaximumUid=60513
			MinimumUid=1000
EOF
    systemctl enable bluetooth
elif [[ $desktopEnvironment == "gnome" ]]; then
    echo -e "\n[INFO] -- Installing GNOME..."
    pacman -S --noconfirm gnome
    systemctl enable gdm
fi
sed -i '/^'$username'/d' /etc/sudoers

echo -e "\n[INFO] -- Taking initial snapshot..."
name="root-$(date +%Y%m%d%H%M%S)"
btrfs su snapshot -r / /.snapshots/\$name
echo -e "\n[INFO] -- Configuring systemd-boot snapshot entry..."
echo -e "title Arch Linux (\$name)\nlinux /vmlinuz-linux\ninitrd /$ucodePackage.img\ninitrd /initramfs-linux.img\noptions cryptdevice=UUID=$(blkid -s UUID -o value $rootPartition):root root=/dev/mapper/root rootflags=subvol=@snapshots/\$name ro" > /boot/loader/entries/\$name.conf
EOT

echo -e "\n[INFO] -- Installing pacman hook for systemd-boot upgrade..."
mkdir -p /mnt/etc/pacman.d/hooks
cat <<-EOT >/mnt/etc/pacman.d/hooks/95-systemd-boot.hook
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
cat <<-'EOT' >/mnt/usr/local/bin/btsnap
	#!/bin/bash

	RED="\e[31m"
	NC="\e[0m"

	clean=false

	set -e

	if [[ $EUID -ne 0 ]]; then
		echo -e "${RED}[ERROR] -- This script must be run as root${NC}"
		exit 1
	fi

	usage() {
		echo -e "Usage: $(basename $0) <option> <subvolume-path> "
		echo -e "Options:"
		echo -e "\t-p\tPath to snapshot"
		echo -e "\t-c\tClean snaphsots mode"
		echo -e "\t-k x\tKeep the most recent x snapshots"
		echo -e "Example: $(basename $0) -p /var"
		exit 1
	}

	while getopts "p:ck:" opt; do
		case $opt in
		p) path=$OPTARG ;;
		c) clean=true ;;
		k) keep=$OPTARG ;;
		:)
			echo -e "${RED}[ERROR] -- Option $OPTARG requires an argument!"
			usage
			;;
		\?)
			echo -e "${RED}[ERROR] -- Invalid option: $OPTARG${NC}"
			usage
			;;
		esac
	done

	if [[ -z $path ]]; then
		echo -e "${RED}[ERROR] -- Missing subvolume path!${NC}"
		usage
	fi

	prefix=$(btrfs su show $path | awk '/Name:/{gsub(/@/, ""); print $2}')
	if [[ -z $prefix ]]; then
		prefix="root"
	fi
	name="$prefix-$(date +%Y%m%d%H%M%S)"

	if $clean; then
		echo -e "\n[INFO] -- Cleaning snapshots..."
		ls -1 /.snapshots | sort -r | grep "${prefix}-" | awk "NR>${keep:-0}" | xargs -I {} btrfs su delete /.snapshots/{}

		if [[ $prefix == "root" ]]; then
			echo -e "\n[INFO] -- Removing bootloader entries..."
			ls -1 /boot/loader/entries | sort -r | grep "root-" | awk "NR>${keep:-0}" | xargs -I {} rm -rf /boot/loader/entries/{}
		fi
	else
		echo -e "\n[INFO] -- Taking snapshot of $path"
		btrfs su snapshot -r $path /.snapshots/$name

		if [[ $prefix == "root" ]]; then
			echo -e "\n[INFO] -- Setting up systemd-boot snapshot entry..."
			cat /boot/loader/entries/arch.conf | sed "s/Arch Linux/Arch Linux ($name)/; s#rootflags.*#rootflags=subvol=@snapshots/$name ro#" >/boot/loader/entries/$name.conf
		fi
	fi
EOT
chmod +x /mnt/usr/local/bin/btsnap

echo -e "\n[INFO] -- Installing pacman snapshot hook..."
cat <<-'EOT' >/mnt/etc/pacman.d/hooks/99-btrfs-snap.hook
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
