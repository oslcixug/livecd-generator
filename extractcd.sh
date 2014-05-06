#! /bin/bash
#
# extractcd.sh
# Copyright (C) 2008      Mancomun - Óscar García Amor <ogarcia@mancomun.org>
# Copyright (C) 2008-2011 OSL da USC - Francisco Diéguez <francisco.dieguez@usc.es>
# Copyright (C) 2012	  CIXUG - Oficina de Software Libre <osl@cixug.es>
#			  OpenHost - Fran Dieguez <fran@openhost.es>
#
# Distribuído baixo os termos da licenza MIT.
#

# ==================================================================
# Ferrallas para montaxe do CD de LiveCD dende o cd oficial de Ubuntu
# ==================================================================
#
# Este conxunto de scripts permite de forma sinxela extraer o contido do CD
# oficial de Ubuntu e crear un entorno de traballo para facer as
# modificacións necesarias para obter o CD de LiveCD, así como tamén
# reempaquetar o CD unha vez rematada a tarefa de modificación.

# Impórtanse as funcións.
source lib/functions.func &> /dev/null || \
 err "ATENCION: Non se atopa o ficheiro coas funcións\n" \
   "lib/functions.func necesario para a execución de $0"

# Importase a configuración.
source lib/configurations.conf &> /dev/null || \
 err "Non se atopa o ficheiro coa configuración lib/configurations.conf" \
  "necesario para a execución de $0"

# Comprobase se se indica coma parámetro o directorio onde se atopa montado
# o CD ou o nome da imaxe do CD. Se non se indica ou se solicita axuda
# facilítanse instrucións.
case $1 in
  ''|-h|--help )
    echo "Usos: $0 /ruta/ao/cd | imaxe_do_cd.iso"
    echo "$0 permite extraer os contidos do CD de Ubuntu (o doutro"
    echo "CD Vivo baseado en Debian) para a súa posterior modificación."
    echo -e "\nOpcións:\n"
    echo "  -h,--help    Mostra esta axuda."
    echo "  --config     Mostra o estado da configuración."
    echo -e "\nReporta os erros que atopes en <osl@usc.es>."
    exit 0
  ;;
  --config )
    echo -e "Configuración:\n"
    echo "* Punto de montaxe temporal para a ISO:      $MOUNTCD"
    echo "* Punto de extracción dos contidos do CD:    $EXTRACTCD"
    echo "* Punto de montaxe temporal para o squashfs: $SQUASHFS"
    echo "* Cartafol de traballo:                      $WORK"
    echo "* Cartafoles das copias de seguridade:"
    echo "   Contidos do CD:                           $BACKUP/$BAKEXT<DATA>"
    echo "   Cartafol de traballo:                     $BACKUP/$BAKWORK<DATA>"
    echo -e "\nEdita lib/configurations.conf para cambiar estes valores."
    echo -e "\nReporta os erros que atopes en <osl@cixug.es>."
    exit 0
  ;;
esac

# Comprobase se se é root, senón dáse un erro. É necesario ser root para
# traballar coas imaxes dos CD's xa que se deben crear ficheiros especiais
# de dispositivo e montar e desmontar unidades.
[ $UID != 0 ] && \
 err "Necesitas privilexios de root para executar o script"

# Comprobase a configuración.
[ "$MOUNTCD" ] || err "A variábel MOUNTCD non esta definida na configuración"
[ "$EXTRACTCD" ] || err "A variábel EXTRACTCD non esta definida na configuración"
[ "$SQUASHFS" ] || err "A variábel SQUASHFS non esta definida na configuración"
[ "$WORK" ] || err "A variábel WORK non esta definida na configuración"
[ "$BACKUP" ] || err "A variábel BACKUP non esta definida na configuración"
[ "$BAKEXT" ] || err "A variábel BAKEXT non esta definida na configuración"
[ "$BAKWORK" ] || err "A variábel BAKWORK non esta definida na configuración"

# Comprobase se o que se indica como parámetro e un ficheiro para tentar
# montalo.
if [ -f $1 ]; then
  mess "A montar a imaxe do CD . . . \n"
  mkdir -p $MOUNTCD || \
   err "Non foi posíbel crear o cartafol para montar a imaxe do CD"
  mount -o loop $1 $MOUNTCD || \
   err "Non foi posíbel montar a imaxe do CD"
  # Se o montaxe foi correcto se establece coma orixe dos datos
  ORIG=$MOUNTCD
else
  # Se non e unha iso a orixe dos datos e o parámetro de entrada
  ORIG=$1
  # Compróbase que realmente e un directorio onde se montou o CDROM
  [ ! -d $ORIG ] && \
   err "A ruta facilitada non é un directorio ou non se pode ler"
fi

# Se existe previamente o cartafol onde se extraeu o CD faise copia.
if [ -d "$EXTRACTCD" ]; then
  mess "A facer o backup do CD antigo . . . \n"
  TARGET="$BACKUP/$BAKEXT`date +%Y%m%d%H%M%S`"
  mkdir -p "$TARGET" || \
   err "Non foi posíbel crear o cartafol para facer o backup"
  # Para non mover o cartafol en si mesmo senón os seus contidos (incluíndo
  # ficheiros ocultos) facemos o mv nun bucle.
  for item in `ls -A "$EXTRACTCD"`
  do
    mv "$EXTRACTCD/$item" "$TARGET"
  done
fi

# Se existe o cartafol de traballo tamén faise copia.
if [ -d "$WORK" ]; then
  mess "A facer o backup do cartafol de traballo . . . \n"
  TARGET="$BACKUP/$BAKWORK`date +%Y%m%d%H%M%S`"
  mkdir -p "$TARGET" || \
   err "Non foi posíbel crear o cartafol para facer o backup"
  mv "$WORK" "$TARGET"
fi

# Créase o cartafol onde se vai extraer o contido do CD
mkdir -p $EXTRACTCD || \
 err "Non foi posíbel crear o cartafol para extraer a imaxe do CD"

# Cópiase o contido do CD
mess "A copiar o contido do CD . . . \n"
rsync --exclude=/casper/filesystem.squashfs -a $ORIG/ $EXTRACTCD > /dev/null

# Créase un cartafol para montar o squashfs
mkdir -p $SQUASHFS || \
 err "Non foi posíbel crear o cartafol para montar o squashfs"

# Móntase o squashfs
mount -t squashfs -o loop $ORIG/casper/filesystem.squashfs $SQUASHFS || \
 err "Non foi posíbel montar o squashfs"

# Créase o directorio de traballo
mkdir -p $WORK || \
 err "Non foi posíbel crear o cartafol de traballo"
# IMPORTANTISIMO: Establécense os permisos para o cartafol de traballo.
chmod 755 $WORK || \
 err "ERRO FATAL!!! Non e posíbel establecer os permisos do directorio de traballo"

# Cópiase todo o contido do squashfs ao directorio de traballo
mess "A copiar o contido do squashfs (leva algun tempo). . . \n"
cp -av $SQUASHFS/* $WORK &> /dev/null

# Desmontanse e borranse os directorios temporais de squashfs e o da iso se
# se montou
mess "A desmontar e borrar os directorios temporais . . . \n"
umount $SQUASHFS || \
 err "Non foi posíbel desmontar o squashfs, debera facelo a man"
rmdir $SQUASHFS
if [ "$ORIG" = "$MOUNTCD" ]; then
  umount $MOUNTCD || \
   err "Non foi posíbel desmontar a imaxe do CDROM, debera facelo a man"
  rmdir $MOUNTCD
fi

exit 0

