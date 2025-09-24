#!/bin/bash

# ==================================================
# Script de monitoreo y optimización de memoria y swap
# Desarrollado por Ricardo Rosero
# ==================================================

# Habilitar el modo de depuración y salir si un comando falla
set -e
trap 'echo "🚫 Error: El script ha fallado en la línea $LINENO." >&2; exit 1' ERR

# --- Umbrales y configuración ---
readonly RAM_THRESHOLD=85   # Aumentado para evitar falsos positivos
readonly SWAP_THRESHOLD=60  # Aumentado para evitar falsos positivos
readonly PROCESS_MEMORY_LIMIT=15 # Porcentaje de RAM que un proceso puede usar
readonly LOG_FILE="/var/log/memory_monitor.log"
readonly EXCLUDE_PROCESSES=("gnome-shell" "kdeinit5" "systemd" "firefox" "chrome") # Procesos a excluir de la terminación

# --- Funciones de utilidad ---

# Función de registro de eventos
log_event() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a "$LOG_FILE" > /dev/null
}

# Obtener el uso de memoria en un solo comando
get_usage() {
    local mem_usage=$(free | awk '/^Mem/ {printf("%.0f", $3/$2 * 100.0)}')
    local swap_usage=$(free | awk '/^Swap/ {if ($2>0) printf("%.0f", $3/$2 * 100.0); else print 0}')
    echo "$mem_usage $swap_usage"
}

# Liberar la caché de RAM de forma segura
free_ram() {
    echo "✅ Liberando RAM..."
    sync
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    log_event "Memoria RAM liberada."
}

# Resetear la swap
reset_swap() {
    echo "✅ Reseteando swap..."
    if sudo swapoff -a && sudo swapon -a; then
        log_event "Swap reseteada con éxito."
    else
        log_event "Error al resetear swap."
    fi
}

# Terminar procesos de forma segura
kill_heavy_processes() {
    echo "✅ Identificando procesos que consumen más del $PROCESS_MEMORY_LIMIT% de la RAM..."
    local pids_to_kill=$(ps aux --sort=-%mem | awk -v limit="$PROCESS_MEMORY_LIMIT" '$4 > limit {print $2}')
    local processes_terminated=0

    for pid in $pids_to_kill; do
        local process_name=$(ps -p "$pid" -o comm=)
        local is_excluded=false
        for excluded in "${EXCLUDE_PROCESSES[@]}"; do
            if [[ "$process_name" == "$excluded" ]]; then
                is_excluded=true
                break
            fi
        done

        if [[ "$is_excluded" == "false" ]]; then
            echo "   Terminando proceso: $process_name (PID: $pid)"
            if sudo kill -9 "$pid" &>/dev/null; then
                log_event "Proceso $process_name (PID: $pid) terminado."
                processes_terminated=$((processes_terminated+1))
            fi
        fi
    done

    if [[ "$processes_terminated" -gt 0 ]]; then
        echo "   Se han terminado $processes_terminated procesos de alto consumo."
    else
        echo "   No se encontraron procesos para terminar."
    fi
}

# --- Lógica principal del script ---

main() {
    # Verificar si el script se está ejecutando como root
    if [[ $EUID -ne 0 ]]; then
        echo "🚫 Este script debe ejecutarse con privilegios de root (sudo) para funcionar correctamente."
        exit 1
    fi

    # Obtener el uso actual de RAM y Swap
    read -r ram_usage swap_usage <<< "$(get_usage)"
    
    echo "Uso de RAM: $ram_usage%"
    echo "Uso de Swap: $swap_usage%"

    # Si la RAM supera el umbral, liberamos caché y terminamos procesos
    if (( ram_usage > RAM_THRESHOLD )); then
        echo "⚠️  Uso de RAM alto: $ram_usage% (Umbral: $RAM_THRESHOLD%)"
        free_ram
        kill_heavy_processes
    fi

    # Si la Swap supera el umbral, la reseteamos
    if (( swap_usage > SWAP_THRESHOLD )); then
        echo "⚠️  Uso de Swap alto: $swap_usage% (Umbral: $SWAP_THRESHOLD%)"
        reset_swap
    fi

    echo "✅ Verificación completa."
}

# Ejecutar la función principal
main

