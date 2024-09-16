#!/bin/bash

# ---------------------------------------------------------
# Script de verificación de uso de memoria y swap
# Autor: Ricardo Rosero
# Email: rrosero2000@gmail.com
# Github: https://github.com/rr-n4p5t3r
# ---------------------------------------------------------
# Este script verifica el uso de la memoria RAM y swap.
# Si el uso de la RAM supera el 80% o el uso de la swap
# supera el 40%, ejecuta los comandos `swapoff -a` y `sudo swapon -a`.
# ---------------------------------------------------------

# Umbrales
RAM_THRESHOLD=80
SWAP_THRESHOLD=40

# Función para obtener el porcentaje de uso de memoria
get_memory_usage() {
    local usage=$(free | awk '/^Mem/ {printf("%.0f", $3/$2 * 100.0)}')
    echo "$usage"
}

# Función para obtener el porcentaje de uso de la swap
get_swap_usage() {
    local usage=$(free | awk '/^Swap/ {printf("%.0f", $3/$2 * 100.0)}')
    echo "$usage"
}

# Función para realizar el swapoff y swapon
reset_swap() {
    echo "Reseteando swap..."
    if sudo swapoff -a && sudo swapon -a; then
        echo "$(date): Swap reseteado con éxito" >> /var/log/swap_reset.log
    else
        echo "$(date): Error al resetear swap" >> /var/log/swap_reset.log
    fi
}

# Obtener el porcentaje de uso de RAM y swap
ram_usage=$(get_memory_usage)
swap_usage=$(get_swap_usage)

# Verificar si se supera el umbral de RAM
if [ "$ram_usage" -gt "$RAM_THRESHOLD" ]; then
    echo "Uso de RAM alto: $ram_usage% (Umbral: $RAM_THRESHOLD%)"
    reset_swap
fi

# Verificar si se supera el umbral de Swap
if [ "$swap_usage" -gt "$SWAP_THRESHOLD" ]; then
    echo "Uso de Swap alto: $swap_usage% (Umbral: $SWAP_THRESHOLD%)"
    reset_swap
fi
