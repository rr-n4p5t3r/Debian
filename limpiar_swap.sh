#!/bin/bash

# ==================================================
# Script para limpiar la swap en Linux
# Desarrollado por Ricardo Rosero
# ==================================================

# Habilitar el modo de depuración y salir si un comando falla
set -e
trap 'echo "🚫 Error: El script ha fallado en la línea $LINENO." >&2; exit 1' ERR

# --- Funciones ---

# Verificar si el script se está ejecutando como root
check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "🚫 Este script debe ejecutarse con privilegios de root (sudo) para funcionar correctamente."
        exit 1
    fi
}

# Mostrar el estado actual de la swap
show_swap_status() {
    echo "Estado actual de la memoria:"
    free -h | grep "Swap"
    echo ""
}

# --- Lógica principal ---

main() {
    check_root

    echo "Limpiando la memoria de intercambio (swap)..."
    echo "---------------------------------------------------"
    
    # Mostrar el estado antes de la limpieza
    show_swap_status
    
    # Desactivar la swap
    echo "Desactivando la swap..."
    if ! swapoff -a; then
        echo "🚫 Error: No se pudo desactivar la swap. Verifique los permisos o si hay errores en el sistema."
        exit 1
    fi

    # Activar la swap nuevamente
    echo "Reactivando la swap..."
    if ! swapon -a; then
        echo "🚫 Error: No se pudo activar la swap. Verifique los permisos o si hay errores en el sistema."
        exit 1
    fi
    
    echo "---------------------------------------------------"
    echo "✅ Swap limpiada con éxito. Nuevo estado de la memoria:"
    show_swap_status
}

# Ejecutar la función principal
main

