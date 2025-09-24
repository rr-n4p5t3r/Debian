#!/bin/bash

# -----------------------------------------
# Autor: Ricardo Rosero
# Descripción:
# Script mejorado para la actualización y limpieza de Linux Mint.
# Más robusto y eficiente.
# -----------------------------------------

# Variable global para el estado de la operación
EXIT_CODE=0

# Función para manejar errores
function handle_error() {
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo "Error: El comando '$BASH_COMMAND' falló con código de salida $EXIT_CODE" >&2
        # Puedes agregar una notificación o logueo aquí si es necesario
    fi
}
trap 'handle_error' ERR

# Función para mostrar mensajes
function print_message() {
    echo "---"
    echo "$1"
    echo "---"
}

# --- Comprobación inicial y actualizaciones ---

# Comprobar si el script se ejecuta como root (opcional, pero buena práctica)
if [ "$(id -u)" -ne 0 ]; then
    print_message "Este script requiere permisos de root. Por favor, ejecútalo con 'sudo'."
    exit 1
fi

# Actualizar el sistema en un solo paso
print_message "Actualizando el sistema y dependencias..."
apt update && apt upgrade -y
apt dist-upgrade -y
apt --fix-broken install -y
dpkg --configure -a

# --- Limpieza y optimización ---

print_message "Limpiando paquetes innecesarios..."
apt autoremove --purge -y
apt autoclean
apt clean

# --- Lógica mejorada para la eliminación de kernels ---

function remove_old_kernels() {
    print_message "Preparando la eliminación de kernels antiguos..."

    # Obtener el kernel actual
    local current_kernel=$(uname -r | cut -d'-' -f1-2)

    # Obtener una lista de todos los kernels instalados de forma robusta
    local installed_kernels=($(dpkg --list | grep 'linux-image' | awk '{print $2}' | cut -d':' -f1 | cut -d'-' -f1-3 | sort -V | uniq))
    local kernel_to_keep_count=2
    local kernels_to_remove=()

    # Si hay menos de 3 kernels, no hacemos nada
    if [[ ${#installed_kernels[@]} -le $kernel_to_keep_count ]]; then
        print_message "No se eliminarán kernels. Hay menos de 3 kernels instalados."
        return
    fi

    # Seleccionar los kernels a eliminar
    for ((i=0; i<${#installed_kernels[@]}-$kernel_to_keep_count; i++)); do
        local kernel_version=${installed_kernels[$i]}
        
        # Evitar eliminar el kernel en uso
        if [[ "$kernel_version" != "$current_kernel" ]]; then
            kernels_to_remove+=("${kernel_version}")
        fi
    done
    
    if [[ ${#kernels_to_remove[@]} -eq 0 ]]; then
        print_message "No se encontraron kernels antiguos para eliminar."
        return
    fi
    
    # Construir el comando de purga para todos los kernels a la vez
    local purge_command="apt purge -y"
    for kernel in "${kernels_to_remove[@]}"; do
        purge_command+=" linux-image-$kernel linux-headers-$kernel"
    done
    
    print_message "Eliminando kernels y headers antiguos..."
    print_message "Comando a ejecutar: $purge_command"
    eval "$purge_command"
}

remove_old_kernels

# --- Verificación de reinicio ---

print_message "Verificando si el sistema requiere un reinicio..."
if [ -f /var/run/reboot-required ]; then
    print_message "El sistema requiere un reinicio para aplicar las actualizaciones."
    read -p "¿Deseas reiniciar ahora? (s/n): " reboot_answer
    if [[ "$reboot_answer" =~ ^[sS]$ ]]; then
        print_message "Reiniciando el sistema..."
        reboot
    else
        print_message "No se reiniciará el sistema. Puedes reiniciarlo manualmente más tarde."
    fi
else
    print_message "El sistema no requiere un reinicio."
fi

print_message "¡Actualización y optimización completadas!"
exit $EXIT_CODE
