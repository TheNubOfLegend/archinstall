#!/bin/bash

# Define the path to the list of packages
universal_package_list_dir="$(dirname $0)/packages/universal.list"
#TODO: add verification that <hostname>.list exists
package_list_dir="$(dirname $0)/packages/$(cat /etc/hostname).list"
package_list=()
script_list=()

# Read the desired packages from the list file
while read -r line; do
    # Skip lines starting with a comment character (#)
    if [[ "$line" =~ ^/.*$ ]] && [ ! -z "$line" ]; then
        script_list+=($line)
    elif [[ ! "$line" =~ ^#.*$ ]] && [ ! -z "$line" ]; then
        package_list+=($line)
    fi
done < <(cat $package_list_dir && cat $universal_package_list_dir)

echo "Installing needed: "
 echo ${package_list[@]}
# echo ${script_list[@]}
sudo pacman --noconfirm --needed -S ${package_list[@]}
# Remove packages not listed in the desired list
# for package in $installed_packages; do
#    if ! grep -q "^$package$" "$package_list"; then
#        echo "Removing $package"
#        sudo pacman -Rns --noconfirm "$package"
#    fi
# done

# Update all installed packages
echo "Updating all installed packages..."
sudo pacman -Syu --noconfirm

