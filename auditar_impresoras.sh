#!/bin/bash

# ==================================================
# Auditor de Impresoras del Sistema
# Desarrollado por Ricardo Rosero
# ==================================================

# Habilitar el modo de depuración y salir si un comando falla
set -e
trap 'echo "🚫 Error: El script ha fallado en la línea $LINENO." >&2; exit 1' ERR

# --- Funciones de Auditoría ---

audit_printers() {
    echo "Detectando impresoras locales y de red..."

    if ! command -v lpstat &> /dev/null; then
        echo "🚫 ERROR: El comando 'lpstat' no está disponible. Asegúrese de que CUPS esté instalado y en ejecución." >&2
        return 1
    fi

    local printers=()
    local printer_names=()
    
    # Obtener la lista de nombres de impresoras instaladas desde lpstat -p
    # Ajustar para sistemas con salida en español
    while IFS= read -r line; do
        if [[ "$line" =~ ^"la impresora " ]]; then
            local name=$(echo "$line" | awk '{print $3}')
            if [[ ! -z "$name" ]]; then
                printer_names+=("$name")
            fi
        fi
    done < <(lpstat -p 2>/dev/null)

    if [ ${#printer_names[@]} -eq 0 ]; then
        echo "No se encontraron impresoras instaladas en el sistema."
        return 0
    fi
    
    for printer_name in "${printer_names[@]}"; do
        # Obtener la URI del dispositivo desde lpstat -v
        local device_uri=$(lpstat -v "$printer_name" 2>/dev/null | awk '{print $NF}')
        
        # Obtener el estado de la impresora desde lpstat -p
        local printer_status=$(lpstat -p "$printer_name" 2>/dev/null | awk '{print $4}' | sed 's/[()]/ /g' | xargs)

        # Verificar si es una impresora de red
        local is_network="❌ Local"
        if [[ "$device_uri" == *"://"* ]]; then
            is_network="✅ Red"
        fi
        
        # Obtener información del controlador
        local driver_info=$(lpinfo -m 2>/dev/null | grep -m 1 "$printer_name" | awk '{print $1}')
        if [ -z "$driver_info" ]; then
            driver_info="Desconocido"
        fi
        
        printers+=("$printer_name|$is_network|$printer_status|$driver_info")
    done

    # Imprimir el encabezado y el contenido de la tabla
    print_table "${printers[@]}"
}

# --- Funciones de Formato ---

print_table() {
    local entries=("$@")

    if [ ${#entries[@]} -eq 0 ]; then
        echo "No se encontraron impresoras en el sistema."
        echo "======================================================================================="
        echo "✅ Auditoría completada."
        return 0
    fi
    
    # Paso 1: Determinar el ancho máximo de las columnas
    local max_name_len=15
    local max_type_len=10
    local max_status_len=10
    local max_driver_len=20
    
    for entry in "${entries[@]}"; do
        IFS='|' read -r name type status driver <<< "$entry"
        if [ ${#name} -gt "$max_name_len" ]; then max_name_len=${#name}; fi
        if [ ${#type} -gt "$max_type_len" ]; then max_type_len=${#type}; fi
        if [ ${#status} -gt "$max_status_len" ]; then max_status_len=${#status}; fi
        if [ ${#driver} -gt "$max_driver_len" ]; then max_driver_len=${#driver}; fi
    done
    
    # Añadir un buffer para la legibilidad de las columnas
    max_name_len=$((max_name_len + 2))
    max_type_len=$((max_type_len + 2))
    max_status_len=$((max_status_len + 2))
    max_driver_len=$((max_driver_len + 2))
    
    # Paso 2: Imprimir el encabezado de la tabla
    printf "%-${max_name_len}s | %-${max_type_len}s | %-${max_status_len}s | %s\n" "Impresora" "Tipo" "Estado" "Controlador"
    
    # Construir la línea de separación
    local sep_name=$(printf '%.0s-' $(seq 1 $max_name_len))
    local sep_type=$(printf '%.0s-' $(seq 1 $max_type_len))
    local sep_status=$(printf '%.0s-' $(seq 1 $max_status_len))
    local sep_driver=$(printf '%.0s-' $(seq 1 $max_driver_len))
    printf "%s | %s | %s | %s\n" "$sep_name" "$sep_type" "$sep_status" "$sep_driver"
    
    # Paso 3: Auditar e imprimir la información de cada impresora
    for entry in "${entries[@]}"; do
        IFS='|' read -r name type status driver <<< "$entry"
        printf "%-${max_name_len}s | %-${max_type_len}s | %-${max_status_len}s | %s\n" "$name" "$type" "$status" "$driver"
    done

    echo "======================================================================================="
    echo "✅ Auditoría completada."
}

# --- Lógica principal del script ---

main() {
    echo "======================================================================================="
    echo "        Análisis de Impresoras del Sistema"
    echo "======================================================================================="
    echo ""

    audit_printers
}

# Ejecutar la función principal
main

