#!/bin/bash

# Commandes pour installer et configurer les paquets necessaires dans la VM pour l'ISO
# Version sans utiliser cloud-init : reprends toutes les installs de cloud-config.yaml

# Afin d'etre sur d'avoir les executables dans le chroot
export PATH=/usr/sbin:/sbin:$PATH

# Pour eviter les problemes de locale
LANG=

# On ajoute l'utilisateur candidat, avec les pouvoirs admin (sudo) et le mot de passe "concours".
useradd -u 1000 -m -G sudo -s /bin/bash -c "Candidat Agreg" -p $(echo "concours" | openssl passwd -1 -stdin) candidat

# On commence par mettre a jour ce qui est installe
apt update -y
apt upgrade -y

# On ajoute la cle puis le repository pour VSCodium
wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
    | gpg --dearmor \
    | dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' \
    | tee /etc/apt/sources.list.d/vscodium.list

# On remet a jour avec le nouveau repository
apt update -y

# Il y a plusieurs commandes apt-get afin que ce soit plus lisible, les paquets sont regroupes par genre
# La liste vient du cloud-config.yaml du git clef-agreg.

## Window Managers
apt-get install -q=2 \
	gnome \
	lxde

## Terminaux
apt-get install -q=2 \
	gnome-terminal

## Utilitaires console
apt-get install -q=2 \
	bash-completion \
	htop \
	wget \
	
## Navigateurs
apt-get install -q=2 \
	firefox \
	chromium-browser

## Libraries
apt-get install -q=2 \
	zlib1g-dev \
	libffi-dev \
	libgmp-dev \
	libzmq5-dev

## Serveurs web et BDD
apt-get install -q=2 \
	apache2 \
	mariadb-server \
	sqlite3 \
	phpmyadmin

## Pour coder
# Langages
apt-get install -q=2 \
	ocaml \
	gcc-10 \
	gfortran \
	gprolog \
	openjdk-11-jdk \
	python-is-python3 \
	python-dev-is-python3 \
	r-base \
	nodejs

# Environnements de compilation et utilitaires
apt-get install -q=2 \
	opam \
	menhir \
	ml-yacc \
	build-essential \
	python3-pip \
	flex \
	ragel

# Debuggers
apt-get install -q=2 \
	gdb \
	valgrind

# gestionnaires de version
apt-get install -q=2 \
	git \
	subversion

# Editeurs et IDE
apt-get install -q=2 \
	emacs \
	vim \
	jupyter \
	pyzo \
	codium 

## Utilitaires pour la gestion d'images/graphes
apt-get install -q=2 \
	gimp \
	inkscape \
	qgis \
	graphviz \
	gnuplot

## Bureautique
apt-get intall -q=2 \
	texlive-latex-base \
	texmaker \
	libreoffice \
	evince

## Documentation
apt-get install -q=2 \
	zeal \
	pandoc \
	manpages \
	manpages-dev \
	glibc-doc \
	man-db

## Localisation fr
apt-get install -q=2 \
	language-pack-fr \
	texlive-lang-french \
	libreoffice-l10n-fr \
	manpages-fr \
	manpages-fr-dev
	
## Inutile hors vm (maximise disques vituels ext2/3/4 en remplissant de 0)
apt-get install -q=2 \
	zerofree

## Ajouts pour l'iso (utilitaires pour le live et utilitaire de boot)
apt-get install -q=2 \
	grub-efi-amd64-signed \
	casper \
	lupin-casper \
	xorriso \
	mtools

## Maintenant on passe aux scripts contenus dans runcmds de cloud-config.yaml et script/install.sh de clef-agreg
rm /var/lib/dpkg/info/ca-certificates-java.postinst && apt install -f
cd ~/
git clone https://gitlab.com/agreg-info/clef-agreg.git

# Modifier la derniere ligne pour eviter les messages d'erreur lors du boot
cat clef-agreg/scripts/install.sh | sed -e "s/rm -rf \/var\/lib/\#rm -rf \/var\/lib/g" > clef-agreg/scripts/install_chroot.sh
cd clef-agreg && bash ./scripts/install_chroot.sh
cd ~/

# Generer l'initramfs
UNAMER=`ls /boot/config*`
depmod -a ${UNAMER/\/boot\/config-/}
update-initramfs -u -k ${UNAMER/\/boot\/config-/}

# Tout nettoyer
apt-get autoremove -y
apt-get clean -y
apt remove -y unattended-upgrades
rm -rf ~/clef-agreg
find /var/log -regex '.*?[0-9].*?' -exec rm -v {} \;
find /var/log -type f | while read file
do
        cat /dev/null | tee $file
done
exit
