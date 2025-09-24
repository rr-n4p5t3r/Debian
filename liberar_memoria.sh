#!/bin/bash

# ---------------------------------------------------------
# Script de verificación de uso de memoria y swap
# Autor: Ricardo Rosero
# Email: rrosero2000@gmail.com
# Github: https://github.com/rr-n4p5t3r
# ---------------------------------------------------------
# Este script verifica el uso de la memoria RAM y swap.
# Si el uso de la RAM supera el 80% o el uso de la swap
# supera el 40%, libera memoria RAM, reinicia la swap,
# y termina procesos de alto consumo de memoria si es necesario.
# ---------------------------------------------------------

# Umbrales
RAM_THRESHOLD=80
SWAP_THRESHOLD=40
PROCESS_MEMORY_LIMIT=10  # Porcentaje de RAM que un proceso puede usar antes de ser considerado para terminación

# Función para obtener el porcentaje de uso de memoria
get_memory_usage() {
    local usage=$(free | awk '/^Mem/ {printf("%.0f", $3/$2 * 100.0)}')
    echo "$usage"
}

# Función para obtener el porcentaje de uso de la swap
get_swap_usage() {
    local swap_total=$(free | awk '/^Swap/ {print $2}')
    if [ -z "$swap_total" ] || [ "$swap_total" -eq 0 ]; then
        echo "0"  # Si no hay swap configurado, devolvemos 0
    else
        local usage=$(free | awk '/^Swap/ {printf("%.0f", $3/$2 * 100.0)}')
        echo "$usage"
    fi
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

# Función para liberar RAM
free_ram() {
    echo "Liberando RAM..."
    sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
    echo "$(date): Memoria RAM liberada" >> /var/log/ram_free.log
}

# Función para matar procesos que usan mucha RAM
kill_heavy_processes() {
    echo "Identificando procesos que consumen más del $PROCESS_MEMORY_LIMIT% de la RAM..."
    
    # Encuentra los procesos que están usando más del 10% de RAM
    ps aux --sort=-%mem | awk -v limit=$PROCESS_MEMORY_LIMIT '$4 > limit {print $2, $4, $11}' | while read pid mem_usage process_name; do
        echo "El proceso $process_name con PID $pid está usando $mem_usage% de la RAM."
        
        # Si decides matar el proceso, descomenta la siguiente línea
        sudo kill -9 $pid
        echo "$(date): Proceso $process_name (PID $pid) que usaba $mem_usage% de la RAM ha sido terminado." >> /var/log/memory_process_kill.log
    done
}

# Obtener el porcentaje de uso de RAM y swap
ram_usage=$(get_memory_usage)
swap_usage=$(get_swap_usage)

# Depuración: Mostrar valores de RAM y Swap obtenidos
echo "Uso de RAM: $ram_usage%"
echo "Uso de Swap: ${swap_usage}%"

# Validar que los valores de RAM no estén vacíos y sean numéricos
if [ -z "$ram_usage" ] || ! [[ "$ram_usage" =~ ^[0-9]+$ ]]; then
    echo "Error: No se pudo obtener el uso de la RAM o el valor no es válido."
    exit 1
fi

# Validar que los valores de Swap no estén vacíos y sean numéricos
if [ -z "$swap_usage" ] || ! [[ "$swap_usage" =~ ^[0-9]+$ ]]; then
    echo "Error: No se pudo obtener el uso de la Swap o el valor no es válido."
    exit 1
fi

# Verificar si se supera el umbral de RAM
if [ "$ram_usage" -gt "$RAM_THRESHOLD" ]; then
    echo "Uso de RAM alto: $ram_usage% (Umbral: $RAM_THRESHOLD%)"
    free_ram  # Liberar RAM si se supera el umbral
    kill_heavy_processes  # Identificar y matar procesos que consumen demasiada memoria
fi

# Verificar si se supera el umbral de Swap
if [ "$swap_usage" -gt "$SWAP_THRESHOLD" ]; then
    echo "Uso de Swap alto: $swap_usage% (Umbral: $SWAP_THRESHOLD%)"
    reset_swap  # Resetear swap si se supera el umbral
fi
