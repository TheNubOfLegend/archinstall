#!/bin/bash

# Define the path to the list of packages
vital_package_list_dir="$(dirname "${BASH_SOURCE[0]}")/vital_packages.list"
package_list_dir="$(dirname "${BASH_SOURCE[0]}")/packages.list"
package_list=()

# Read the desired packages from the list file
while IFS= read -r line; do
    # Skip lines starting with a comment character (#)
    if [[ "$line" =~ ^#.*$ ]] || [ -z "$line" ]; then
        continue
    fi
    package_list+=($line)
done < "$package_list_dir"

while IFS= read -r line; do
    # Skip lines starting with a comment character (#)
    if [[ "$line" =~ ^#.*$ ]] || [ -z "$line" ]; then
        continue
    fi
    package_list+=($line)
done < "$vital_package_list_dir"

# Get the list of explicitly installed packages
installed_packages=""
while IFS= read -r line; do
    installed_packages+=" $line "
done < <( pacman -Qqe )

needed_packages=""
for package in "${package_list[@]}"; do
    # Check if the package is not installed
    if [[ ! " ${installed_packages} " =~ " ${package} " ]]; then
        needed_packages+="$package "
        echo "Installing $package"
    fi
done

echo "Installing needed: "
sudo pacman --noconfirm -S $needed_packages
# Remove packages not listed in the desired list
#for package in $installed_packages; do
#    if ! grep -q "^$package$" "$package_list"; then
#        echo "Removing $package"
#        sudo pacman -Rns --noconfirm "$package"
#    fi
#done

# Update all installed packages
echo "Updating all installed packages..."
sudo pacman -Syu --noconfirm

