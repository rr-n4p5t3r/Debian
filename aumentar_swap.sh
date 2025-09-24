#!/bin/bash
#
# Script mejorado para aumentar el tamaño de la swap en Linux
# ---------------------------------------------------
# Autor: Ricardo Rosero
# Descripción:
# Este script de gestión de swap es más robusto y seguro. Valida la entrada
# del usuario, maneja errores y garantiza que el proceso de creación y
# activación del archivo de swap sea atómico y consistente.
# ---------------------------------------------------

# Habilitar el modo de depuración para detectar errores y salir inmediatamente si un comando falla
set -e
trap 'echo "Error: El script ha fallado. Saliendo..." >&2; exit 1' ERR

# --- Verificación de privilegios de root ---
if [[ $EUID -ne 0 ]]; then
   echo "🚫 Error: Este script debe ser ejecutado como root."
   exit 1
fi

# --- Entrada de usuario y validación robusta ---
print_message() {
  echo "---"
  echo "$1"
  echo "---"
}

read -p "Ingresa el tamaño de la swap que deseas (en GB): " SWAPSIZE

# Validar que la entrada es un número entero positivo
if ! [[ "$SWAPSIZE" =~ ^[1-9][0-9]*$ ]]; then
  echo "🚫 Error: Por favor, ingresa un número entero válido mayor que cero."
  exit 1
fi

# --- Lógica principal ---

# Desactiva y elimina cualquier archivo de swap existente
if grep -q "/swapfile" /etc/fstab; then
  print_message "Desactivando y eliminando la entrada de swap en /etc/fstab..."
  sed -i '/\/swapfile/d' /etc/fstab
fi

if [ -f /swapfile ]; then
  print_message "Desactivando y eliminando el archivo de swap anterior..."
  swapoff /swapfile
  rm -f /swapfile
fi

# Crea el nuevo archivo de swap de forma robusta
print_message "Creando nuevo archivo de swap de ${SWAPSIZE}G..."
fallocate -l "${SWAPSIZE}G" /swapfile || {
  echo "⚠️ fallocate falló, usando el método más lento 'dd'..."
  dd if=/dev/zero of=/swapfile bs=1G count=$SWAPSIZE
}

# --- Configuración y activación ---
print_message "Configurando y activando la nueva swap..."
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# Persistencia de la swap en /etc/fstab
print_message "Añadiendo la entrada al archivo /etc/fstab para persistencia..."
echo "/swapfile none swap sw 0 0" >> /etc/fstab

# --- Verificación final y limpieza ---
print_message "Swap creada y activada con éxito."
swapon --show
free -h

print_message "Proceso completado."
exit 0
