#!/bin/bash

# ==================================================
# Auditor de Procesos del Sistema
# Desarrollado por CodeGuardian
# ==================================================

# Habilitar el modo de depuración y salir si un comando falla
set -e
trap 'echo "🚫 Error: El script ha fallado en la línea $LINENO." >&2; exit 1' ERR

# --- Funciones de Auditoría ---

audit_processes() {
    echo "Analizando procesos en ejecución..."

    if ! command -v ps &> /dev/null; then
        echo "🚫 ERROR: El comando 'ps' no está disponible. Asegúrese de que el paquete 'procps' o 'psmisc' esté instalado." >&2
        return 1
    fi

    # Obtener los 10 principales procesos ordenados por uso de CPU y memoria
    local top_cpu_processes
    local top_mem_processes
    readarray -t top_cpu_processes < <(ps aux --sort=-%cpu | head -n 11 | tail -n 10)
    readarray -t top_mem_processes < <(ps aux --sort=-%mem | head -n 11 | tail -n 10)
    
    # Imprimir los resultados
    echo ""
    echo "--------------------------------------------------------"
    echo "--- 🔟 Principales procesos por uso de CPU ---"
    echo "--------------------------------------------------------"
    print_processes_table "${top_cpu_processes[@]}"
    
    echo ""
    echo "--------------------------------------------------------"
    echo "--- 🔟 Principales procesos por uso de Memoria ---"
    echo "--------------------------------------------------------"
    print_processes_table "${top_mem_processes[@]}"
}

# --- Funciones de Formato ---

print_processes_table() {
    local entries=("$@")

    if [ ${#entries[@]} -eq 0 ]; then
        echo "No se encontraron procesos en ejecución."
        return 0
    fi
    
    # Paso 1: Determinar el ancho máximo de las columnas
    local max_user_len=10
    local max_pid_len=5
    local max_cpu_len=5
    local max_mem_len=5
    local max_command_len=40
    
    for entry in "${entries[@]}"; do
        local user pid cpu mem command
        read -r user pid cpu mem rest <<< "$entry"
        command=${rest#* } # Remove all fields until the command
        
        # Truncar el comando para que no desborde la tabla
        if [ ${#command} -gt "$max_command_len" ]; then
            command="${command:0:$max_command_len}..."
        fi
        
        if [ ${#user} -gt "$max_user_len" ]; then max_user_len=${#user}; fi
        if [ ${#pid} -gt "$max_pid_len" ]; then max_pid_len=${#pid}; fi
        if [ ${#cpu} -gt "$max_cpu_len" ]; then max_cpu_len=${#cpu}; fi
        if [ ${#mem} -gt "$max_mem_len" ]; then max_mem_len=${#mem}; fi
        # max_command_len is fixed, so no need to update it here
    done
    
    # Añadir un buffer para la legibilidad
    max_user_len=$((max_user_len + 2))
    max_pid_len=$((max_pid_len + 2))
    max_cpu_len=$((max_cpu_len + 2))
    max_mem_len=$((max_mem_len + 2))
    max_command_len=$((max_command_len + 2))

    # Paso 2: Imprimir el encabezado de la tabla
    printf "%-${max_user_len}s | %-${max_pid_len}s | %-${max_cpu_len}s | %-${max_mem_len}s | %s\n" "Usuario" "PID" "CPU(%)" "MEM(%)" "Comando"
    
    # Construir la línea de separación
    local sep_user=$(printf '%.0s-' $(seq 1 $max_user_len))
    local sep_pid=$(printf '%.0s-' $(seq 1 $max_pid_len))
    local sep_cpu=$(printf '%.0s-' $(seq 1 $max_cpu_len))
    local sep_mem=$(printf '%.0s-' $(seq 1 $max_mem_len))
    local sep_command=$(printf '%.0s-' $(seq 1 $max_command_len))
    printf "%s | %s | %s | %s | %s\n" "$sep_user" "$sep_pid" "$sep_cpu" "$sep_mem" "$sep_command"
    
    # Paso 3: Imprimir la información de cada proceso
    for entry in "${entries[@]}"; do
        local user pid cpu mem rest
        read -r user pid cpu mem rest <<< "$entry"
        local command=${rest#* }
        
        # Truncar el comando antes de imprimirlo
        if [ ${#command} -gt "$max_command_len" ]; then
            command="${command:0:$max_command_len-3}..."
        fi

        printf "%-${max_user_len}s | %-${max_pid_len}s | %-${max_cpu_len}s | %-${max_mem_len}s | %s\n" "$user" "$pid" "$cpu" "$mem" "$command"
    done
}

# --- Lógica principal del script ---

main() {
    echo "======================================================================================="
    echo "        Análisis de Procesos del Sistema"
    echo "======================================================================================="
    echo ""

    audit_processes
    
    echo "======================================================================================="
    echo "✅ Auditoría completada."
}

# Ejecutar la función principal
main

