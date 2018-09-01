https://wiki.gentoo.org/wiki/Gentoo_Cheat_Sheet
https://www.gentoo.org/support/use-flags/

## Actualización completa
emerge --update --deep --with-bdeps=y --newuse @world
emerge -avDuN world

## Actualizar un solo paquete
emerge -avDuN <package-name>

## Actualiza todos los paquetes y depedencias. También reconstruye USE
## si ha sido modificadas en algún paquete
emerge -uDU --keep-going --with-bdeps=y @world

## Actualización básica sin comprobar dependencias
emerge -avu <package-name>

## Ver dependencias de un paquete y como se resolverá
emerge --pretend -v <package-name>

## Instalar lightdm
sudo emerge --ask x11-misc/lightdm
sudo rc-update add dbus default
sudo rc-update add xdm default

## Cargar lightdm al iniciar
sudo nano /etc/conf.d/xdm
#DISPLAYMANAGER="lightdm"




###########################################
##             AUTOMATIZANDO             ##
###########################################

WORKSCRIPT=$PWD  ## Directorio principal del script
USER=$(whoami)   ## Usuario que ejecuta el script
VERSION='0.0.1'  ## Primera versión del script
LOGERROR='/tmp/chrooterrores.log'  ## Archivo donde almacenar errores
SYSTEMD=true
HOSTNAME='localhost'  ## Nombre del EQUIPO
DOMAIN='local'  ## Nombre del dominio
USUARIO='usuario'  ## Nombre del usuario a crear

BOOT='/dev/sdXX'  ## Partición BOOT de 1GB
RAIZ='/dev/sdXX'  ## Partición Raíz de más de 10GB
SWAP='/dev/sdXX'  ## Partición SWAP
JAULA='/mnt/gentoo'

## Nombre de la partición RAIZ cifrada
LUKSNAME='LUKSGENTOO'

## Nombre del stage
STAGE3='stage3-amd64-20180828T214505Z.tar.xz'
RUTASTAGE3="http://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64/$STAGE3"

STAGE3SYSTEMD='stage3-amd64-systemd-20180827.tar.bz2'
RUTASTAGE3SYSTEMD="http://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-systemd/$STAGE3SYSTEMD"

formatear() {
    mkfs.ext4 $BOOT
    mkfs.ext4 $RAIZ
    mkswap $SWAP
}

cifrarDiscos() {
    cryptsetup luksFormat $RAIZ
}

##
## Construye la jaula con los datos dados
##
montarJaula() {
    if [[ $BOOT != '' ]] && [[ ! -d $JAULA ]]; then
        mkdir -p $JAULA/boot
        sudo umount $BOOT
    fi

    sudo umount /dev/mapper/$LUKS
    sudo umount $RAIZ

    ## Abre Cifrado
    sudo cryptsetup open --type luks $RAIZ $LUKSNAME

    ## Montar estructura de la jaula
    sudo mount /dev/mapper/${LUKSNAME} $JAULA
    if [[ $BOOT != '' ]]; then
        sudo mount $BOOT ${JAULA}/boot
    fi

    swapon /dev/mapper/swap
}

##
## Descomprime el archivo xz recibido en la jaula
## $1 archivo comprimido
##
descomprimirXZ() {
    echo 'Descomprimiendo Stage3 en la jaula'
     tar -Jcvf $1 $JAULA
}

##
## Descomprime el archivo bz2 recibido en la jaula
## $1 archivo comprimido
##
descomprimirBZ2() {
    echo 'Descomprimiendo Stage3 en la jaula'
    tar -xvjpf $1 $JAULA
}

##
## Descargar y descomprimir el STAGE
##
instalarStage3() {
    if [[ $SYSTEMD = 'true' ]]; then
        echo 'Instalando con soporte para systemd'
        descargarStage /tmp/$STAGE3SYSTEMD
        descomprimirBZ2 /tmp/$STAGE3SYSTEMD
    else
        echo 'Instalando sin soporte para systemd'
        descargarStage /tmp/$STAGE3
        descomprimirXZ /tmp/$STAGE3
    fi
}

