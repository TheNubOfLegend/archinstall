#!/bin/bash
#config.sh
PROGRAMS=(
	#base
	base linux
	linux-firmware
	intel-ucode
	nvidia
	networkmanager
	#terminal
	zoxide zsh
	alacritty
	ripgrep fzf
	btop fastfetch
	neovim
	unzip fd
	wl-clipboard
	#browser
	firefox
	#version control
	chezmoi git
	github-cli
	#man
	man-db
	man-pages
	tldr
	texinfo
	#hyprland
	hyprland
	sddm
	dunst
	#misc
	mlocate
	thunderbird
	ttf-meslo-nerd
	#sound
	pulseaudio
	#languages
	zig go rustup
)
SHELL=zsh
USERNAME=nub
HOSTNAME=nubdesk
ROOT=""
BOOT=""
SWAP=""
#EOconfig.sh
read -p "init? (y/N): " init
if [[ "$init" = "y" || "$init" = "Y" ]]; then 
	timedatectl set-timezone America/Chicago

	fdisk -l
	read -p "part?" part
	if [[ "$part" = "y" || "$part" = "Y" ]]; then 
		read -p "disk: " disk
		fdisk $disk
	fi

	while true; do
		read -p "boot: " BOOT
		read -p "root: " ROOT
		read -p "swap: " SWAP
		read -p "jawohl? (y/N): " ja
		if [[ "$ja" = "y" || "$ja" = "Y" ]]; then 
			break
		fi
	done

	echo "formatting..."
	mkfs.fat -F 32 $BOOT
	mkfs.ext4 $ROOT
	mkswap $SWAP

	mount $BOOT /mnt
	mount --mkdir $BOOT /mnt/boot
	swapon $SWAP

	pacstrap -K /mnt base linux linux-firmware intel-ucode nvidia networkmanager neovim zsh #duplicate

	read -p "fstab? (y/N): " fstab
	if [[ "$fstab" = "y" || "$fstab" = "Y" ]]; then 
		genfstab -U /mnt >> /mnt/etc/fstab
	fi

	arch-chroot /mnt

	echo "setting time and locale..."
	ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
	hwclock --systohc

	sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
	localectl set-locale LANG="en_US.UTF-8" LC_TIME="en_US.UTF-8"

	echo $HOSTNAME > /etc/hostname

	sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

	echo "blacklist pcspkr\nblacklist snd_pcsp" > /etc/modprobe.d/nobeep.conf

	useradd -m -G wheel -s /usr/bin/$SHELL $USERNAME
	sed -i 's/#%wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL)' /etc/sudoers #does it exist yet?
	passwd $USERNAME

	mkinitcpio -P

	passwd

	exit

	umount -R /mnt
	
	read -p "done. reboot? (y/N): " reboot
	if [[ "$reboot" = "y" || "$reboot" = "Y" ]]; then 
		reboot now
	fi
fi

if ! command -v yay &> /dev/null; then
	cd ~
	git clone https://aur.archlinux.org/yay
	cd yay
	pacman -S base-devel
	makepkg -si
	yay -v
	cd ~
	rm -rf ~/yay
fi

pacman -Syyu
read -p "programs? (Y/n): " progs
if [[ "$progs" = "y" || "$progs" = "Y" ]]; then 
	pacman -S ${PROGRAMS[@]}
fi

read -p "config? (Y/n): " cfg
if [[ "$cfg" = "y" || "$cfg" = "Y" ]]; then 
	if [ ! -d ~/.local/share/chezmoi/ ]; then
		chezmoi init thenuboflegend
		chezmoi apply -v
	else
		chezmoi update -v
	fi
fi
