# sign-OC
Script para automatizar tareas al integrar UEFI Secure Boot y OpenCore

He creado un script que automatiza el proceso unificando varios pasos:

- poner al día los orígenes de actualización de Ubuntu antes de comprobar si tenemos las herramientas unzip, sbsigntool y efitools
- instalar las herramientas necesarias si no lo están ya
- generar las claves digitales
- descargar la versión de OpenCore que deseamos utilizar
- firmar los archivos .efi de OpenCore.
- copiar los archivos generados a la carpeta Descargas

Este script sólo necesita como parámetro de entrada la versión de OpenCore con el siguiente formato X.Y.Z. Ejemplo: sh ./sign_oc.sh 0.7.6 crea una carpeta llamada oc en la carpeta de descargas de Windows con todos los archivos necesarios.

Nota: para completar el artículo [OpenCore-and-UEFI-Secure-Boot](https://github.com/perez987/OpenCore-and-UEFI-Secure-Boot).
