#!/bin/bash

# ==================================================
# Ranking de comandos más utilizados
# Desarrollado por Ricardo Rosero
# ==================================================

# Habilitar el modo de depuración y salir si un comando falla
set -e
trap 'echo "🚫 Error: El script ha fallado en la línea $LINENO." >&2; exit 1' ERR

# --- Lógica principal del script ---

main() {
    # Verificar si se pasó el número de comandos a mostrar
    if [[ -z "$1" ]]; then
        echo "🚫 ERROR: Por favor, ingrese el número de comandos que desea mostrar."
        echo "Uso: $0 <número>"
        echo "Ejemplo: $0 10 (mostrará los 10 comandos más usados)"
        exit 1
    fi

    local cant="$1"

    # Validar que el argumento es un número
    if ! [[ "$cant" =~ ^[0-9]+$ ]]; then
        echo "🚫 ERROR: El argumento debe ser un número entero positivo."
        exit 1
    fi

    # Determinar la ruta correcta al archivo de historial
    local hist_file=""
    if [[ -n "$HISTFILE" && -f "$HISTFILE" ]]; then
        # Usa la variable de entorno si está definida y existe
        hist_file="$HISTFILE"
    elif [[ -n "$SUDO_USER" ]]; then
        # Si se ejecuta con sudo, usa el historial del usuario que lo llamó
        hist_file="/home/$SUDO_USER/.bash_history"
    else
        # Si se ejecuta como un usuario normal, busca en el directorio de inicio
        hist_file="$HOME/.bash_history"
    fi

    # Fallback para zsh si no se encuentra el de bash
    if [[ ! -f "$hist_file" && -f "$HOME/.zsh_history" ]]; then
        hist_file="$HOME/.zsh_history"
    fi

    # Verificación final de que el archivo existe
    if [[ ! -f "$hist_file" ]]; then
        echo "🚫 ERROR: No se encontró el archivo de historial."
        echo "Asegúrese de que la variable \$HISTFILE está configurada correctamente para su shell o que el archivo existe en una ubicación predeterminada."
        exit 1
    fi

    echo "Mis $cant comandos más utilizados:"
    echo "---------------------------------------------------"

    # Usar una combinación de comandos más eficiente
    awk '{print $1}' "$hist_file" | sort | uniq -c | sort -nr | head -n "$cant"
    
    echo "---------------------------------------------------"
    echo "✅ Proceso completado."
}

# Ejecutar la función principal
main "$@"

