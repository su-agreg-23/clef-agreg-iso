# Pronaos

https://agreg-info.gitlab.io/docs/

Pronaos est un environnement de concours pour permettre aux candidats de l'agrégation d'informatique de préparer leurs épreuves orales.

La version 2022 est disponible au format OVA pour VirtualBox [ici](https://gitlab.com/agreg-info/clef-agreg/-/releases). L'image est basée sur Ubuntu avec un ensemble spécifique de paquets qui seront mis à disposition des candidats lors des épreuves.

Le compte `candidat` a pour mot de passe `concours`.

## Création de la VM

[`cloud-config.yaml`](cloud-config.yaml) contient notamment les packages à installer et les scripts de génération de l'image suivant le standard [cloud-init](https://cloudinit.readthedocs.io/en/latest/index.html).

[`requirements.txt`](requirements.txt) contient les packages Python à installer.

Le processus de création de VM prend environ 2 heures. La machine virtuelle sera disponible sur agreg-info.org.

Si toutefois vous souhaitez l'installer vous-mêmes, suivez les instructions du test d'intégration continue :

- [`.gitlab-ci.yml`](.gitlab-ci.yml) lance les scripts ci-dessous et, en cas de succès, uploade la machine virtuelle sur un serveur
- [`scripts/build.sh`](scripts/build.sh) crée l'image `.img` et la machine virtuelle `.vdi`
- [`scripts/install.sh`](scripts/install.sh) finalise l'installation et la configuration des derniers paquets, une fois ce repo cloné (celui dont vous êtes en train de lire le README).

## Création de l'ISO Bootable

Le processus de création de l'ISO prend un peu plus de temps que celui de la VM, compter 1h de plus environ. Le code est documenté en français.

- [`scripts/build_iso_cloud.sh`](scripts/build_iso_cloud.sh) crée l'image ISO en utilisant le cloud-config.yaml du répertoire principal et un chroot pour la création de l'image ISO.
- [`scripts/chrooted_cloud.sh`](scripts/chrooted_cloud.sh) script lancé par le script principal dans le chroot pour installer les paquets nécessaires pour la création de l'ISO et le paquet linux-modules-extra afin de gérer les cartes graphiques et mousepads notamment.
- [`splash.png`](splash.png) l'image pour le menu GRUB2 de l'ISO bootable

Les scripts suivants sont encore en développement:
- [`scripts/build_iso_chroot.sh`](scripts/build_iso_chroot.sh) crée l'image iso en utilisant uniquement le chroot, sans utiliser cloud-init (prend moins de place mais pour le moment la génération du répertoire opam de `candidat` pose problème, et la creation de la base de donnees MariaDB semble impossible en chroot)
- [`scripts/chrooted_install.sh`](scripts/chrooted_install.sh) script lancé par le script principal dans le chroot pour installer tous les paquets.

Il manque encore quelques docsets de zeal à ajouter (si quelqu'un connaît la liste de ceux disponnibles le jour de l'agrégation je suis preneur)

## Différences avec l'environnement de concours

Le compte `candidat` n'existera pas pendant les oraux, chaque candidat aura un compte spécifique.

Le compte `candidat` est administrateur de la VM, ce qui ne sera pas le cas pendant les oraux.

La VM a un accès réseau non restreint (en particulier, a accès à internet). Pendant le concours, les machines n'auront qu'un accès à un intranet local.
