#!/bin/bash
#
# so-xug-12-04.sh
# Copyright (C) 2012	CIXUG - Oficina de Software Libre <osl@cixug.es>
# 						OpenHost - Fran Dieguez <fran@openhost.es>
#
# Distribuido baixo os termos da licenza MIT.
#
CODENAME=`lsb_release -cs`

mess(){
  printf "\033[1;36m $@ \033[0m\n"
}

# Paramos os demonios que non precisamos
mess "Stopping daemons... "
service cups stop
service anacron stop
service hal stop
service acpid stop

# ACTIVACION REPOS ---------------------------------------------------------------

mess "Activating external repositories..."
wget http://packages.cixug.es/so.xug/lists/precise.list \
      --output-document=/etc/apt/sources.list.d/ubuntu-cixug.list

add-apt-repository ppa:tiheum/equinox
add-apt-repository ppa:webupd8team/java

cat > /etc/apt/sources.list << EOF
# /etc/apt/sources.list
deb http://archive.ubuntu.com/ubuntu/ precise main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ precise-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ precise-updates main restricted universe multiverse
deb http://archive.canonical.com/ubuntu precise partner
deb http://extras.ubuntu.com/ubuntu precise main
deb-src http://extras.ubuntu.com/ubuntu precise main
EOF

cat > /etc/apt/sources.list.d/r-cran.list << EOF
deb http://cran.es.r-project.org/bin/linux/ubuntu precise/
EOF

# INSTALACION CIXUG BASE ----------------------------------------------------------

# Instalamos chaves de seguranza de cifraxe de pacotes
mess "Instalando as chaves de seguranza de APT ..."
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9 # r-cran
apt-get update
apt-get install xug-keyring -y --force-yes
apt-get update

#Instalamos SO.XUG
mess "Instalando o escritorio de so.xug (pode levar algun tempo) ...\n"
apt-get install xug-desktop ubiquity-slideshow-os-xug -y
apt-get purge landscape-client-ui-install ubuntuone-client ubuntuone-installer -y

# MODIFICAMOS ASPECTOS DO CD-VIVO ---------------------------------------------------
mess "Estabelecendo os parametros do CD vivo (usuario, skel, kernel, casper) ...\n"
# ReescrÃ­bese a configuraciÃ³n do CASPER para cambiar o nome do usuario
# e o da maquina
cat > /etc/casper.conf << EOF
# This file should go in /etc/casper.conf
# Supported variables are:
# USERNAME, USERFULLNAME, HOST, BUILD_SYSTEM

export USERNAME="ubuntu"
export USERFULLNAME="Sesion do CD-Vivo"
export HOST="ubuntu"
export BUILD_SYSTEM="Ubuntu"
EOF

# LIMPANDO A CASA PARA SAIR ---------------------------------------------------
mess "Limpando o sistema e rematando ..."
apt-get autoclean > /dev/null
apt-get autoremove --purge
apt-get clean > /dev/null
#chown -R root:root /var
#chown -R gdm: /var/lib/gdm
rm -f /root/.bash_history
rm -f /tmp/salida.log
rm -vf /var/cache/apt/*cache.bin
rm -vf /var/lib/apt/lists/*_*
rm -vrf /tmp/*
for i in `find /var/log -type f`; do \
echo "" > $i;
done

exit 0
