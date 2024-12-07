#!/bin/bash

mkdir $HOME/.local/lib/yay
cd $HOME/.local/lib/yay

git clone https://aur.archlinux.org/yay-git.git
cd yay-git
makepkg -si
