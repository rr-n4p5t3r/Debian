#!/bin/bash

# ==================================================
# Auditor de Aplicaciones Instaladas
# Desarrollado por Ricardo Rosero
# ==================================================

# Habilitar el modo de depuración y salir si un comando falla
set -e
trap 'echo "🚫 Error: El script ha fallado en la línea $LINENO." >&2; exit 1' ERR

# --- Funciones de Auditoría por Gestor de Paquetes ---

# Auditoría para sistemas basados en Debian (apt/dpkg)
audit_debian() {
    echo "Detectando sistema: Debian/Ubuntu/Mint. Usando dpkg."
    if ! command -v dpkg-query &> /dev/null; then
        echo "🚫 ERROR: El comando 'dpkg-query' no está disponible. ¿Es este un sistema basado en Debian?" >&2
        return 1
    fi
    dpkg-query -W -f='${Package}|${Version}\n' | sort -V
}

# Auditoría para sistemas basados en Red Hat (rpm)
audit_rhel() {
    echo "Detectando sistema: Red Hat/CentOS/Fedora. Usando rpm."
    if ! command -v rpm &> /dev/null; then
        echo "🚫 ERROR: El comando 'rpm' no está disponible. ¿Es este un sistema basado en RHEL?" >&2
        return 1
    fi
    rpm -qa --qf '%{NAME}|%{VERSION}\n' | sort -V
}

# Auditoría para sistemas basados en Arch (pacman)
audit_arch() {
    echo "Detectando sistema: Arch Linux. Usando pacman."
    if ! command -v pacman &> /dev/null; then
        echo "🚫 ERROR: El comando 'pacman' no está disponible. ¿Es este un sistema basado en Arch?" >&2
        return 1
    fi
    pacman -Q | awk '{print $1"|"$2}' | sort -V
}

# Auditoría para sistemas basados en openSUSE (zypper)
audit_suse() {
    echo "Detectando sistema: openSUSE. Usando zypper."
    if ! command -v zypper &> /dev/null; then
        echo "🚫 ERROR: El comando 'zypper' no está disponible. ¿Es este un sistema basado en openSUSE?" >&2
        return 1
    fi
    zypper se --installed-only --no-refresh | awk '{print $3"|"$4}' | sed '1,2d'
}

# Auditoría para sistemas basados en FreeBSD (pkg)
audit_freebsd() {
    echo "Detectando sistema: FreeBSD. Usando pkg."
    if ! command -v pkg &> /dev/null; then
        echo "🚫 ERROR: El comando 'pkg' no está disponible. ¿Es este un sistema basado en FreeBSD?" >&2
        return 1
    fi
    pkg info | awk '{print $1}' | sed 's/-|/|/g'
}

# --- Lógica principal del script ---

main() {
    echo "======================================================================================="
    echo "        Análisis de Aplicaciones Instaladas en el Sistema"
    echo "======================================================================================="
    echo ""

    local installed_apps=()
    local os_id=""
    local pkg_manager_name=""

    # Detectar el sistema operativo
    if [ -f /etc/os-release ]; then
        os_id=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    else
        echo "🚫 No se pudo detectar el sistema operativo. Usando 'dpkg' como fallback."
        os_id="debian"
    fi

    case "$os_id" in
        debian|ubuntu|linuxmint|kali)
            installed_apps=($(audit_debian))
            pkg_manager_name="dpkg"
            ;;
        centos|rhel|fedora)
            installed_apps=($(audit_rhel))
            pkg_manager_name="rpm"
            ;;
        arch|manjaro)
            installed_apps=($(audit_arch))
            pkg_manager_name="pacman"
            ;;
        opensuse-leap|opensuse-tumbleweed)
            installed_apps=($(audit_suse))
            pkg_manager_name="zypper"
            ;;
        freebsd)
            installed_apps=($(audit_freebsd))
            pkg_manager_name="pkg"
            ;;
        *)
            echo "🚫 ERROR: Sistema operativo no soportado. Motores soportados: Debian, Red Hat, Arch, openSUSE, FreeBSD." >&2
            exit 1
            ;;
    esac
    
    if [ ${#installed_apps[@]} -eq 0 ]; then
        echo "No se encontraron aplicaciones instaladas."
        echo "======================================================================================="
        echo "✅ Auditoría completada."
        return 0
    fi

    # Paso 1: Determinar el ancho máximo de las columnas
    local max_app_len=15
    local max_ver_len=15
    local max_pkg_len=15

    for entry in "${installed_apps[@]}"; do
        IFS='|' read -r app version <<< "$entry"
        if [ ${#app} -gt "$max_app_len" ]; then max_app_len=${#app}; fi
        if [ ${#version} -gt "$max_ver_len" ]; then max_ver_len=${#version}; fi
    done
    
    # Añadir un buffer para la legibilidad de las columnas
    max_app_len=$((max_app_len + 2))
    max_ver_len=$((max_ver_len + 2))
    
    # Paso 2: Imprimir el encabezado de la tabla
    printf "%-${max_app_len}s | %-${max_ver_len}s | %-${max_pkg_len}s\n" "Aplicación" "Versión" "Gestor de Paquetes"
    
    # Construir la línea de separación
    local sep_app=$(printf '%.0s-' $(seq 1 $max_app_len))
    local sep_ver=$(printf '%.0s-' $(seq 1 $max_ver_len))
    local sep_pkg=$(printf '%.0s-' $(seq 1 $max_pkg_len))
    printf "%s | %s | %s\n" "$sep_app" "$sep_ver" "$sep_pkg"
    
    # Paso 3: Auditar e imprimir la información de cada aplicación
    for entry in "${installed_apps[@]}"; do
        IFS='|' read -r app version <<< "$entry"
        printf "%-${max_app_len}s | %-${max_ver_len}s | %-${max_pkg_len}s\n" "$app" "$version" "$pkg_manager_name"
    done

    echo "======================================================================================="
    echo "✅ Auditoría completada."
}

# Ejecutar la función principal
main

