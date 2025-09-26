#!/bin/bash

# =======================================================================
# Monitor de Sistema en Tiempo Real
# Desarrollado por Ricardo Rosero
# =======================================================================

# Habilitar el modo de depuración y salir si un comando falla
set -e
trap 'echo -e "\n✅ El monitoreo del sistema ha finalizado." >&2; exit 0' INT

# --- Funciones de Auditoría ---

audit_cpu() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    echo "Uso de CPU: ${cpu_usage}%"
}

audit_memory() {
    local mem_total=$(free -h | grep "Mem:" | awk '{print $2}')
    local mem_used=$(free -h | grep "Mem:" | awk '{print $3}')
    local mem_free=$(free -h | grep "Mem:" | awk '{print $4}')
    echo "Memoria Total: ${mem_total}"
    echo "Memoria Usada: ${mem_used}"
    echo "Memoria Libre: ${mem_free}"
}

audit_storage() {
    local disk_usage=$(df -h --total | tail -n 1 | awk '{print "Uso del disco: " $5 " (" $2 " total)"}')
    echo "${disk_usage}"
}

audit_network() {
    echo "Estado de la red:"
    if command -v ip &> /dev/null; then
        ip -o link show up | awk '{print "  " $2 " (" $1 "): " $9 " | MAC: " $6}'
    else
        echo "  ℹ️ Instala 'iproute2' para obtener detalles de red."
    fi
}

audit_processes() {
    echo ""
    echo "--------------------------------------------------------"
    echo "--- 🔟 Principales procesos por uso de CPU ---"
    echo "--------------------------------------------------------"
    ps aux --sort=-%cpu | head -n 11 | tail -n 10 | awk '{printf "%-10s %-5s %-5s %-5s %s\n", $1, $2, $3, $4, substr($11, 1, 40) "..."}'

    echo ""
    echo "--------------------------------------------------------"
    echo "--- 🔟 Principales procesos por uso de Memoria ---"
    echo "--------------------------------------------------------"
    ps aux --sort=-%mem | head -n 11 | tail -n 10 | awk '{printf "%-10s %-5s %-5s %-5s %s\n", $1, $2, $3, $4, substr($11, 1, 40) "..."}'
}

# --- Lógica principal del script ---

main() {
    while true; do
        clear
        echo "======================================================================================="
        echo "        Monitor de Sistema en Tiempo Real (Presione Ctrl+C para salir)"
        echo "======================================================================================="
        echo ""

        audit_cpu
        audit_memory
        audit_storage
        audit_network
        audit_processes
        
        echo ""
        echo "======================================================================================="
        sleep 10  # La pantalla se refrescará cada 10 segundos
    done
}

# Ejecutar la función principal
main

