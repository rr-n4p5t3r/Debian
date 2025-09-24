#!/bin/bash

# ==================================================
# Auditor de Archivos de Configuración Críticos
# Desarrollado por Ricardo Rosero
# ==================================================

# Habilitar el modo de depuración y salir si un comando falla
set -e
trap 'echo "🚫 Error: El script ha fallado en la línea $LINENO." >&2; exit 1' ERR

# --- Funciones de Auditoría ---

audit_config_files() {
    echo "Verificando permisos de archivos críticos..."
    
    local files=(
        "/etc/passwd"
        "/etc/shadow"
        "/etc/group"
        "/etc/sudoers"
        "/etc/crontab"
        "/etc/ssh/sshd_config"
    )
    
    local results=()
    local is_secure="✅ Seguro"
    
    for file in "${files[@]}"; do
        if [ ! -f "$file" ]; then
            results+=("$file|❌ No existe|No aplica")
            continue
        fi
        
        local owner=$(stat -c "%U" "$file")
        local perms=$(stat -c "%a" "$file")
        
        is_secure="✅ Seguro"
        
        # Reglas de seguridad
        case "$file" in
            "/etc/passwd")
                if [ "$perms" != "644" ]; then is_secure="⚠️ Permisos inseguros ($perms)"; fi
                if [ "$owner" != "root" ]; then is_secure="⚠️ Propietario inseguro ($owner)"; fi
                ;;
            "/etc/shadow")
                if [ "$perms" != "000" ] && [ "$perms" != "600" ] ; then is_secure="❌ Muy inseguro ($perms)"; fi
                if [ "$owner" != "root" ]; then is_secure="⚠️ Propietario inseguro ($owner)"; fi
                ;;
            "/etc/group")
                if [ "$perms" != "644" ]; then is_secure="⚠️ Permisos inseguros ($perms)"; fi
                if [ "$owner" != "root" ]; then is_secure="⚠️ Propietario inseguro ($owner)"; fi
                ;;
            "/etc/sudoers")
                if [ "$perms" != "440" ]; then is_secure="❌ Muy inseguro ($perms)"; fi
                if [ "$owner" != "root" ]; then is_secure="⚠️ Propietario inseguro ($owner)"; fi
                ;;
            "/etc/crontab")
                if [ "$perms" != "600" ] && [ "$perms" != "644" ]; then is_secure="⚠️ Permisos inseguros ($perms)"; fi
                if [ "$owner" != "root" ]; then is_secure="⚠️ Propietario inseguro ($owner)"; fi
                ;;
            "/etc/ssh/sshd_config")
                if [ "$perms" != "600" ]; then is_secure="⚠️ Permisos inseguros ($perms)"; fi
                if [ "$owner" != "root" ]; then is_secure="⚠️ Propietario inseguro ($owner)"; fi
                ;;
            *)
                is_secure="N/A" # No aplica
                ;;
        esac
        
        results+=("$file|$perms|$owner|$is_secure")
    done
    
    print_config_table "${results[@]}"
}

# --- Funciones de Formato ---

print_config_table() {
    local entries=("$@")

    echo "======================================================================================="
    echo "        Análisis de Archivos de Configuración Críticos"
    echo "======================================================================================="
    echo ""
    
    if [ ${#entries[@]} -eq 0 ]; then
        echo "No se encontraron archivos de configuración críticos."
        echo "======================================================================================="
        echo "✅ Auditoría completada."
        return 0
    fi
    
    # Paso 1: Determinar el ancho máximo de las columnas
    local max_file_len=25
    local max_perms_len=10
    local max_owner_len=10
    local max_status_len=30
    
    for entry in "${entries[@]}"; do
        IFS='|' read -r file perms owner status <<< "$entry"
        if [ ${#file} -gt "$max_file_len" ]; then max_file_len=${#file}; fi
        if [ ${#perms} -gt "$max_perms_len" ]; then max_perms_len=${#perms}; fi
        if [ ${#owner} -gt "$max_owner_len" ]; then max_owner_len=${#owner}; fi
        if [ ${#status} -gt "$max_status_len" ]; then max_status_len=${#status}; fi
    done
    
    # Añadir un buffer
    max_file_len=$((max_file_len + 2))
    max_perms_len=$((max_perms_len + 2))
    max_owner_len=$((max_owner_len + 2))
    max_status_len=$((max_status_len + 2))

    # Paso 2: Imprimir el encabezado
    printf "%-${max_file_len}s | %-${max_perms_len}s | %-${max_owner_len}s | %s\n" "Archivo" "Permisos" "Propietario" "Estado de Seguridad"
    
    # Construir la línea de separación
    local sep_file=$(printf '%.0s-' $(seq 1 $max_file_len))
    local sep_perms=$(printf '%.0s-' $(seq 1 $max_perms_len))
    local sep_owner=$(printf '%.0s-' $(seq 1 $max_owner_len))
    local sep_status=$(printf '%.0s-' $(seq 1 $max_status_len))
    printf "%s | %s | %s | %s\n" "$sep_file" "$sep_perms" "$sep_owner" "$sep_status"
    
    # Paso 3: Imprimir los resultados
    for entry in "${entries[@]}"; do
        IFS='|' read -r file perms owner status <<< "$entry"
        printf "%-${max_file_len}s | %-${max_perms_len}s | %-${max_owner_len}s | %s\n" "$file" "$perms" "$owner" "$status"
    done

    echo "======================================================================================="
    echo "✅ Auditoría completada."
}

# --- Lógica principal del script ---

main() {
    audit_config_files
}

# Ejecutar la función principal
main

