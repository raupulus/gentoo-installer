#################################################
##             DENTRO DEL CHROOT               ##
#################################################

## Importo variables de configuración
source "conf"

## Importo funciones auxiliares
source "functions.sh"

startChroot() {
    echo 'Preparando entorno chroot'
    source /etc/profile
    export PS1="(chroot) $PS1"

    if [[ ! -d '/usr/portage' ]]; then
        mkdir /usr/portage
    fi
}

confRepos() {
    emerge-webrsync
}

portageProfile() {
    eselect profile list
    read -p "Introduce el profile elegido" inputprofile
    eselect profile set $inputprofile
    cp "/usr/share/zoneinfo/$ZONE" /etc/localtime
    echo "$ZONE" > /etc/timezone
}

installKernel() {
    emerge gentoo-sources
    emerge genkernel
    genkernel all
}

createFstab() {
    ## Editando FSTAB
    #nano -w /etc/fstab
}

configRed() {
    echo "$HOSTNAME" > /etc/conf.d/hostname

    # nano -w /etc/conf.d/net
    #dns_domain_lo="$DOMAIN"  ## insertar con sed

    ## Interfaz de red levantandose sola
    # nano -w /etc/conf.d/net
    #config_enp0s3=( “dhcp” )
    # cd /etc/init.d/
    # ln -s net.lo net.enp0s3
    # rc-update add net.enp0s3 default
}

configLocales() {
    # nano -w /etc/conf.d/keymaps
    #Agregamos las siguientes líneas si nuestro teclado es en español: > KEYMAP="$KEYMAP" > SET_WINDOWKEYS="yes"

    ## Reloj
    # nano -w /etc/conf.d/hwclock
    # clock="UTC"
    # clock_systohc="YES"

    ## Localizaciones
    echo "$LOCALIZATION UTF-8" > /etc/locale.gen
    echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
    locale-gen

    ## Locale Variables globales
    echo "LANG=$LOCALIZATION" > /etc/env.d/02locale
    echo "LANGUAGE=$LOCALIZATION" >> /etc/env.d/02locale
    echo 'LC_COLLATE="C"' >> /etc/env.d/02locale
    env-update && source /etc/profile
}

configRoot() {
    ## Passwd de root
    echo 'Introduce la contraseña para root'
    passwd
}

configUser() {
    emerge app-admin/sudo
    useradd -m -G users,wheel,audio,cdrom,usb,video -s /bin/bash $USUARIO
    passwd $USUARIO
}

installGrub() {
    ## Instalando grub
    emerge grub
    kernel=$(ls /boot/kernel* | head -1)
    initramfs=$(/boot/initramfs* | head -1)
    echo 'default 0' > '/boot/grub/grub.conf'
    echo 'timeout 30' >> '/boot/grub/grub.conf'
    echo 'title Gentoo' >> '/boot/grub/grub.conf'
    echo "root $HDROOT" >> '/boot/grub/grub.conf'
    echo "kernel $kernel real_root=$RAIZ" >> '/boot/grub/grub.conf'
    echo "initrd $initramfs" >> '/boot/grub/grub.conf'

    ## Instalar GRUB en el disco duro
    # grep -v rootfs /proc/mounts > /etc/mtab
    # grub-install --no-floppy /dev/sda
}

installSoftware() {
    emerge syslog-ng
    rc-update add syslog-ng default

    emerge vixie-cron
    rc-update add vixie-cron default

    emerge mlocate
    emerge net-misc/dhcpcd
}

installChroot() {
    startChroot
    confRepos
    portageProfile
    installKernel
    createFstab
    configRed
    configLocales
    configRoot
    configUser
    installGrub
}
