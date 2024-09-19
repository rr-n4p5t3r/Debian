#!/bin/bash
#
# Script para aumentar el tamaño de la swap en Linux
# ---------------------------------------------------
# Autor: Ricardo Rosero
# Email: rrosero2000@gmail.com
# GitHub: https://github.com/rr-n4p5t3r
#
# Descripción:
# Este script permite a los usuarios configurar el tamaño de la swap de acuerdo
# con sus necesidades, haciendo que el tamaño de swap sea persistente tras el
# reinicio del sistema. Si ya existe un archivo swap, este será eliminado y se
# creará uno nuevo con el tamaño indicado por el usuario.
#
# Uso:
# Ejecutar el script como root:
#     sudo ./aumentar_swap.sh
#
# El script pedirá al usuario que ingrese el tamaño de la swap en GB y luego
# procederá a crear, activar y configurar el archivo swap.
#
# ---------------------------------------------------

# Verifica si el script está siendo ejecutado como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor ejecuta el script como root"
  exit 1
fi

# Solicita el tamaño de swap que el usuario desea en GB
read -p "Ingresa el tamaño de la swap que deseas (en GB): " SWAPSIZE

# Verificación de entrada válida
# Si el usuario no ingresa un valor numérico o un valor menor o igual a cero, el script se detiene
if ! [[ "$SWAPSIZE" =~ ^[0-9]+$ ]] || [ "$SWAPSIZE" -le 0 ]; then
  echo "Error: Por favor ingresa un número válido mayor que 0."
  exit 1
fi

# Desactiva cualquier swap existente
echo "Desactivando swap actual (si existe)..."
swapoff /swapfile

# Elimina el archivo swap anterior (si existe)
if [ -f /swapfile ]; then
  echo "Eliminando archivo swap anterior..."
  rm /swapfile
fi

# Crea un nuevo archivo swap con el tamaño proporcionado en GB
echo "Creando nuevo archivo swap de ${SWAPSIZE}G..."
fallocate -l "${SWAPSIZE}G" /swapfile

# Verifica si fallocate falló (por ejemplo, en sistemas de archivos que no lo soportan) y usa dd en su lugar
if [ $? -ne 0 ]; then
  echo "fallocate falló, usando dd en su lugar..."
  dd if=/dev/zero of=/swapfile bs=1M count=$((SWAPSIZE * 1024))
fi

# Establece los permisos correctos para el archivo swap (solo accesible por root)
chmod 600 /swapfile

# Formatea el archivo como área de swap
mkswap /swapfile

# Activa la swap
swapon /swapfile

# Añade la swap a /etc/fstab para que sea persistente tras el reinicio
# Verifica si la entrada para /swapfile ya existe en /etc/fstab
if ! grep -q "/swapfile" /etc/fstab; then
  echo "/swapfile none swap sw 0 0" >> /etc/fstab
  echo "Swap añadida a /etc/fstab para persistencia."
fi

# Muestra el estado actual de la swap
echo "Swap creada y activada con éxito."
swapon --show
free -h

# Fin del script
