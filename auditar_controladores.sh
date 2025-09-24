#!/bin/bash

# ==================================================
# Auditor de Controladores del Sistema
# Desarrollado por Ricardo Rosero
# ==================================================

# Habilitar el modo de depuración y salir si un comando falla
set -e
trap 'echo "🚫 Error: El script ha fallado en la línea $LINENO." >&2; exit 1' ERR

# --- Funciones de Auditoría por Sistema Operativo ---

# Auditoría para sistemas basados en Linux
audit_linux_drivers() {
    echo "Detectando sistema: Linux. Usando lspci y lsmod."
    
    if ! command -v lsmod &> /dev/null || ! command -v lspci &> /dev/null || ! command -v lshw &> /dev/null; then
        echo "🚫 ERROR: Faltan comandos esenciales ('lsmod', 'lspci', 'lshw'). Asegúrese de que estén instalados." >&2
        return 1
    fi

    local drivers=()
    
    # Obtener una lista de módulos del kernel
    local modules_info=$(lsmod | awk 'NR>1 {print $1, $4}')
    
    # Obtener una lista de dispositivos y sus controladores
    local devices_info=$(lshw -short -class display -class network -class multimedia -class scsi -class storage 2>/dev/null)

    # Procesar y combinar la información
    while IFS= read -r line; do
        local driver_name=$(echo "$line" | awk '{print $1}')
        local device_desc=$(echo "$line" | awk '{$1=""; print $0}')
        drivers+=("$driver_name|$device_desc")
    done < <(lshw -short -class display -class network -class multimedia -class storage 2>/dev/null | awk 'NR>1 {print $4"|"$2" "$3}')

    # Si la auditoría de hardware falla, recurrimos a lsmod
    if [ ${#drivers[@]} -eq 0 ]; then
        echo "⚠️ No se pudieron obtener los detalles del hardware. Mostrando solo los módulos del kernel."
        while IFS= read -r line; do
            local module_name=$(echo "$line" | awk '{print $1}')
            local description="Módulo de kernel cargado"
            drivers+=("$module_name|$description")
        done < <(lsmod | awk 'NR>1 {print $1}')
    fi

    # Imprimir el encabezado y el contenido de la tabla
    print_table "${drivers[@]}"
}

# Auditoría para sistemas basados en FreeBSD
audit_freebsd_drivers() {
    echo "Detectando sistema: FreeBSD. Usando kldstat."

    if ! command -v kldstat &> /dev/null; then
        echo "🚫 ERROR: El comando 'kldstat' no está disponible. ¿Es este un sistema FreeBSD?" >&2
        return 1
    fi

    local drivers=()
    local kld_output=$(kldstat)
    
    if [ -z "$kld_output" ]; then
        echo "No se encontraron módulos de kernel cargados."
        return 0
    fi

    # Procesar la salida de kldstat
    while IFS= read -r line; do
        local driver_name=$(echo "$line" | awk '{print $5}')
        local description="Módulo de kernel cargado"
        drivers+=("$driver_name|$description")
    done < <(echo "$kld_output" | awk 'NR>1 {print $0}')

    # Imprimir el encabezado y el contenido de la tabla
    print_table "${drivers[@]}"
}

# --- Funciones de Formato ---

print_table() {
    local entries=("$@")

    if [ ${#entries[@]} -eq 0 ]; then
        echo "No se encontraron controladores en el sistema."
        echo "======================================================================================="
        echo "✅ Auditoría completada."
        return 0
    fi
    
    # Paso 1: Determinar el ancho máximo de las columnas
    local max_driver_len=15
    local max_device_len=25
    
    for entry in "${entries[@]}"; do
        IFS='|' read -r driver device <<< "$entry"
        if [ ${#driver} -gt "$max_driver_len" ]; then max_driver_len=${#driver}; fi
        if [ ${#device} -gt "$max_device_len" ]; then max_device_len=${#device}; fi
    done
    
    # Añadir un buffer para la legibilidad de las columnas
    max_driver_len=$((max_driver_len + 2))
    max_device_len=$((max_device_len + 2))
    
    # Paso 2: Imprimir el encabezado de la tabla
    printf "%-${max_driver_len}s | %-${max_device_len}s | %s\n" "Controlador" "Dispositivo" "Descripción"
    
    # Construir la línea de separación
    local sep_driver=$(printf '%.0s-' $(seq 1 $max_driver_len))
    local sep_device=$(printf '%.0s-' $(seq 1 $max_device_len))
    printf "%s | %s | %s\n" "$sep_driver" "$sep_device" "---------------------"
    
    # Paso 3: Auditar e imprimir la información de cada controlador
    for entry in "${entries[@]}"; do
        IFS='|' read -r driver device <<< "$entry"
        printf "%-${max_driver_len}s | %-${max_device_len}s | %s\n" "$driver" "$device" "Controlador cargado"
    done

    echo "======================================================================================="
    echo "✅ Auditoría completada."
}

# --- Lógica principal del script ---

main() {
    echo "======================================================================================="
    echo "        Análisis de Controladores y Módulos del Sistema"
    echo "======================================================================================="
    echo ""

    local os_id=""

    # Detectar el sistema operativo
    if [ -f /etc/os-release ]; then
        os_id=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    else
        echo "🚫 No se pudo detectar el sistema operativo. Usando 'Linux' como fallback."
        os_id="linux"
    fi

    case "$os_id" in
        debian|ubuntu|linuxmint|kali|centos|rhel|fedora|arch|manjaro|opensuse-leap|opensuse-tumbleweed)
            audit_linux_drivers
            ;;
        freebsd)
            audit_freebsd_drivers
            ;;
        *)
            echo "🚫 ERROR: Sistema operativo no soportado. Soportados: Linux (en sus principales variantes) y FreeBSD." >&2
            exit 1
            ;;
    esac
}

# Ejecutar la función principal
main

