#!/bin/bash

# ==================================================
# Auditor de Conexiones de Red
# Desarrollado por Ricardo Rosero
# ==================================================

# Habilitar el modo de depuración y salir si un comando falla
set -e
trap 'echo "🚫 Error: El script ha fallado en la línea $LINENO." >&2; exit 1' ERR

# --- Funciones de Auditoría ---

audit_network_connections() {
    echo "Detectando conexiones de red..."

    # Comprobar si los comandos necesarios están disponibles
    if ! command -v ip &> /dev/null; then
        echo "🚫 ERROR: El comando 'ip' no está disponible. Asegúrese de que las herramientas de red estén instaladas." >&2
        return 1
    fi

    local connections=()
    local interfaces
    readarray -t interfaces < <(ip -o link show | awk -F': ' '{print $2}')

    if [ ${#interfaces[@]} -eq 0 ]; then
        echo "No se encontraron interfaces de red en el sistema."
        return 0
    fi
    
    for iface in "${interfaces[@]}"; do
        # Obtener información de la interfaz
        local ip_info=$(ip -o -4 addr show dev "$iface" | awk '{print $4}')
        local mac_addr=$(ip -o link show dev "$iface" | awk '{print $NF}')
        local status=$(ip -o link show dev "$iface" | awk '{print $9}')
        local network_name=""

        # Determinar el tipo de conexión (WLAN o LAN) y obtener el nombre de la red
        local conn_type="Desconocido"
        if [[ "$iface" =~ ^wlan|^wlp|^wlx ]]; then
            conn_type="WLAN"
            if command -v iw &> /dev/null; then
                network_name=$(iw dev "$iface" link 2>/dev/null | grep 'SSID' | awk '{print $2}')
            fi
        elif [[ "$iface" =~ ^eth|^enp ]]; then
            conn_type="LAN"
        fi

        # Agregar la información a la lista
        connections+=("$iface|$conn_type|$ip_info|$mac_addr|$status|$network_name")
    done

    # Imprimir el encabezado y el contenido de la tabla
    print_table "${connections[@]}"
}

# --- Funciones de Formato ---

print_table() {
    local entries=("$@")

    if [ ${#entries[@]} -eq 0 ]; then
        echo "No se encontraron conexiones de red en el sistema."
        echo "======================================================================================="
        echo "✅ Auditoría completada."
        return 0
    fi
    
    # Paso 1: Determinar el ancho máximo de las columnas
    local max_iface_len=15
    local max_type_len=10
    local max_ip_len=20
    local max_mac_len=20
    local max_status_len=10
    local max_name_len=20
    
    for entry in "${entries[@]}"; do
        IFS='|' read -r iface type ip mac status name <<< "$entry"
        if [ ${#iface} -gt "$max_iface_len" ]; then max_iface_len=${#iface}; fi
        if [ ${#type} -gt "$max_type_len" ]; then max_type_len=${#type}; fi
        if [ ${#ip} -gt "$max_ip_len" ]; then max_ip_len=${#ip}; fi
        if [ ${#mac} -gt "$max_mac_len" ]; then max_mac_len=${#mac}; fi
        if [ ${#status} -gt "$max_status_len" ]; then max_status_len=${#status}; fi
        if [ ${#name} -gt "$max_name_len" ]; then max_name_len=${#name}; fi
    done
    
    # Añadir un buffer para la legibilidad de las columnas
    max_iface_len=$((max_iface_len + 2))
    max_type_len=$((max_type_len + 2))
    max_ip_len=$((max_ip_len + 2))
    max_mac_len=$((max_mac_len + 2))
    max_status_len=$((max_status_len + 2))
    max_name_len=$((max_name_len + 2))

    # Paso 2: Imprimir el encabezado de la tabla
    printf "%-${max_iface_len}s | %-${max_type_len}s | %-${max_ip_len}s | %-${max_mac_len}s | %-${max_status_len}s | %s\n" "Interfaz" "Tipo" "Dirección IP" "Dirección MAC" "Estado" "Nombre de Red"
    
    # Construir la línea de separación
    local sep_iface=$(printf '%.0s-' $(seq 1 $max_iface_len))
    local sep_type=$(printf '%.0s-' $(seq 1 $max_type_len))
    local sep_ip=$(printf '%.0s-' $(seq 1 $max_ip_len))
    local sep_mac=$(printf '%.0s-' $(seq 1 $max_mac_len))
    local sep_status=$(printf '%.0s-' $(seq 1 $max_status_len))
    local sep_name=$(printf '%.0s-' $(seq 1 $max_name_len))
    printf "%s | %s | %s | %s | %s | %s\n" "$sep_iface" "$sep_type" "$sep_ip" "$sep_mac" "$sep_status" "$sep_name"
    
    # Paso 3: Auditar e imprimir la información de cada conexión
    for entry in "${entries[@]}"; do
        IFS='|' read -r iface type ip mac status name <<< "$entry"
        printf "%-${max_iface_len}s | %-${max_type_len}s | %-${max_ip_len}s | %-${max_mac_len}s | %-${max_status_len}s | %s\n" "$iface" "$type" "$ip" "$mac" "$status" "$name"
    done

    echo "======================================================================================="
    echo "✅ Auditoría completada."
}

# --- Lógica principal del script ---

main() {
    echo "======================================================================================="
    echo "        Análisis de Conexiones de Red del Sistema"
    echo "======================================================================================="
    echo ""

    audit_network_connections
}

# Ejecutar la función principal
main

