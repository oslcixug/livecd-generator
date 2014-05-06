#! /bin/bash
#
# chroot.sh
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

# chroot.sh crea un entorno de chroot e entra nel para poder modificar os
# contidos do CD Vivo oficial e adaptalo as nosas necesidades. E posíbel
# especificar unha rota onde facer chroot mediante un parámetro, se non se
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

# Revísanse os parámetros de entrada para saber se se solicita axuda
case $1 in
  -h|--help )
    echo "Uso: $0 [ /rota/ao/cartafol/de/chroot ]"
    echo "$0 automatiza o proceso de facer chroot no cartafol de traballo"
    echo "para a modificación do sistema da imaxe squashfs"
    echo -e "\nOpcións:\n"
    echo "  -h,--help    Mostra esta axuda."
    echo -e "\nSe non se especifica unha rota tómase a rota por defecto $WORK"
    echo "definida no ficheiro de configuración lib/configurations.conf."
    echo -e "\nReporta os erros que atopes en <osl@cixug.es>."
    exit 0
  ;;
  # En calquera outro caso tomamos a entrada como unha rota
  * )
    # Este script permite especificar en que cartafol se quere facer chroot.
    # senón se especifica unha ruta tómase o cartafol por defecto da
    # configuración.
    [ "$WORK" ] || err "A variábel de configuración WORK non esta definida"
    [ ! $1 ] && set $1 "$WORK"
  ;;
esac

# Comprobase se existe e é un directorio o lugar onde se quere facer chroot
[ -d "$1" ] || err "Non e posíbel facer chroot no directorio $1 xa que non existe ou non se pode ler"

# Copiase o resolv para ter conexión dentro do chroot
mess "Copiando o resolv.conf\n"
cp -vL /etc/resolv.conf $1/etc/ &> /dev/null || \
 warn "Non foi posíbel copiar o resolv.conf ao directorio de traballo," \
      "e posíbel que non haia conexión no entorno chroot"

# Montase o necesario para facer chroot
mess "\nFacendo os montaxes fora do chroot . . . \n"
mount -v -o bind /dev $1/dev &> /dev/null || \
 err "Non foi posíbel facer o bind do directorio /dev"

mount -v -o bind /var/run $1/var/run &> /dev/null  || \
 err "Non foi posíbel facer o bind do directorio /var/run"

# Créanse uns ficheiros temporais cos comandos que se deben executar ao facer
# o chroot e ao sair
touch $1/tmp/login.sh || \
 err "Non e posíbel crear o script de entrada para o chroot"

cat > $1/tmp/login.sh << EOF
echo "Configurando entorno chroot..."
source /etc/bash.bashrc
export HOME=/root
export LC_ALL=C
source /etc/profile
alias ls='ls --color=auto'
PS1="[chr] \[\e[31;01m\]\h \[\e[34;01m\]\W # \[\e[0m\]"
mount -v -t proc none /proc &> /dev/null
mount -v -t sysfs none /sys &> /dev/null
mount -v -t devpts none /dev/pts &> /dev/null
echo "Pra proceder coa personalización da súa distro execute \"/tmp/so-xug-12-04.sh\""
EOF
cp generators/*.sh $1/tmp &> /dev/null
chmod a+x $1/tmp/*.sh &> /dev/null

# Faise o chroot utilizando o ficheiro temporal coma rc
mess "Entrando no entorno chroot\n"
mess "*************************************************************************\n"
chroot $1 /bin/bash --rcfile /tmp/login.sh
# Neste intre o script detense ata que se sae do chroot

# Ao saír do chroot desmontase todo, se non se pode desmontar algo dáse un
# aviso para tentar desmontalo a man
mess "\nDesmontando . . . \n"
# Coma /proc /sys e /dev/pts montáronse dentro do chroot deben desmontarse
# dentro do mesmo
chroot $1 umount -lv /proc || \
 warn "Non foi posíbel desmontar /proc no entorno chroot"
chroot $1 umount -lv /sys || \
 warn "Non foi posíbel desmontar /sys no entorno chroot"
chroot $1 umount -lv /dev/pts || \
 warn "Non foi posíbel desmontar /dev/pts no entorno chroot"
# /dev e /var/run montáronse fora do chroot polo que se desmontan
# normalmente
umount -lv $1/dev || \
 warn "Non foi posíbel desmontar $1/dev"
umount -lv $1/var/run || \
 warn "Non foi posíbel desmontar $1/var/run"

# Borrase o resolv e o script temporal
rm -vf $1/etc/resolv.conf &> /dev/null
rm -vf $1/tmp/*.sh &> /dev/null
