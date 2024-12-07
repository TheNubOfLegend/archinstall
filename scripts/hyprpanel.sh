#!/bin/bash

#Dependencies
sh ./bun.sh
sudo pacman -S --no-confirm libdbusmenu-gtk3 networkmanager gnome-bluetooth-3.0 pipewire libgtop bluez bluez-utils wl-clipboard dart-sass brightnessctl

if [ ! -d "$HOME/.local/lib" ]; then
    mkdir $HOME/.local/lib
fi

git clone https://github.com/Jas-SinghFSU/HyprPanel $HOME/.local/lib/HyprPanel

sh $HOME/.local/lib/HyprPanel/make_agsv1.sh
sh $HOME/.local/lib/HyprPanel/install_fonts.sh

# Installs HyprPanel to ~/.config/ags
ln -s $HOME/.local/lib/HyprPanel $HOME/.config/ags
