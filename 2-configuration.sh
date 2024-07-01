#!/bin/bash

#   ____             __ _                       _   _             
#  / ___|___  _ __  / _(_) __ _ _   _ _ __ __ _| |_(_) ___  _ __  
# | |   / _ \| '_ \| |_| |/ _` | | | | '__/ _` | __| |/ _ \| '_ \ 
# | |__| (_) | | | |  _| | (_| | |_| | | | (_| | |_| | (_) | | | |
#  \____\___/|_| |_|_| |_|\__, |\__,_|_|  \__,_|\__|_|\___/|_| |_|
#                         |___/                                   
# by Stephan Raabe (2023)
# ------------------------------------------------------
clear
#keyboardlayout="de-latin1"
zoneinfo="America/Chicago"
hostname=""
username="nub"

# ------------------------------------------------------
# Set System Time
# ------------------------------------------------------
ln -sf /usr/share/zoneinfo/$zoneinfo /etc/localtime
hwclock --systohc

# ------------------------------------------------------
# Synchronize mirrors
# ------------------------------------------------------
pacman -Syy

# ------------------------------------------------------
# Install Packages
# ------------------------------------------------------
source "$(dirname "${BASH_SOURCE[0]}")/packages.sh"

# ------------------------------------------------------
# set lang utf8 US
# ------------------------------------------------------
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

# ------------------------------------------------------
# Set Keyboard
# ------------------------------------------------------
echo "FONT=ter-v18n" >> /etc/vconsole.conf
#echo "KEYMAP=$keyboardlayout" >> /etc/vconsole.conf

# ------------------------------------------------------
# Set hostname and localhost
# ------------------------------------------------------
while true
	do
		read -p "Please name your machine: " hostname
		# hostname regex (!!couldn't find spec for computer name!!)
		if [[ "${hostname,,}" =~ ^[a-z][a-z0-9_.-]{0,62}[a-z0-9]$ ]]
		then
			break
		fi
		# if validation fails allow the user to force saving of the hostname
		read -p "Hostname doesn't seem correct. Do you still want to save it? (y/n): " force 
		if [[ "${force,,}" = "y" ]]
		then
			break
		fi
	done
echo "$hostname" >> /etc/hostname
#echo "127.0.0.1 localhost" >> /etc/hosts
#echo "::1       localhost" >> /etc/hosts
#echo "127.0.1.1 $hostname.localdomain $hostname" >> /etc/hosts
clear

# ------------------------------------------------------
# Set Root Password
# ------------------------------------------------------
echo "Set root password"
passwd root

# ------------------------------------------------------
# Add User
# ------------------------------------------------------
echo "Add user $username"
useradd -m -G wheel $username -s /bin/zsh
passwd $username

# ------------------------------------------------------
# Enable Services
# ------------------------------------------------------
systemctl enable NetworkManager
#systemctl enable cups.service
systemctl enable reflector.timer
#systemctl enable acpid

# ------------------------------------------------------
# Add user to wheel
# ------------------------------------------------------
clear
#echo "Uncomment %wheel group in sudoers (around line 85):"
#echo "Before: #%wheel ALL=(ALL:ALL) ALL"
#echo "After:  %wheel ALL=(ALL:ALL) ALL"
#echo ""
#read -p "Open sudoers now?" c
#EDITOR=nvim sudo -E visudo
usermod -aG wheel $username
sed -i 's/#%wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
# ------------------------------------------------------
# nobeep
# ------------------------------------------------------
echo "blacklist pcspkr
blacklist snd_pcsp" > /etc/modprobe.d/nobeep.conf

# ------------------------------------------------------
# Systemd-boot
# ------------------------------------------------------
bootctl install

echo "title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=UUID=$(blkid /dev/$root | grep -oP ' UUID="\K[^"\s]+') rw" > /boot/loader/entries/arch.conf

if nvidia; then
    echo "options nvidia_drm modeset=1 fbdev=1" >> /etc/modprobe.d/nvidia.conf
fi

echo "timeout 7
default @saved
console-mode keep" > /boot/loader/loader.conf

# ------------------------------------------------------
# Add setfont (& nvidia for hyprland!!!!!!!) to mkinitcpio
# ------------------------------------------------------
if nvidia; then
    sed -i 's/^MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/g' /mnt/etc/mkinitcpio.conf
fi
sed -i 's/BINARIES=()/BINARIES=(setfont)/g' /mnt/etc/mkinitcpio.conf
mkinitcpio -p linux

# ------------------------------------------------------
# chezmoi init
# ------------------------------------------------------
chezmoi init thenuboflegend

# ------------------------------------------------------
# Copy installation scripts to home directory 
# ------------------------------------------------------
cp /archinstall/3-yay.sh /home/$username
cp /archinstall/vital_packages.list /home/$username
cp /archinstall/packages.list /home/$username
cp /archinstall/packages.sh /home/$username

clear
echo "     _                   "
echo "  __| | ___  _ __   ___  "
echo " / _' |/ _ \| '_ \ / _ \ "
echo "| (_| | (_) | | | |  __/ "
echo " \__,_|\___/|_| |_|\___| "
echo "                         "
echo ""
echo "Please find the following additional installation scripts in your home directory:"
echo "- yay AUR helper: 3-yay.sh"
echo ""
echo "Please exit & shutdown (shutdown -h now), remove the installation media and start again."
echo "Important: Activate WIFI after restart with nmtui."
