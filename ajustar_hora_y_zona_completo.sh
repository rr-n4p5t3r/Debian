#!/bin/bash

# =======================================================================
# Script de configuración de hora y zona horaria
# Desarrollado por Ricardo Rosero
# =======================================================================

# Habilitar el modo de depuración y salir si un comando falla
set -e
trap 'echo "🚫 Error: El script ha fallado en la línea $LINENO." >&2; exit 1' ERR

# --- Funciones de utilidad ---

function print_header() {
    clear
    echo "======================================================================="
    echo "       Configuración de Hora y Zona Horaria"
    echo "======================================================================="
}

function check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "🚫 Este script debe ejecutarse con privilegios de root (sudo) para funcionar correctamente."
        exit 1
    fi
}

function install_packages() {
    echo "Verificando e instalando paquetes necesarios..."
    sudo apt update
    sudo apt install -y systemd-timesyncd util-linux
    echo "✅ Paquetes instalados o ya existentes."
}

function show_status() {
    print_header
    echo "Estado actual del sistema:"
    echo "-----------------------------------------------------------------------"
    timedatectl status
    echo "-----------------------------------------------------------------------"
    read -rp "Presione Enter para continuar..." pause
}

function set_timezone() {
    read -rp "Introduce la zona horaria (ej. America/Bogota): " zona_horaria
    
    if ! timedatectl list-timezones | grep -q "^$zona_horaria$"; then
        echo "🚫 Zona horaria inválida. Verifique la zona horaria ingresada."
        read -rp "Presione Enter para continuar..." pause
        return 1
    fi

    echo "Configurando la zona horaria a $zona_horaria..."
    timedatectl set-timezone "$zona_horaria"
    echo "✅ Zona horaria configurada con éxito."
    read -rp "Presione Enter para continuar..." pause
}

function sync_rtc() {
    if command -v hwclock &> /dev/null; then
        echo "Sincronizando el reloj de hardware (RTC) con la hora del sistema..."
        sudo hwclock --systohc
        echo "✅ Reloj de hardware sincronizado con éxito."
    else
        echo "🚫 hwclock no está disponible. Verifique la instalación de 'util-linux'."
    fi
    read -rp "Presione Enter para continuar..." pause
}

function enable_ntp() {
    echo "Habilitando la sincronización automática de hora (NTP)..."
    timedatectl set-ntp true
    echo "✅ Sincronización NTP habilitada. El sistema mantendrá la hora actualizada automáticamente."
    read -rp "Presione Enter para continuar..." pause
}

# --- Lógica principal ---

main() {
    check_root
    install_packages

    while true; do
        print_header
        echo "1) Ver estado actual de la hora y zona horaria"
        echo "2) Ajustar zona horaria"
        echo "3) Sincronizar la hora del sistema con el reloj de hardware (RTC)"
        echo "4) Habilitar la sincronización automática de hora (NTP)"
        echo "0) Salir"
        echo "-----------------------------------------------------------------------"
        read -rp "Seleccione una opción: " opcion

        case $opcion in
            1) show_status ;;
            2) set_timezone ;;
            3) sync_rtc ;;
            4) enable_ntp ;;
            0) echo "Saliendo..."; exit 0 ;;
            *) echo "Opción inválida. Intente de nuevo."; read -rp "Presione Enter para continuar..." pause ;;
        esac
    done
}

# Ejecutar la función principal
main

