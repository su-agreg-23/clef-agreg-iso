#!/bin/bash

# Commandes pour installer et configurer les paquets necessaires pour faire l'ISO bootable

# Afin d'etre sur d'avoir les executables dans le chroot
export PATH=/usr/sbin:/sbin:$PATH

# Pour eviter les problemes de locale
LANG=

# On commence par mettre a jour ce qui est installe
apt update -y
apt upgrade -y

# On determine la version du noyau
export KERNEL_VERSION=`cd /boot && ls -1 vmlinuz-* | tail -1 | sed 's@vmlinuz-@@'`

## Ajouts pour l'iso (utilitaires pour le live et utilitaire de boot)
apt-get install -q=2 \
	grub-efi-amd64-signed \
	casper \
	lupin-casper \
	xorriso \
	mtools \
	linux-modules-extra-${KERNEL_VERSION}

cd ~/

# Generer l'initramfs
depmod -a ${KERNEL_VERSION}
update-initramfs -u -k ${KERNEL_VERSION}

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
