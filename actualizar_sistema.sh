#!/bin/bash

# -----------------------------------------
# Autor: Ricardo Rosero
# Descripción:
# Script mejorado para la actualización y limpieza de sistemas Debian/Ubuntu.
# Más seguro, robusto y eficiente.
# -----------------------------------------

# Función para manejar errores de comandos
set -e
trap 'echo "Error: El comando falló. Saliendo..." >&2; exit 1' ERR

# Función para mostrar mensajes
function print_message() {
    echo "---"
    echo "✅ $1"
    echo "---"
}

# --- Chequeo de privilegios ---
if [[ $EUID -ne 0 ]]; then
   print_message "Este script debe ser ejecutado como root. Por favor, usa 'sudo'."
   exit 1
fi

# --- Actualización del sistema ---
print_message "Actualizando el sistema y dependencias..."
apt update -y && apt full-upgrade -y

# --- Limpieza y reparación combinadas ---
print_message "Limpiando y reparando paquetes rotos o no necesarios..."
apt autoremove --purge -y
apt --fix-broken install -y
apt autoclean
apt clean
dpkg --configure -a

# --- Lógica de eliminación de kernels (Más Segura) ---
print_message "Buscando kernels antiguos para eliminar..."
# Obtener el kernel actual en uso (ej. 6.5.0-26-generic)
KERNEL_CURRENT=$(uname -r)
# Obtener la lista de kernels instalados de forma segura
KERNELS_INSTALLED=$(dpkg --list | awk '/linux-image-/ {print $2}')
# Contar los kernels que se mantienen (al menos 2 por seguridad)
KERNEL_KEEP_COUNT=2
# Inicializar array de kernels a eliminar
KERNELS_TO_PURGE=()

# Lógica para seleccionar kernels a eliminar
for KERNEL in $KERNELS_INSTALLED; do
    # Evitar purgar el kernel actual
    if [[ "$KERNEL" == "linux-image-$KERNEL_CURRENT" ]]; then
        print_message "Manteniendo el kernel en uso: $KERNEL_CURRENT"
        continue
    fi
    # Agregar a la lista de purga
    KERNELS_TO_PURGE+=("$KERNEL")
done

# Si hay más de 2 kernels, purga los más antiguos
if [[ ${#KERNELS_TO_PURGE[@]} -gt $(($KERNEL_KEEP_COUNT-1)) ]]; then
    # Ordenar y seleccionar los más antiguos para purgar
    KERNELS_TO_PURGE=($(printf '%s\n' "${KERNELS_TO_PURGE[@]}" | sort -V | head -n -$(($KERNEL_KEEP_COUNT-1))))
    
    print_message "Se purgarán los siguientes kernels antiguos:"
    for KERNEL in "${KERNELS_TO_PURGE[@]}"; do
        echo "  - $KERNEL"
        # Eliminar también los headers asociados para ahorrar espacio
        apt purge -y "$KERNEL" "${KERNEL//image/headers}"
    done
else
    print_message "No se encontraron kernels antiguos para eliminar o solo hay kernels de respaldo."
fi

# --- Verificación de reinicio ---
print_message "Verificando si se requiere un reinicio..."
if [ -f /var/run/reboot-required ]; then
    print_message "El sistema requiere un reinicio para completar las actualizaciones."
    read -p "¿Deseas reiniciar ahora? (s/n): " REBOOT_ANSWER
    if [[ "$REBOOT_ANSWER" =~ ^[Ss]$ ]]; then
        print_message "Reiniciando el sistema..."
        reboot
    else
        print_message "Reinicio pospuesto. Por favor, reinicia manualmente."
    fi
else
    print_message "El sistema no requiere un reinicio."
fi

print_message "Actualización y optimización completadas exitosamente."
