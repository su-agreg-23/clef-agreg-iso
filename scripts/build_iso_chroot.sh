#!/bin/bash

# Script principal pour creer un .iso bootable correspondant a la VM clef-agreg
# Version chroot only
# Utile pour demarrer l'environnement du concours sur clef avec Ventoy par exemple

# Le script doit etre lance en root
if [ `whoami` != "root" ]; then
    echo "Il faut lancer le script en tant que root"
    exit 1
fi
# Le repertoire depuis lequel il est lance doit avoir suffisamment d'espace libre - 40 Go environ

# Le systeme depuis lequel on fait les manipulations doit avoir d'installe un certain nombre d'outils:
# wget : pour telecharger un fichier depuis la ligne de commande
# rsync : utilitaire pour synchroniser des fichiers
# qemu : emulateur tres repandu pour demarrer une vm
# squashfs : les outils pour gerer les systemes de fichiers squashfs


## PARTIE I : CONFIGURATION ET PREPARATION
echo "Partie I : CONFIGURATION ET PREPARATION"
# Configuration des repertoires et variables
export RACINE=`pwd`              # Repertoire dans lequel tout sera cree
export CHROOT=${RACINE}/root_fs  # Systeme de fichier dans lequel on va installer et configurer clef-agreg
export SCRIPTS=${RACINE}/scripts # Repertoire dans lequel se situent les scripts, y compris celui-ci
export RAWFS=${RACINE}/raw_fs    # Point de montage de l'image recuperee sur les serveurs ubuntu
export TMP=${RACINE}/tmp_files   # Repertoire pour tous les fichiers temporaires (image disque surtout)
export ISO_DIR=iso               # Repertoire relatif pour l'image ISO
export CD=${CHROOT}/${ISO_DIR}   # Racine de ce qui sera dans l'image ISO
export FORMAT=squashfs           # Format du systeme de fichier compresse sur l'ISO
export FS_DIR=casper             # Repertoire du noyau pour le live
export VERSION=focal             # Version d'ubuntu, focal = 20.04 LTS, jammy = 22.04 LTS

# Creation des repertoires
mkdir -p ${RAWFS} ${CHROOT} ${TMP}

# Recuperation de l'image serveur cloud ubuntu 20.04 LTS
cd ${TMP}
wget https://cloud-images.ubuntu.com/${VERSION}/current/${VERSION}-server-cloudimg-amd64.img
cd ${RACINE}

# Conversion dans un format montable (RAW)
qemu-img convert ${TMP}/${VERSION}-server-cloudimg-amd64.img ${TMP}/${VERSION}.raw

# Suppression de l'image originale
rm -f ${TMP}/${VERSION}-server-clouding-amd64.img

# Montage de l'image afin de copier ses fichiers dans le futur chroot
# Detection automatique du numero du premier secteur de la partition principale du fichier .raw
START=$( fdisk -l -o Device,Start ${TMP}/${VERSION}.raw | grep "${VERSION}.raw1 " | gawk '{print $2}' )

# Detection de la taille en octets d'un secteur du disque
SECTEUR=$( fdisk -l ${TMP}/${VERSION}.raw | grep "^Unit" | gawk '{print $(NF-2)}' )

# Calcul de l'offset de montage (ou demarre la partition principale dans l'image raw)
OFFSET=$(( ${START} * ${SECTEUR} ))
# Montage
mount -o ro,loop,offset=${OFFSET} ${TMP}/${VERSION}.raw ${RAWFS}

