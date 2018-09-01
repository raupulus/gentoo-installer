#!/usr/bin/env bash
# -*- ENCODING: UTF-8 -*-
##
## @author     Raúl Caro Pastorino
## @copyright  Copyright © 2018 Raúl Caro Pastorino
## @license    https://wwww.gnu.org/licenses/gpl.txt
## @email      dev@fryntiz.es
## @web        https://fryntiz.es
## @gitlab     https://gitlab.com/fryntiz
## @github     https://github.com/fryntiz
## @twitter    https://twitter.com/fryntiz
##
##             Guía de estilos aplicada:
## @style      https://gitlab.com/fryntiz/bash-guide-style

############################
##     INSTRUCCIONES      ##
############################
## Genera una instalación del sistema operativo GNU/Linux Gentoo

############################
##     IMPORTACIONES      ##
############################
## Importo variables de configuración
source "config"

## Importo funciones auxiliares
source "functions.sh"

############################
##       FUNCIONES        ##
############################
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
## Copio el script en el objetivo de la jaula chroot para poder
## ejecutar el resto de la instalación desde allí dentro.
##
copiarScriptEnJaula() {
    cp config functions.sh chroot.sh "$JAULA/"
}

##
## Prepara portage con personalizaciones a mi gusto
##
configurarPortage() {
    cp portage/* "$JAULA/etc/portage/"
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
copiarScriptEnJaula

## Copia resolución DNS en la jaula
cp -L /etc/resolv.conf /mnt/gentoo/etc/resolv.conf

enjaular
desmontar

exit 0
