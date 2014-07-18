#! /bin/bash
#
# buildcd.sh
# Copyright (C) 2008      Mancomun - Óscar García Amor <ogarcia@mancomun.org>
# Copyright (C) 2008-2011 OSL da USC - Francisco Diéguez <francisco.dieguez@usc.es>
# Copyright (C) 2012	  CIXUG - Oficina de Software Libre <osl@cixug.es>
#			  OpenHost - Fran Dieguez <fran@openhost.es>
#
# Distibuido baixo os termos da licenza MIT.
#

# ==================================================================
# Ferrallas para montaxe do CD de LiveCD dende o CD oficial de Ubuntu
# ==================================================================
#
# Este conxunto de scripts permite de forma sinxela extraer o contido do CD
# oficial de Ubuntu e crear un entorno de traballo para facer as
# modificacións necesarias para obter o CD de LiveCD, así como tamen
# reempaquetar o CD unha vez rematada a tarefa de modificación.

# buildcd.sh empaqueta o contido do cartafol de traballo WORK definido no
# ficheiro lib/configurations.conf nunha imaxe squashfs no cartafol cos
# contidos do CD, e o contido de este ultimo nunha imaxe ISO de CD.

# Comprobase se se é root, senon dase un erro. É necesario ser root para
# facer o chroot.


# Importanse as funcions.
source ./lib/functions.func &> /dev/null || \
 err "ATENCION: Non se atopa o ficheiro coas funcións\n" \
   "lib/functions.func necesario para a execución de $0\n"

[ $UID != 0 ] && \
 err "Necesitas privilexios de root para executar o script"

# Importase a configuración
source ./lib/configurations.conf &> /dev/null || \
 err "Non se atopa o ficheiro coa configuración " \
  "lib/configurations.conf necesario para a execución de $0"

# Comprobase que se lle pasou a ruta de chroot
if [ $# -lt 1 ]; then
  err "Especifique unha ruta ao chroot: buildcd.sh $WORK"
fi

# Coprobase se se pasou algun parametro ou se se solicitou axuda.
case $1 in
  -h|--help )
    echo "Uso: $0"
    echo "$0 empaqueta os contidos do directorio de traballo nunha imaxe"
    echo "ISO de CD."
    echo -e "\nOpcións:\n"
    echo "  -h,--help    Mostra esta axuda."
    echo "  --config     Mostra o estado da configuración."
    echo -e "\nReporta os erros que atopes en <osl@cixug.es>."
    exit 0;
  ;;
  --config )
    echo -e "Configuración:\n"
    echo "* Cartafol co contido do CD:               $EXTRACTCD"
    echo "* Cartafol de Traballo:                    $WORK"
    echo "* Nome do Kernel:                          $KERNEL"
    echo "* Nome do initrd:                          $INITRD"
    echo "* Ficheiro ISO:                            $ISO"
    echo "* Nome do volume ISO:                      $NOMECD"
    echo "* Cartafois das copias de seguridade:"
    echo "   Contidos do CD:                         $BACKUP/$BAKEXT<DATA>"
    echo "   Ficheiro ISO:                           $BACKUP/$BAKISO<DATA>"
    echo -e "\nEdita lib/configurations.conf para cambiar estes valores."
    echo -e "\nReporta os erros que atopes en <osl@cixug.es>."
    exit 0;
  ;;
esac

# Comprobase que se teñen os pacotes necesarios para traballar
if [ `dpkg --get-selections|grep squashfs-tools|wc -l` -lt 1 ]; then
  err "Non ten instalado o paquente squashfs-tools, necesario no proceso\n"
fi

# Comprobase a configuración.
[ "$EXTRACTCD" ] || err "A variábel EXTRACTCD non esta definida na configuración"
[ "$WORK" ] || err "A variábel WORK non esta definida na configuración"
[ "$KERNEL" ] || err "A variábel KERNEL non esta definida na configuración"
[ "$INITRD" ] || err "A variábel INITRD non esta definida na configuración"
[ "$ISO" ] || err "A variábel ISO non esta definida na configuración"
[ "$NOMECD" ] || err "A variábel NOMECD non esta definida na configuración"
[ "$BACKUP" ] || err "A variábel BACKUP non esta definida na configuración"
[ "$BAKEXT" ] || err "A variábel BAKEXT non esta definida na configuración"
[ "$BAKISO" ] || err "A variábel BAKISO non esta definida na configuración"

# Comprobase se existe o directorio de traballo e o directorio cos contidos do CD
[ -d "$WORK" ] || err "O directorio de traballo $WORK non existe ou non se pode ler"
[ -d "$EXTRACTCD" ] || err "O directorio cos contidos base do CD $EXTRACTCD non existe ou non se pode ler"

