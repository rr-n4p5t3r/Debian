#!/bin/bash

# ==================================================
# Script de monitoreo y optimización de memoria y swap
# Desarrollado por Ricardo Rosero
# ==================================================

# Habilitar el modo de depuración y salir si un comando falla
set -e
trap 'echo "🚫 Error: El script ha fallado en la línea $LINENO." >&2; exit 1' ERR

# --- Umbrales y configuración ---
readonly RAM_THRESHOLD=80
readonly SWAP_THRESHOLD=50
readonly LOG_FILE="/var/log/memory_monitor.log"

# --- Funciones de utilidad ---

# Verificar si el script se está ejecutando como root
check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "🚫 Este script debe ejecutarse con privilegios de root (sudo) para funcionar correctamente."
        exit 1
    fi
}

# Obtener el uso de memoria en un solo comando
get_usage() {
    local mem_usage=$(free | awk '/^Mem/ {printf("%.0f", $3/$2 * 100.0)}')
    local swap_usage=$(free | awk '/^Swap/ {if ($2>0) printf("%.0f", $3/$2 * 100.0); else print 0}')
    echo "$mem_usage $swap_usage"
}

# Realizar la operación de swapoff y swapon
reset_swap() {
    echo "✅ Reseteando swap..."
    if sudo swapoff -a && sudo swapon -a; then
        echo "Swap reseteada con éxito."
    else
        echo "Error al resetear swap."
    fi
}

# --- Lógica principal del script ---

main() {
    check_root

    echo "Iniciando la verificación de uso de memoria y swap..."
    
    # Obtener el uso actual de RAM y Swap
    read -r ram_usage swap_usage <<< "$(get_usage)"
    
    echo "Uso de RAM: $ram_usage%"
    echo "Uso de Swap: $swap_usage%"

    # Si la RAM supera el umbral
    if (( ram_usage > RAM_THRESHOLD )); then
        echo "⚠️  Uso de RAM alto: $ram_usage% (Umbral: $RAM_THRESHOLD%)"
    fi

    # Si la Swap supera el umbral
    if (( swap_usage > SWAP_THRESHOLD )); then
        echo "⚠️  Uso de Swap alto: $swap_usage% (Umbral: $SWAP_THRESHOLD%)"
        reset_swap
    else
        echo "Uso de Swap por debajo del umbral, no se requiere acción."
    fi

    echo "✅ Verificación completa."
}

main

