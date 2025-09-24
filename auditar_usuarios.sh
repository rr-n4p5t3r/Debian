#!/bin/bash

# ==================================================
# Auditor de Usuarios y Permisos en el Sistema
# Desarrollado por Ricardo Rosero
# ==================================================

# Habilitar el modo de depuración y salir si un comando falla
set -e
trap 'echo "🚫 Error: El script ha fallado en la línea $LINENO." >&2; exit 1' ERR

# --- Funciones de utilidad ---

function get_user_list() {
    # Excluye usuarios del sistema
    cut -d: -f1 /etc/passwd | grep -E '^[^_]'
}

function is_sudoer() {
    # Verifica si el usuario pertenece al grupo sudo o wheel
    # La salida se redirige a /dev/null para evitar mensajes en la pantalla
    groups "$1" | grep -qE '\bsudo\b|\bwheel\b'
}

# --- Lógica principal del script ---

main() {
    echo "======================================================================================="
    echo "                 Análisis de Usuarios y Permisos del Sistema"
    echo "======================================================================================="
    
    # Obtener la lista de usuarios y ordenar alfabéticamente
    local users
    readarray -t users < <(get_user_list | sort)

    # Paso 1: Obtener la longitud máxima de los grupos para ajustar el formato de la tabla
    local max_group_len=40 # Ancho mínimo de la columna
    for user in "${users[@]}"; do
        local groups
        groups=$(groups "$user" 2>/dev/null)
        local groups_clean="${groups#*:}"
        local current_len=${#groups_clean}
        if [[ $current_len -gt $max_group_len ]]; then
            max_group_len=$current_len
        fi
    done

    # Paso 2: Imprimir el encabezado de la tabla con el ancho dinámico
    printf "%-20s | %-${max_group_len}s | %-12s | %s\n" "Usuario" "Grupos" "Permisos" "Directorio de Inicio"
    
    # Construir la línea de separación dinámicamente para evitar el error de printf
    local separator="---------------------|-"
    for ((i=0; i<max_group_len; i++)); do
        separator+="-"
    done
    separator+="|--------------|------------------------------"
    printf "%s\n" "$separator"

    # Paso 3: Imprimir la información de cada usuario
    for user in "${users[@]}"; do
        # Obtener los grupos del usuario
        local groups
        groups=$(groups "$user" 2>/dev/null)
        local groups_clean="${groups#*:}"
        
        # Verificar si el usuario es sudoer
        local is_sudo="❌ No es SUDOER"
        if is_sudoer "$user"; then
            is_sudo="✅ SUDOER"
        fi

        # Obtener el directorio de inicio del usuario
        local home_dir
        home_dir=$(getent passwd "$user" | cut -d: -f6)
        
        # Imprimir la fila de la tabla
        printf "%-20s | %-${max_group_len}s | %-12s | %s\n" "$user" "$groups_clean" "$is_sudo" "$home_dir"
    done
    
    echo "======================================================================================="
    echo "✅ Auditoría completada."
}

# Ejecutar la función principal
main

