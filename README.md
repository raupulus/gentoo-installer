# gentoo-installer

Instalador para gentoo que me facilita el trabajo a la hora de reinstalar siguiendo unos patrones de preferencias

## ADVERTENCIA

Este script puede ser arriesgado y no me hago responsable.

El objetivo con el que ha sido creado es facilitar mis propias
instalaciones, aún así lo comparto para que otras personas puedan
obtener beneficio pero en ningún momento contemplaré ni daré soporte a
otros objetivos distintos.

Por supuesto si que correjiré fallos e implemetaré mejoras siempre que
sea posible y viable para el objetivo actual.

Usa este repositorio bajo tu propia responsabilidad.

## Modo de uso

Clonamos el repositorio dentro del live o medio de instalación

```bash
git clone https://gitlab.com/fryntiz/gentoo-installer.git
```

Editamos las variables de configuración en el archivo **config**

```bash
nano config
```

La instalación se lleva a cabo simplemente ejecutando:

```bash
./gentoo-installer.sh
```

Una vez el script anterior nos deja dentro del entorno enjaulado chroot
ejecutaremos el segundo script para terminar de personalizar el sistema:

```bash
cd / && ./chroot.sh
```
