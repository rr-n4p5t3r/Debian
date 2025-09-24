#!/bin/bash
#
# Script mejorado para monitorear memoria y swap de forma segura
# ---------------------------------------------------
# Autor: Ricardo Rosero
# Descripción:
# Este script monitorea de manera segura el uso de la memoria RAM y swap.
# En lugar de resetear la swap de forma agresiva, registra un evento
# y sugiere una acción al usuario si los umbrales se superan.
# ---------------------------------------------------

# Habilitar el modo de depuración para detectar errores
set -e
trap 'echo "Error: El script ha fallado. Saliendo..." >&2; exit 1' ERR

# --- Umbrales y configuración ---
readonly RAM_THRESHOLD=80
readonly SWAP_THRESHOLD=40
readonly LOG_FILE="/var/log/memory_monitor.log"

# --- Funciones de utilidad ---
function log_event() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" | tee -a "$LOG_FILE"
}

function get_memory_info() {
    # Usar /proc/meminfo para una lectura más precisa y consistente
    local mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    local mem_free=$(awk '/MemFree/ {print $2}' /proc/meminfo)
    local mem_buffers=$(awk '/Buffers/ {print $2}' /proc/meminfo)
    local mem_cached=$(awk '/Cached/ {print $2}' /proc/meminfo)
    
    # Calcular RAM disponible y porcentaje de uso
    # La memoria disponible es una métrica más precisa que la memoria libre
    local mem_available=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
    local ram_usage_percent=0
    if [[ "$mem_total" -gt 0 ]]; then
        ram_usage_percent=$(( ( (mem_total - mem_available) * 100 ) / mem_total ))
    fi
    echo "$ram_usage_percent"
}

function get_swap_info() {
    local swap_total=$(awk '/SwapTotal/ {print $2}' /proc/meminfo)
    local swap_free=$(awk '/SwapFree/ {print $2}' /proc/meminfo)
    local swap_usage_percent=0
    if [[ "$swap_total" -gt 0 ]]; then
        swap_usage_percent=$(( ( (swap_total - swap_free) * 100) / swap_total ))
    fi
    echo "$swap_usage_percent"
}

# --- Lógica principal del monitoreo ---

# Obtener los porcentajes de uso
ram_usage=$(get_memory_info)
swap_usage=$(get_swap_info)

# Mostrar estado actual y registrar
log_event "Estado actual - Uso de RAM: $ram_usage% | Uso de Swap: $swap_usage%"

# Evaluar condiciones
if [[ "$ram_usage" -gt "$RAM_THRESHOLD" ]]; then
    log_event "⚠️ ALERTA: Uso de RAM ($ram_usage%) supera el umbral ($RAM_THRESHOLD%). Posible escasez de memoria."
    # Acción sugerida: Notificar al administrador, pero no resetear la swap.
    # Por ejemplo, puedes enviar un correo o una notificación de push.
fi

if [[ "$swap_usage" -gt "$SWAP_THRESHOLD" ]]; then
    log_event "⚠️ ALERTA: Uso de Swap ($swap_usage%) supera el umbral ($SWAP_THRESHOLD%)."
    # Acción sugerida: Investigar la causa. Aumentar la RAM o el tamaño de la swap.
fi

log_event "Verificación completada."
exit 0
