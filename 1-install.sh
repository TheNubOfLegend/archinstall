#!/bin/bash
clear
echo "    _             _       ___           _        _ _ "
echo "   / \   _ __ ___| |__   |_ _|_ __  ___| |_ __ _| | |"
echo "  / _ \ | '__/ __| '_ \   | || '_ \/ __| __/ _' | | |"
echo " / ___ \| | | (__| | | |  | || | | \__ \ || (_| | | |"
echo "/_/   \_\_|  \___|_| |_| |___|_| |_|___/\__\__,_|_|_|"
echo ""
echo "by Stephan Raabe, modified by nub (2024)"
echo "-----------------------------------------------------"

# ------------------------------------------------------
# Enter partition names
# ------------------------------------------------------
lsblk
echo "nvme0n1p6,7,8 for lap for testing"
read -p "Enter the name of the EFI partition (e.g. sda1): " efi
read -p "Enter the name of the ROOT partition (e.g. sda2): " root
read -p "Enter the name of the SWAP partition (e.g. sda3): " swap

# ------------------------------------------------------
# Sync time
# ------------------------------------------------------
timedatectl set-ntp true

# ------------------------------------------------------
# Format partitions
# ------------------------------------------------------
mkfs.fat -F 32 /dev/$efi
mkfs.btrfs -f /dev/$root
mkswap /dev/$swap

# ------------------------------------------------------
# Mount points for fs
# ------------------------------------------------------
# mount /dev/$root /mnt
# mount --mkdir /dev/$efi /mnt/boot
# swapon /dev/$swap

mount /dev/$root /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@cache
btrfs su cr /mnt/@home
btrfs su cr /mnt/@log

mount -o compress=zstd:1,noatime,subvol=@ /dev/$root /mnt
mkdir -p /mnt/{boot/efi,home,var/{cache,log}}
mount -o compress=zstd:1,noatime,subvol=@cache /dev/$root /mnt/var/cache
mount -o compress=zstd:1,noatime,subvol=@home /dev/$root /mnt/home
mount -o compress=zstd:1,noatime,subvol=@log /dev/$root /mnt/var/log
mount /dev/$efi /mnt/boot/efi

swapon /dev/$swap

# TODO: look into this
# mount /dev/$root /mnt
# btrfs su cr /mnt/@
# btrfs su cr /mnt/@cache
# btrfs su cr /mnt/@home
# btrfs su cr /mnt/@snapshots
# btrfs su cr /mnt/@log
# umount /mnt
#
# mount -o compress=zstd:1,noatime,subvol=@ /dev/$root /mnt
# mkdir -p /mnt/{boot/efi,home,.snapshots,var/{cache,log}}
# mount -o compress=zstd:1,noatime,subvol=@cache /dev/$root /mnt/var/cache
# mount -o compress=zstd:1,noatime,subvol=@home /dev/$root /mnt/home
# mount -o compress=zstd:1,noatime,subvol=@log /dev/$root /mnt/var/log
# mount -o compress=zstd:1,noatime,subvol=@snapshots /dev/$root /mnt/.snapshots
# mount /dev/$efi /mnt/boot/efi
# TODO: look into this

# ------------------------------------------------------
# Install base packages
# ------------------------------------------------------
echo "Start reflector..."
reflector --latest 10 -c "United States," -p https --sort rate --save /etc/pacman.d/mirrorlist

sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf

vital=(base base-devel git linux linux-firmware neovim reflector sudo)

proc_type=$(lscpu)
if grep -E "GenuineIntel" <<< ${proc_type}; then
    echo "Installing Intel microcode"
    vital+=(intel-ucode)
elif grep -E "AuthenticAMD" <<< ${proc_type}; then
    echo "Installing AMD microcode"
    vital+=(amd-ucode)
fi

gpu_type=$(lspci)
if grep -E "NVIDIA|GeForce" <<< ${gpu_type}; then
    vital+=(nvidia)
    nvidia=true
elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
    vital+=(xf86-video-amdgpu)
elif grep -E "Integrated Graphics Controller" <<< ${gpu_type}; then
    vital+=(libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa)
elif grep -E "Intel Corporation UHD" <<< ${gpu_type}; then
    vital+=(libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa)
fi

pacstrap -KP /mnt "${vital[@]}"
for v in "${vital[@]}"; do
    echo "$v" >> "$(dirname "${BASH_SOURCE[0]}")/vital_packages.list"
done

# ------------------------------------------------------
# Generate fstab
# ------------------------------------------------------
genfstab -U /mnt > /mnt/etc/fstab
cat /mnt/etc/fstab

# ------------------------------------------------------
# Install configuration scripts
# ------------------------------------------------------
mkdir /mnt/archinstall
cp 2-configuration.sh /mnt/archinstall/
cp vital_packages.list /mnt/archinstall
cp -r ./packages /mnt/archinstall
cp -r ./scripts /mnt/archinstall

# ------------------------------------------------------
# Chroot to installed sytem
# ------------------------------------------------------
arch-chroot /mnt ./archinstall/2-configuration.sh
