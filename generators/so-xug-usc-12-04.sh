#!/bin/bash
#
# so-xug-12-04.sh
# Copyright (C) 2012	CIXUG - Oficina de Software Libre <osl@cixug.es>
# 						OpenHost - Fran Dieguez <fran@openhost.es>
# so-xug-14-04.sh
# Copyright (C) 2014	CIXUG - Oficina de Software Libre <osl@cixug.es>
# 						Rafael R. Gaioso <rafael@gaioso.es>
#
# Distribuido baixo os termos da licenza MIT.
#
mess(){
  printf "\033[1;36m $@ \033[0m\n"
}

# Paramos os demonios que non precisamos
mess "Parando os <<daemons>>... "
service cups stop
service anacron stop
service hal stop
service acpid stop

# ACTIVACION REPOS ---------------------------------------------------------------

mess "Activando repositorios adicionais ..."
#wget http://packages.cixug.es/so.xug/lists/precise.list \
#      --output-document=/etc/apt/sources.list.d/ubuntu-cixug.list

echo "deb http://packages.cixug.es/ubuntu/ precise main" > /etc/apt/sources.list.d/soxug.list

#add-apt-repository ppa:tiheum/equinox
#add-apt-repository ppa:webupd8team/java

cat > /etc/apt/sources.list << EOF
deb http://archive.ubuntu.com/ubuntu/ precise main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ precise-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ precise-updates main restricted universe multiverse
deb http://archive.canonical.com/ubuntu precise partner
deb http://extras.ubuntu.com/ubuntu precise main
deb-src http://extras.ubuntu.com/ubuntu precise main
EOF

echo "deb http://ftp.cixug.es/CRAN/bin/linux/ubuntu precise/" > /etc/apt/sources.list.d/r-cran.list 

# INSTALACION CIXUG BASE ----------------------------------------------------------

# Instalamos chaves de seguranza de cifraxe de pacotes
mess "Instalando as chaves de seguranza de APT ..."
wget -q -O- http://packages.cixug.es/so.xug/lists/xug-keyring.gpg | apt-key add -
wget -q -O- http://ftp.cixug.es/pub/rcmdr/cran.gpg | apt-key add -
apt-get update
apt-get upgrade -y
#apt-get install xug-keyring -y --force-yes

#Instalamos SO.XUG
mess "Instalando o escritorio de so.xug (pode levar algun tempo) ...\n"
apt-get install xug-desktop ubiquity-slideshow-os-xug xug-redeusc -y

# Desinstalamos UbuntuOne e o menu global das xanelas propio de Unity

apt-get purge landscape-client-ui-install ubuntuone-client ubuntuone-installer -y
apt-get remove indicator-appmenu -y

# Configuración do proxy
cp /tmp/environment /etc
cp /tmp/95proxies /etc/apt/apt.conf.d

# Configuración da páxina de inicio de Firefox a nivel do sistema
# e da orde das linguaxes nas que amosar as páxinas
echo "user_pref(\"browser.startup.homepage\", \"http://www.usc.es\");" >> /etc/firefox/syspref.js
echo "user_pref(\"intl.accept_languages\", \"gl-gl,gl,es-es,en-us,en\");" >> /etc/firefox/syspref.js

# Configuración da xanela de inicio de sesión para ocultar usuarios
cat >> /etc/lightdm/lightdm.conf << EOF
greeter-hide-users=true
allow-guest=false
EOF

# Ocultar o cambio de usuario no escritorio unity
cat > /usr/share/glib-2.0/schemas/soxug.schemas.override << EOF
[com.canonical.indicator.session]
user-show-menu=false
EOF
glib-compile-schemas /usr/share/glib-2.0/schemas

# MODIFICAMOS ASPECTOS DO CD-VIVO ---------------------------------------------------
mess "Estabelecendo os parametros do CD vivo (usuario, skel, kernel, casper) ...\n"
# ReescrÃ­bese a configuraciÃ³n do CASPER para cambiar o nome do usuario
# e o da maquina
cat > /etc/casper.conf << EOF
# This file should go in /etc/casper.conf
# Supported variables are:
# USERNAME, USERFULLNAME, HOST, BUILD_SYSTEM

export USERNAME="osl"
export USERFULLNAME="Sesion do CD-Vivo"
export HOST="soxug"
export BUILD_SYSTEM="Soxug"
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

exit
