#!/bin/bash

# ==================================================
# Auditor de Puertos TCP Comunes
# Desarrollado por Ricardo Rosero
# ==================================================

# Habilitar el modo de depuración y salir si un comando falla
set -e
trap 'echo "🚫 Error: El script ha fallado en la línea $LINENO." >&2; exit 1' ERR

# --- Funciones de Auditoría ---

audit_ports() {
    echo "Detectando puertos abiertos..."

    if ! command -v ss &> /dev/null; then
        echo "🚫 ERROR: El comando 'ss' no está disponible. Asegúrese de que el paquete 'iproute2' esté instalado." >&2
        return 1
    fi

    # Puertos comunes a auditar
    local common_ports=(21 22 25 53 80 110 143 443 465 587 993 995 3306 5432 8080)
    local connections=()
    
    for port in "${common_ports[@]}"; do
        local is_open="❌ Cerrado"
        local service="Desconocido"
        
        # El comando 'ss' no es tan fiable para comprobar puertos específicos sin un proceso escuchando.
        # En su lugar, comprobamos si un proceso está escuchando en ese puerto.
        local listener=$(ss -tlnp "sport = :$port" 2>/dev/null | grep LISTEN)
        if [[ -n "$listener" ]]; then
            is_open="✅ Abierto"
            # Extraer el nombre del servicio (si está disponible)
            local process_info=$(echo "$listener" | awk '{print $NF}')
            service=$(echo "$process_info" | sed 's/.*,.\(.*\),.*/\1/' | sed 's/".*//')
        fi
        
        connections+=("$port|$is_open|$service")
    done

    # Imprimir la tabla
    print_ports_table "${connections[@]}"
}

# --- Funciones de Formato ---

print_ports_table() {
    local entries=("$@")

    echo "======================================================================================="
    echo "        Análisis de Puertos del Sistema"
    echo "======================================================================================="
    echo ""
    
    if [ ${#entries[@]} -eq 0 ]; then
        echo "No se encontraron puertos abiertos en el sistema."
        echo "======================================================================================="
        echo "✅ Auditoría completada."
        return 0
    fi
    
    # Paso 1: Determinar el ancho máximo de las columnas
    local max_port_len=10
    local max_status_len=12
    local max_service_len=20
    
    for entry in "${entries[@]}"; do
        IFS='|' read -r port status service <<< "$entry"
        if [ ${#port} -gt "$max_port_len" ]; then max_port_len=${#port}; fi
        if [ ${#status} -gt "$max_status_len" ]; then max_status_len=${#status}; fi
        if [ ${#service} -gt "$max_service_len" ]; then max_service_len=${#service}; fi
    done
    
    # Añadir un buffer para la legibilidad
    max_port_len=$((max_port_len + 2))
    max_status_len=$((max_status_len + 2))
    max_service_len=$((max_service_len + 2))

    # Paso 2: Imprimir el encabezado de la tabla
    printf "%-${max_port_len}s | %-${max_status_len}s | %s\n" "Puerto" "Estado" "Servicio"
    
    # Construir la línea de separación
    local sep_port=$(printf '%.0s-' $(seq 1 $max_port_len))
    local sep_status=$(printf '%.0s-' $(seq 1 $max_status_len))
    local sep_service=$(printf '%.0s-' $(seq 1 $max_service_len))
    printf "%s | %s | %s\n" "$sep_port" "$sep_status" "$sep_service"
    
    # Paso 3: Imprimir la información de cada puerto
    for entry in "${entries[@]}"; do
        IFS='|' read -r port status service <<< "$entry"
        printf "%-${max_port_len}s | %-${max_status_len}s | %s\n" "$port" "$status" "$service"
    done

    echo "======================================================================================="
    echo "✅ Auditoría completada."
}

# --- Lógica principal del script ---

main() {
    audit_ports
}

# Ejecutar la función principal
main

