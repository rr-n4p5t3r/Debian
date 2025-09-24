#!/bin/bash

# ==============================
# Script de mantenimiento para Linux con medición de espacio
# Desarrollado por Ricardo Rosero - rrosero2000@gmail.com
# Github: rr-n4p5t3r
# ==============================

function obtener_espacio() {
    df --output=avail / | tail -n 1
}

function bytes_a_humanos() {
    num=$1
    if (( num < 1024 )); then
        echo "${num}K"
    elif (( num < 1048576 )); then
        echo "$((num/1024))M"
    else
        echo "$((num/1024/1024))G"
    fi
}

function limpiar_temp() {
    echo "Limpiando archivos temporales..."
    espacio_inicial=$(obtener_espacio)

    rm -rf /tmp/* ~/.cache/* 2>/dev/null

    espacio_final=$(obtener_espacio)
    espacio_recuperado=$((espacio_final - espacio_inicial))
    echo "Espacio recuperado: $(bytes_a_humanos "$espacio_recuperado")"
    echo
}

function limpiar_apt() {
    echo "Limpiando paquetes obsoletos y cachés de APT..."
    espacio_inicial=$(obtener_espacio)

    sudo apt clean
    sudo apt autoremove -y
    sudo apt autoclean

    espacio_final=$(obtener_espacio)
    espacio_recuperado=$((espacio_final - espacio_inicial))
    echo "Espacio recuperado: $(bytes_a_humanos "$espacio_recuperado")"
    echo
}

function limpiar_logs() {
    echo "Limpiando archivos de log antiguos..."
    espacio_inicial=$(obtener_espacio)

    sudo find /var/log -type f -name "*.log" -delete

    espacio_final=$(obtener_espacio)
    espacio_recuperado=$((espacio_final - espacio_inicial))
    echo "Espacio recuperado: $(bytes_a_humanos "$espacio_recuperado")"
    echo
}

function limpiar_recientes() {
    echo "Eliminando historial de archivos recientes..."
    rm -f ~/.local/share/recently-used.xbel
    rm -rf ~/.local/share/kactivitymanagerd/resources/*
    sed -i '/PickList/d' ~/.config/libreoffice/4/user/registrymodifications.xcu
    echo "Historial eliminado."
}


function mostrar_menu() {
    clear
    echo "======================================="
    echo "    Script de Mantenimiento del Sistema"
    echo "======================================="
    echo "1) Limpiar archivos temporales"
    echo "2) Limpiar caché de APT"
    echo "3) Limpiar logs del sistema"
    echo "4) Ejecutar todo el mantenimiento"
    echo "5) Borrar historial de archivos recientes"
    echo "0) Salir"
    echo "---------------------------------------"
    read -rp "Seleccione una opción: " opcion
}

while true; do
    mostrar_menu
    case $opcion in
        1) limpiar_temp ;;
        2) limpiar_apt ;;
        3) limpiar_logs ;;
        4)
            espacio_total_inicial=$(obtener_espacio)
            limpiar_temp
            limpiar_apt
            limpiar_logs 
            limpiar_recientes 
            espacio_total_final=$(obtener_espacio)
            espacio_total_recuperado=$((espacio_total_final - espacio_total_inicial))
            echo "Espacio total recuperado: $(bytes_a_humanos "$espacio_total_recuperado")"
            ;;
        5) limpiar_recientes ;;

        0) echo "Saliendo..."; exit 0 ;;
        *) echo "Opción inválida. Intente de nuevo." ;;
    esac
    read -rp "Presione Enter para continuar..." pause
done