##
## Enjaular en la ruta indicada
##
enjaular() {
    if [[ $JAULA = '' ]]; then
        exit 1
    fi

    ## Según la guía
    # mount -t proc none ${JAULA}/proc
    # mount --rbind /sys ${JAULA}/sys
    # mount --rbind /dev ${JAULA}/dev

    ## Mio en Debian
    sudo mount -t proc   proc  ${JAULA}/proc/
    sudo mount -t sysfs  sys   ${JAULA}/sys/
    sudo mount -o bind   /dev/ ${JAULA}/dev
    sudo mount -t devpts pts   ${JAULA}/dev/pts

    sudo chroot $JAULA /bin/bash
    #export PS1="Enjaulado → (chroot) $PS1"
}

##
## Desmonta la jaula
##
desmontar() {
    sudo umount ${JAULA}/proc/
    sudo umount ${JAULA}/sys/
    sudo umount ${JAULA}/dev/pts
    sudo umount ${JAULA}/dev
    sudo umount ${JAULA}/boot
    sudo umount ${JAULA}
}

formatear
cifrarDiscos
montarJaula
instalarStage3


## COPIAR: make.conf portage.use/ portage.mask/
cp -L /etc/resolv.conf /mnt/gentoo/etc/resolv.conf




enjaular
desmontar

exit 0






#################################################3
## DENTRO DEL CHROOT
source /etc/profile
xport PS1="(chroot) $PS1"

if [[ ! -d /usr/portage ]]; then
    mkdir /usr/portage
fi

emerge-webrsync
eselect profile list

read -p "Introduce el profile elegido" inputprofile
eselect profile set $inputprofile
cp /usr/share/zoneinfo/Europe/Madrid /etc/localtime
echo "Europe/Madrid" > /etc/timezone

emerge gentoo-sources
emerge genkernel
genkernel all

## Editando FSTAB
#nano -w /etc/fstab

echo "$HOSTNAME" > /etc/conf.d/hostname

# nano -w /etc/conf.d/net
#dns_domain_lo="$DOMAIN"  ## insertar con sed

## Interfaz de red levantandose sola
# nano -w /etc/conf.d/net
#config_enp0s3=( “dhcp” )
# cd /etc/init.d/
# ln -s net.lo net.enp0s3
# rc-update add net.enp0s3 default

## Passwd de root
echo 'Introduce la contraseña para root'
passwd

# nano -w /etc/conf.d/keymaps
#Agregamos las siguientes líneas si nuestro teclado es en español: > KEYMAP=“es” > SET_WINDOWKEYS=“yes”

## Reloj
# nano -w /etc/conf.d/hwclock
# clock="UTC"
# clock_systohc="YES"

## Localizaciones
echo 'es_ES.UTF-8 UTF-8' > /etc/locale.gen
echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
locale-gen

## Locale Variables globales
echo 'LANG="es_ES.UTF-8"' > /etc/env.d/02locale
echo 'LANGUAGE="es_ES.UTF-8"' >> /etc/env.d/02locale
echo 'LC_COLLATE="C"' >> /etc/env.d/02locale
env-update && source /etc/profile


emerge syslog-ng
rc-update add syslog-ng default

emerge vixie-cron
rc-update add vixie-cron default

emerge mlocate
emerge net-misc/dhcpcd

## Instalando grub
emerge grub
kernek=$(ls /boot/kernel*)
initramfs=$(/boot/initramfs*)
# nano -w /boot/grub/grub.conf
#default 0
#timeout 30
#title Mi primer gentoo
#root (hd0,0)
#kernel /boot/kernel-genkernel-x86_64-3.7.10-gentoo-r1 real_root=/dev/sda3
#initrd /boot/initramfs-genkernel-x86_64-3.7.10-gentoo-r1


## Instalar GRUB en el disco duro
# grep -v rootfs /proc/mounts > /etc/mtab
# grub-install --no-floppy /dev/sda



emerge app-admin/sudo
useradd -m -G users,wheel,audio,cdrom,usb,video -s /bin/bash $USUARIO
passwd $USUARIO


