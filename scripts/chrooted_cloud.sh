#!/bin/bash

# Commandes pour installer et configurer les paquets necessaires pour faire l'ISO bootable

# Afin d'etre sur d'avoir les executables dans le chroot
export PATH=/usr/sbin:/sbin:$PATH

# Pour eviter les problemes de locale
LANG=

# On commence par mettre a jour ce qui est installe
apt update -y
apt upgrade -y

## Ajouts pour l'iso (utilitaires pour le live et utilitaire de boot)
apt-get install -q=2 \
	grub-efi-amd64-signed \
	casper \
	lupin-casper \
	xorriso \
	mtools

cd ~/

# Generer l'initramfs
UNAMER=`ls /boot/config*`
depmod -a ${UNAMER/\/boot\/config-/}
update-initramfs -u -k ${UNAMER/\/boot\/config-/}

# Tout nettoyer
apt-get autoremove -y
apt-get clean -y
rm -rf ~/clef-agreg
find /var/log -regex '.*?[0-9].*?' -exec rm -v {} \;
find /var/log -type f | while read file
do
        cat /dev/null | tee $file
done
exit
