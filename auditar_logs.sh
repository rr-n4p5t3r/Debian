#!/bin/bash

# ==================================================
# Auditor de Archivos de Registro (Logs) del Sistema
# Desarrollado por Ricardo Rosero
# ==================================================

# Habilitar el modo de depuración y salir si un comando falla
set -e
trap 'echo "🚫 Error: El script ha fallado en la línea $LINENO." >&2; exit 1' ERR

# --- Lógica principal del script ---

main() {
    echo "======================================================================================="
    echo "        Análisis de Archivos de Registro (Logs) del Sistema"
    echo "======================================================================================="

    # Define la lista de logs comunes a auditar
    # Formato: "Aplicacion|Tipo|Ruta"
    local log_files=(
        "Sistema|Auth|/var/log/auth.log"
        "Sistema|Syslog|/var/log/syslog"
        "Sistema|Kern|/var/log/kern.log"
        "Sistema|Dmesg|/var/log/dmesg"
        "Servidor Web|Apache Access|/var/log/apache2/access.log"
        "Servidor Web|Apache Error|/var/log/apache2/error.log"
        "Servidor Web|Nginx Access|/var/log/nginx/access.log"
        "Servidor Web|Nginx Error|/var/log/nginx/error.log"
        "Firewall|UFW|/var/log/ufw.log"
        "Correo|Mail|/var/log/mail.log"
        "Base de Datos|MySQL Error|/var/log/mysql/error.log"
        "Base de Datos|Postgresql|/var/log/postgresql/postgresql-*.log"
    )

    # Paso 1: Determinar el ancho máximo para el formato de tabla
    local max_app_len=15
    local max_type_len=15
    local max_path_len=40

    for entry in "${log_files[@]}"; do
        IFS='|' read -r app type path <<< "$entry"
        if [ ${#app} -gt "$max_app_len" ]; then max_app_len=${#app}; fi
        if [ ${#type} -gt "$max_type_len" ]; then max_type_len=${#type}; fi
        if [ ${#path} -gt "$max_path_len" ]; then max_path_len=${#path}; fi
    done
    
    # Añadir un buffer al ancho de las columnas
    max_app_len=$((max_app_len + 2))
    max_type_len=$((max_type_len + 2))
    max_path_len=$((max_path_len + 2))

    # Paso 2: Imprimir el encabezado de la tabla
    printf "%-${max_app_len}s | %-${max_type_len}s | %-${max_path_len}s | %s\n" "Aplicación" "Tipo de Log" "Ruta" "Tamaño (Bytes)"
    
    # Construir la línea de separación
    local sep_app=$(printf '%.0s-' $(seq 1 $max_app_len))
    local sep_type=$(printf '%.0s-' $(seq 1 $max_type_len))
    local sep_path=$(printf '%.0s-' $(seq 1 $max_path_len))
    printf "%s | %s | %s | %s\n" "$sep_app" "$sep_type" "$sep_path" "----------------"
    
    # Paso 3: Auditar e imprimir la información de cada log
    for entry in "${log_files[@]}"; do
        IFS='|' read -r app type path <<< "$entry"

        # Expandir comodines (globbing) para rutas como postgresql-*.log
        for file in $path; do
            if [ -e "$file" ]; then
                local file_size=$(du -b "$file" | cut -f1)
                printf "%-${max_app_len}s | %-${max_type_len}s | %-${max_path_len}s | %s\n" "$app" "$type" "$file" "$file_size"
            else
                printf "%-${max_app_len}s | %-${max_type_len}s | %-${max_path_len}s | %s\n" "$app" "$type" "$file" "🚫 No encontrado"
            fi
        done
    done

    echo "======================================================================================="
    echo "✅ Auditoría de logs completada."
}

# Ejecutar la función principal
main