# Copie des fichier par rsync utile pour les options --one-file-system et --exclude
rsync -av --one-file-system \
      --exclude=${RAWFS}/proc/* \
      --exclude=${RAWFS}/dev/* \
      --exclude=${RAWFS}/sys/* \
      --exclude=${RAWFS}/lost+found \
      --exclude=${RAWFS}/etc/fstab \
      --exclude=${RAWFS}/etc/gshadow* \
      --exclude=${RAWFS}/etc/hosts \
      --exclude=${RAWFS}/etc/mtab \
      --exclude=${RAWFS}/etc/shadows* \
      --exclude=${RAWFS}/etc/timezone \
      ${RAWFS}/ ${CHROOT}

# Demontage, on a plus besoin de l'image raw, on la supprime donc (pour gagner de la place)
umount ${RAWFS}
rm -f ${TMP}/${VERSION}.raw

## PARTIE II : INSTALLATION DES PAQUETS ET CONFIGURATION DU CHROOT
echo "Partie II: installation des paquets et configuration du chroot"

function chroot_prepare ()
{
    # Preparation du chroot: on monte les systemes de fichiers necessaires et on place le bon resolv.conf pour acceder au reseau dans le chroot
    mount --bind /dev/ ${CHROOT}/dev
    mount -t proc proc ${CHROOT}/proc
    mount -t sysfs sysfs ${CHROOT}/sys
    mount -o bind /run ${CHROOT}/run
    mv ${CHROOT}/etc/resolv.conf ${CHROOT}/etc/resolv.conf.old
    cp /etc/resolv.conf ${CHROOT}/etc/resolv.conf
}

function chroot_after ()
{
   # Nettoyage apres le chroot
    umount ${CHROOT}/dev
    umount ${CHROOT}/proc
    umount ${CHROOT}/sys
    umount ${CHROOT}/run
    rm ${CHROOT}/etc/resolv.conf
    mv ${CHROOT}/etc/resolv.conf.old ${CHROOT}/etc/resolv.conf 
}

chroot_prepare
cp ${SCRIPTS}/chrooted_install.sh ${CHROOT}/root/chrooted_install.sh
chmod +x ${CHROOT}/root/chrooted_install.sh

# Execution du script dans le chroot
chroot ${CHROOT} /root/chrooted_install.sh

chroot_after
rm ${CHROOT}/root/chrooted_install.sh

## PARTIE III : Compression du systeme racine, preparation de l'iso
echo "Partie III : Compression du systeme racine, preparation de l'iso"

# Recuperation de la version du kernel pour l'iso
export KERNEL_VERSION=`cd ${CHROOT}/boot && ls -1 vmlinuz-* | tail -1 | sed 's@vmlinuz-@@'`

# Creation du systeme de fichier compresse en squashfs:
mksquashfs ${CHROOT} ${TMP}/filesystem.${FORMAT} -noappend

# Creation de la taille du systeme de fichier et de son md5
echo -n $(du -s --block-size=1 ${CHROOT} | tail -1 | awk '{print $1}') | tee ${TMP}/filesystem.size


# Creation des repertoires pour l'ISO, doit NECESSAIREMENT se trouver dans le CHROOT pour generer l'iso
mkdir -p ${CD}/{${FS_DIR},boot/grub}

# On met les fichiers au bon endroit maintenant que le squashfs est généré
mv ${TMP}/filesystem.${FORMAT} ${CD}/${FS_DIR}/
mv ${TMP}/filesystem.size ${CD}/${FS_DIR}/

find ${CD} -type f -print0 | xargs -0 md5sum | sed "s@${CD}@.@" | grep -v md5sum.txt | tee -a ${CD}/md5sum.txt

# Copie du kernel et de l'intiram dans les parties adequates de l'ISO
cp -vp ${CHROOT}/boot/vmlinuz-${KERNEL_VERSION} ${CD}/${FS_DIR}/vmlinuz
cp -vp ${CHROOT}/boot/initrd.img-${KERNEL_VERSION} ${CD}/${FS_DIR}/initrd.img

## PARTIE IV : Configuration de grub
echo "Partie IV: Configuration de grub"

# Ajout de Grub2 sur l'arborescence de l'ISO
cp -av ${CHROOT}/boot/grub ${CD}/boot/
cp -av ${CHROOT}/boot/efi ${CD}/boot/

# Verifier si c'est toujours utile:
mkdir -p ${CD}/boot/efi/EFI/BOOT/
cp ${CHROOT}/usr/lib/grub/x86_64-efi-signed/grubx64.efi.signed ${CD}/boot/efi/EFI/BOOT/grubx64.efi

# Creation du grub.cfg
rm -f ${CD}/boot/grub/{grub.cfg,*.txt,grubenv}
echo "
set default=\"0\"
set timeout=10
if loadfont /boot/grub/unicode.pf2
then
  set gfxmode=auto
  insmod efi_gop
  insmod efi_uga
  insmod gfxterm
  insmod png
  terminal_output gfxterm
fi
set theme=/boot/grub/theme.cfg
menuentry \"Clef Agreg\" {
set gfxpayload=keep
linux /"${FS_DIR}"/vmlinuz boot="${FS_DIR}" \$KERNEL_PARAMS quiet splash --
initrd /"${FS_DIR}"/initrd.img
}
menuentry \"Clef Agreg in safe mode\" {
set gfxpayload=keep
linux /"${FS_DIR}"/vmlinuz boot="${FS_DIR}" \$KERNEL_PARAMS nomodeset quiet splash --
initrd /"${FS_DIR}"/initrd.img
}
menuentry \"Check Disk for Defects\" {
set gfxpayload=keep
linux /"${FS_DIR}"/vmlinuz boot="${FS_DIR}" \$KERNEL_PARAMS integrity-check quiet splash --
initrd /"${FS_DIR}"/initrd.img
}
menuentry \"Boot from the first hard disk\" {
set root=(hd0)
chainloader +1
}
" > ${CD}/boot/grub/grub.cfg

# Creation du theme.cfg
echo "
title-color: \"white\"
title-text: \"clef-agreg\"
title-font: \"Sans Regular 16\"
desktop-color: \"black\"
desktop-image: \"/boot/grub/splash.png\"
message-color: \"white\"
message-bg-color: \"black\"
terminal-font: \"Sans Regular 12\"
+ boot_menu {
  top = 130
  left = 5%
  width = 85%
  height = 150
  item_font = \"Sans Regular 12\"
  item_color = \"white\"
  selected_item_color = \"yellow\"
  item_height = 20
  item_padding = 15
  item_spacing = 5
}
+ vbox {
  top = 100%
  left = 2%
  + label {text = \"Appuyer sur la touche \'E\' pour modifier\" font = \"Sans 10\" color = \"white\" align = \"left\"}
}
" > ${CD}/boot/grub/theme.cfg

# Copie du splash screen
cp ${RACINE}/splash.png ${CD}/boot/grub/splash.png

# On remet le chroot pour creer l'image iso bootable
chroot_prepare
chroot ${CHROOT} grub-mkrescue -o ~/clef-agreg.iso /${ISO_DIR} --iso-level 3
chroot_after

# On bouge l'iso dans la racine
# On attend que l'image iso ait finit d'etre ecrite
mv ${CHROOT}/root/clef-agreg.iso ${RACINE}/
# On synchronise pour etre sur que toutes les operations sur les fichiers sont terminees
sync

# On supprime les fichiers temporaires
rm -rf ${CHROOT} ${TMP} ${RAWFS}
