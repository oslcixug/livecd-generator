#! /bin/bash
#
# chroot.sh
# Copyright (C) 2014	  CIXUG - Oficina de Software Libre <osl@cixug.es>
#			  Rafael R. Gaioso <rafael@gaioso.es>
#
# Distribuído baixo os termos da licenza GPLv3.
#

# ==================================================================
# Script para eliminar as copias de seguranza existentes
# ==================================================================
#
# especifícase nada se collería a rota do ficheiro de configuración.

# Impórtanse as funcións.
source lib/functions.func &> /dev/null || \
 { echo -e "ATENCION: Non se atopa o ficheiro coas funcións" \
   "lib/functions.func necesario para a execución de $0" && exit 1; }

# Comprobase se se é root, senón ocorre un erro. É necesario ser root para
# facer o chroot.
[ $UID != 0 ] && \
 err "Necesitas privilexios de root para executar o script"

# Importase a configuración
source lib/configurations.conf &> /dev/null || \
 err "Non se atopa o ficheiro coa configuración configuration.conf" \
  "necesario para a execución de $0"

# Faise o chroot utilizando o ficheiro temporal coma rc
mess "Comezamos co proceso de borrados das copias\n"
mess "*************************************************************************\n"

mess "Estás seguro de querer eliminar as copias de seguranza? (S/n) "
read -p "" -i "S" escolla
escolla=${escolla:-S}

if [[ $escolla = "S" ]]
then 
	rm -rf $BACKUP/*
	mess "\nProceso rematado!\n"
else

	mess "\nNon se fixeron cambios nas copias\n"
fi

