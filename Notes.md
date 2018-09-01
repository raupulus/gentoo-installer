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