# Comprobase se existen os ficheiros do kernel e do initrd
#[ -f "$WORK/boot/$KERNEL" ] || \
# err "O ficheiro do kernel $KERNEL"\
#"non existe ou non se pode ler, poida ser que"\
#"actualizara o kernel e eliminara o orixinal,"\
#"modifique a variable KERNEL en lib/configurations.conf"\
#"nese caso"
# O ficheiro de initrd pode ser que non exista, polo que so se avisa
[ -f "$WORK/boot/$INITRD" ] || \
 warn "O ficheiro do inird $INITRD non existe ou non se pode ler" \
 "E posíbel que o initrd non fora xerado na última modificación" \
 "ou que actualizara o kernel, modifique a variable INITRD en" \
 "configurations.conf nese caso"

# Faise copia do CD extraido antigo
mess "A facer o backup do CD antigo . . . \n"
TARGET="$BACKUP/$BAKEXT`date +%Y%m%d%H%M%S`"
mkdir -p "$TARGET" || \
 err "Non foi posíbel crear o cartafol para facer o backup"
# Non se moven os contidos senon que se copian con rsync xa que moitos deles
# nos van facer falla na nova compilación.
rsync --exclude=/casper/filesystem.squashfs -a $EXTRACTCD/ $TARGET || \
 err "Fallou a creación da copia de seguridade do CD"
# Se existe un squashfs movese directamente (non se copia xa que se vai
# sobrescribir e non necesitamos o contido antigo).
if [ -e "$EXTRACTCD/casper/filesystem.squashfs" ]; then
  mv "$EXTRACTCD/casper/filesystem.squashfs" "$TARGET/casper"
fi

# Personalizando o arrinque da vivo, apariencia e idioma.
mess "A modificar visualmente o arrinque de SO.XUG no livecd...\n"
#sudo cp images/splash.p* $EXTRACTCD/isolinux
sudo sed -i 's/B6875A/5071B3/' $EXTRACTCD/isolinux/gfxboot.cfg

mess "Establecendo o idioma galego por defecto no arrinque da livecd...\n"
echo "gl" > $EXTRACTCD/isolinux/lang

# Comprobase se exinte unha ISO antiga para facer o backup
if [ -e "$EXTRACTCD/../$ISO" ]; then
  mess "A facer o backup da imaxe ISO antiga . . . \n"
  TARGET="$BACKUP/$BAKISO`date +%Y%m%d%H%M%S`"
  mkdir -p "$TARGET" || \
   err "Non foi posíbel crear o cartafol para facer o backup"
  mv "$EXTRACTCD/../$ISO" "$TARGET"
fi

# Actualizanse os manifest do CD
mess "A actualizar os manifests do CD . . . \n"
chroot $WORK dpkg-query -W --showformat='${Package} ${Version}\n' > $EXTRACTCD/casper/filesystem.manifest || \
 err "Non foi posíbel crear o manifest"
{ cp -v $EXTRACTCD/casper/filesystem.manifest $EXTRACTCD/casper/filesystem.manifest-desktop  &> /dev/null && \
  sed -i '/ubiquity/d' $EXTRACTCD/casper/filesystem.manifest-desktop; } || \
   err "Non foi posíbel crear o manifest.desktop"

# Copiase o kernel e movese o initrd do sistema
mess "A facer a copia do kernel e mover o initrd (se existe) . . . \n"
cp -v $WORK/boot/$KERNEL $EXTRACTCD/casper/vmlinuz &> /dev/null|| \
  warn "Non foi posíbel copiar o kernel ao CD"
if [ -e "$WORK/boot/$INITRD" ]; then
  mv -v $WORK/boot/$INITRD $EXTRACTCD/casper/initrd.gz  &> /dev/null || \
  warn "Non foi posíbel mover o initrd ao CD"
fi

# Crease o novo filesystem
mess "A crear o squashfs . . . \n"
mksquashfs $WORK $EXTRACTCD/casper/filesystem.squashfs || \
 err "Fallou a creación do squashfs"

# Actualizanse as sumas md5 e limpiase o ficheiro
mess "Actualizando a sumas md5 . . . \n"
{ cd $EXTRACTCD && find . -type f -print0 | xargs -0 md5sum > md5sum.txt && \
  sed -i '/md5sum.txt/d' md5sum.txt && sed -i '/boot.cat/d' md5sum.txt && \
  cd $OLDPWD; } || \
   err "Non foi posíbel actualizar as sumas MD5"

# Crease a imaxe de CD
mess "A crear a nova ISO . . . \n"
{ cd $EXTRACTCD && mkisofs -r -V "$NOMECD" -cache-inodes -J -l -b \
   isolinux/isolinux.bin -c isolinux/boot.cat \
   -no-emul-boot -boot-load-size 4 -boot-info-table -o \
   ../../final-isos/$ISO .  &> /dev/null && cd $OLDPWD; } || \
    err "Non foi posíbel crear a imaxe do CD"
chmod 644 final-isos/$ISO
mess "A nova imaxe ISO co CD de «$NOMECD» creouse con éxito no cartafol \"final-isos\".\n"
