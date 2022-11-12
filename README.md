# clef-agreg-iso
Scripts pour la creation d'une iso bootable de clef agreg
Basé sur https://gitlab.com/agreg-info/clef-agreg/

scripts/build_iso_cloud.sh : script pour creer une iso bootable en utilisant cloud-init puis chroot (methode la plus proche de clef-agreg)
scripts/build_iso_chroot.sh : script pour creer une iso bootbale en utilisant uniquement chroot
scripts/chrooted_cloud.sh : script qui sera automatiquement lance dans le chroot pour l'installation par cloud-init
scripts/chrooted_install.sh : script qui sera automatiquement lance dans le chroot pour l'installation par chroot uniquement

splash.png : image pour grub 

En l'etat actuel: on est bloque en 800x600 et le mousepad ne marche pas, ceci est du au fait que les drivers ne s'installent pas correctement ni en VM ni en chroot ...
(pour le chroot : probleme packagekit, pour la vm je ne sais pas trop)
