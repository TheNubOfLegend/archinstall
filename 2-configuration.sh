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
# set lang utf8 US
# ------------------------------------------------------
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

# ------------------------------------------------------
# Set Keyboard
# ------------------------------------------------------
#echo "FONT=ter-v18n" >> /etc/vconsole.conf
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

#NOTE: must come after hostname for current package script
# ------------------------------------------------------
# Synchronize mirrors
# ------------------------------------------------------
pacman -Syy

# ------------------------------------------------------
# Install Packages
# ------------------------------------------------------
source "$(dirname "${BASH_SOURCE[0]}")/packages.sh"

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

sed -i 's/--sort age/--sort rate/g' /etc/xdg/reflector/reflector.conf
sed -i 's/--latest 5/--latest 10/g' /etc/xdg/reflector/reflector.conf

systemctl enable reflector.timer --now
systemctl enable reflector.service --now

systemctl enable paccache.timer --now
systemctl enable paccache.service --now
#systemctl enable acpid

# ------------------------------------------------------
# Pacman
# ------------------------------------------------------
sed -i 's/#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
sed -i 's/#Color/Color/' /etc/pacman.conf
sed -i 's/#Misc options/#Misc options\nILoveCandy/' /etc/pacman.conf

# ------------------------------------------------------
# Add user to wheel
# ------------------------------------------------------
usermod -aG wheel $username
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

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
# Add nvidia for hyprland to mkinitcpio
# ------------------------------------------------------
if nvidia; then
    sed -i 's/^MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/g' /mnt/etc/mkinitcpio.conf
fi
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
echo ""
echo "Please exit & shutdown (shutdown -h now), remove the installation media and start again."
echo "Important: Activate WIFI after restart with nmtui."
