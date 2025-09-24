#!/bin/bash

# ==============================
# Script de mantenimiento mejorado para Linux
# Desarrollado por Ricardo Rosero
# ==============================

# Habilitar el modo de depuración y salir si un comando falla
set -e
trap 'echo "🚫 Error: El script ha fallado en la línea $LINENO." >&2; exit 1' ERR

# --- Funciones de utilidad ---

function print_header() {
    clear
    echo "======================================="
    echo "       Script de Mantenimiento"
    echo "======================================="
}

function get_disk_space() {
    # Usar 'du -B1 --apparent-size' es más preciso para la limpieza
    # y /var/tmp puede contener archivos temporales importantes
    du -shc /tmp /var/tmp ~/.cache ~/.local/share/Trash/*-Trash/* 2>/dev/null | tail -n1 | awk '{print $1}'
}

function bytes_to_human() {
    local bytes=$1
    local suffixes=("B" "KiB" "MiB" "GiB" "TiB")
    local suffix=0

    # Usar un bucle para una conversión más precisa
    while (( $(echo "$bytes >= 1024" | bc -l) )) && (( $suffix < ${#suffixes[@]} )); do
        bytes=$(echo "$bytes / 1024" | bc -l)
        ((suffix++))
    done
    printf "%.1f %s\n" "$bytes" "${suffixes[$suffix]}"
}

# --- Funciones de limpieza ---

function clean_user_files() {
    echo "✅ Limpiando archivos temporales y caché de usuario..."
    rm -rf /tmp/* ~/.cache/* 2>/dev/null || true # Ignorar errores
    find /var/tmp -mindepth 1 -delete 2>/dev/null || true # Más seguro
    echo "Archivos temporales y de caché eliminados."
}

function clean_apt_cache() {
    echo "✅ Limpiando paquetes y cachés de APT..."
    apt autoremove --purge -y
    apt clean
    apt autoclean
    echo "Caché de APT y paquetes obsoletos eliminados."
}

function clean_system_logs() {
    echo "✅ Limpiando archivos de log antiguos..."
    journalctl --vacuum-time=7d
    find /var/log -type f -name "*.log" -delete || true # Ignorar errores
    echo "Logs del sistema eliminados."
}

function clean_recent_history() {
    echo "✅ Eliminando historial de archivos recientes..."
    # Eliminar archivos que pueden no existir
    rm -f ~/.local/share/recently-used.xbel ~/.local/share/kactivitymanagerd/resources/* 2>/dev/null || true
    
    # === CORRECCIÓN CLAVE ===
    # Comprobar si el archivo de LibreOffice existe antes de ejecutar 'sed'.
    local libreoffice_file="$HOME/.config/libreoffice/4/user/registrymodifications.xcu"
    if [ -f "$libreoffice_file" ]; then
        sed -i '/PickList/d' "$libreoffice_file"
    else
        echo "   (El archivo de LibreOffice no se encontró, omitiendo la limpieza)"
    fi
    # ========================

    echo "Historial eliminado."
}

# --- Menú y lógica principal ---

if [[ $EUID -ne 0 ]]; then
   echo "🚫 Este script debe ejecutarse con privilegios de root para la limpieza del sistema."
   echo "Algunas funciones de limpieza de usuario podrían fallar sin 'sudo'."
fi

while true; do
    print_header
    echo "1) Limpiar archivos temporales de usuario"
    echo "2) Limpiar caché y paquetes de APT"
    echo "3) Limpiar logs del sistema"
    echo "4) **Ejecutar todo el mantenimiento**"
    echo "5) Borrar historial de archivos recientes"
    echo "0) Salir"
    echo "---------------------------------------"
    read -rp "Seleccione una opción: " opcion

    # Medir el espacio antes de la operación
    local_space_before=$(df -k --output=avail / | tail -n 1)

    case $opcion in
        1) clean_user_files ;;
        2) clean_apt_cache ;;
        3) clean_system_logs ;;
        4)
            echo "--- Ejecutando todas las tareas de mantenimiento ---"
            clean_user_files
            clean_apt_cache
            clean_system_logs
            clean_recent_history
            ;;
        5) clean_recent_history ;;
        0) echo "Saliendo..."; exit 0 ;;
        *) echo "Opción inválida. Intente de nuevo." ;;
    esac

    # Medir el espacio después y calcular lo recuperado
    local_space_after=$(df -k --output=avail / | tail -n 1)
    space_recovered=$((local_space_after - local_space_before))

    if (( space_recovered > 0 )); then
        echo "✅ Espacio recuperado en esta operación: $(bytes_to_human "$space_recovered")"
    else
        echo "No se recuperó espacio en esta operación."
    fi

    read -rp "Presione Enter para continuar..." pause
done

