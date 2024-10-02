#!/bin/bash

# ---------------------------------------------------------
# Script de verificación de uso de memoria y swap
# Autor: Ricardo Rosero
# Email: rrosero2000@gmail.com
# Github: https://github.com/rr-n4p5t3r
# ---------------------------------------------------------
# Este script verifica el uso de la memoria RAM y swap.
# Si el uso de la RAM supera el 80% o el uso de la swap
# supera el 50%, ejecuta los comandos `swapoff -a` y `sudo swapon -a`.
# ---------------------------------------------------------

# Umbrales
RAM_THRESHOLD=80
SWAP_THRESHOLD=40

# Obtén el porcentaje de uso de la RAM
ram_usage=$(free | awk '/^Mem/ {printf("%.0f", $3/$2 * 100.0)}')

# Obtén el porcentaje de uso de la Swap
swap_usage=$(free | awk '/^Swap/ {printf("%.0f", $3/$2 * 100.0)}')

# Asegúrate de que ram_usage y swap_usage no estén vacíos
ram_usage=${ram_usage:-0}
swap_usage=${swap_usage:-0}

# Verifica si alguno de los umbrales se ha superado y ejecuta los comandos si es necesario
if [ "$ram_usage" -gt "$RAM_THRESHOLD" ] || [ "$swap_usage" -gt "$SWAP_THRESHOLD" ]; then
    sudo swapoff -a
    sudo swapon -a
fi
