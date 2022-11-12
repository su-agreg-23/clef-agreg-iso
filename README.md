# clef-agreg-iso
Scripts pour la creation d'une iso bootable de clef agreg
Basé sur https://gitlab.com/agreg-info/clef-agreg/

scripts/build_iso_cloud.sh : script pour creer une iso bootable en utilisant cloud-init puis chroot (methode la plus proche de clef-agreg)
scripts/build_iso_chroot.sh : script pour creer une iso bootbale en utilisant uniquement chroot
scripts/chrooted_cloud.sh : script qui sera automatiquement lance dans le chroot pour l'installation par cloud-init
scripts/chrooted_install.sh : script qui sera automatiquement lance dans le chroot pour l'installation par chroot uniquement

splash.png : image pour grub 

Tout marche pour la version cloud (a priori il ne manque que les docsets pour zeal)
Pour la version chroot only, il y a toujours un probleme pour l'installation d'opam en plus.
