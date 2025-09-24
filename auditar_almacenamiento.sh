#!/bin/bash

# ==================================================
# Auditor de Almacenamiento del Sistema
# Desarrollado por Ricardo Rosero
# ==================================================

# Habilitar el modo de depuración y salir si un comando falla
set -e
trap 'echo "🚫 Error: El script ha fallado en la línea $LINENO." >&2; exit 1' ERR

# --- Funciones de Auditoría ---

audit_disk_usage() {
    echo "Analizando uso de disco por partición..."
    
    # Comprobar si los comandos 'df' y 'du' están disponibles
    if ! command -v df &> /dev/null; then
        echo "🚫 ERROR: El comando 'df' no está disponible. Instálelo para continuar." >&2
        return 1
    fi
    
    if ! command -v du &> /dev/null; then
        echo "🚫 ERROR: El comando 'du' no está disponible. Instálelo para continuar." >&2
        return 1
    fi

    # Imprimir el uso de disco por partición
    echo ""
    echo "--------------------------------------------------------"
    echo "--- Uso de Disco por Partición ---"
    echo "--------------------------------------------------------"
    df -h | column -t
    
    echo ""
    echo "--------------------------------------------------------"
    echo "--- 🔟 Directorios Principales en el Directorio Actual ---"
    echo "--------------------------------------------------------"
    # Analizar los 10 directorios más grandes en la ubicación actual
    du -h --max-depth=1 | sort -rh | head -n 10
}

# --- Lógica principal del script ---

main() {
    echo "======================================================================================="
    echo "        Auditoría de Almacenamiento del Sistema"
    echo "======================================================================================="
    
    audit_disk_usage
    
    echo "======================================================================================="
    echo "✅ Auditoría completada."
}

# Ejecutar la función principal
main

