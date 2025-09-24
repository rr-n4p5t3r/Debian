#!/bin/bash

# ==================================================
# Script de optimización de CPU
# Desarrollado por Ricardo Rosero
# ==================================================

# Habilitar el modo de depuración y salir si un comando falla
set -e
trap 'echo "🚫 Error: El script ha fallado en la línea $LINENO." >&2; exit 1' ERR

# --- Umbrales y configuración ---
readonly CPU_KILL_THRESHOLD=80      # Porcentaje de CPU para terminar procesos
readonly CPU_RENICE_THRESHOLD=50    # Porcentaje de CPU para cambiar prioridad
readonly WHITELIST=("systemd" "bash" "sshd" "nginx" "mysqld" "apache2" "php" "mariadb" "oracle" "postgresql" "tomcat" "cron" "NetworkManager" "wpa_supplicant" "dhclient")
readonly SERVICE_WHITELIST=("cups" "ntp" "cron" "rsync" "systemd-timesyncd" "anacron")

# --- Funciones de utilidad ---

# Verificar si el script se está ejecutando como root
check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "🚫 Este script debe ejecutarse con privilegios de root (sudo) para funcionar correctamente."
        exit 1
    fi
}

# --- Lógica principal del script ---
main() {
    check_root

    echo "Iniciando optimización de CPU..."
    echo "---------------------------------------------------"

    # 1. Identificar y finalizar procesos que consumen demasiada CPU (> 80%)
    echo "🔍 Finalizando procesos con más del $CPU_KILL_THRESHOLD% de CPU..."
    
    ps aux --sort=-%cpu | awk -v threshold="$CPU_KILL_THRESHOLD" '$3 > threshold {print $2, $11}' | while read PID PROC_NAME; do
        local is_whitelisted=false
        for excluded in "${WHITELIST[@]}"; do
            if [[ "$PROC_NAME" == *"$excluded"* ]]; then
                is_whitelisted=true
                break
            fi
        done

        if [[ "$is_whitelisted" == "true" ]]; then
            echo "   ⏩ Saltando proceso en lista blanca: $PROC_NAME (PID: $PID)"
            continue
        fi
        
        echo "   🚨 Intentando terminar amigablemente: $PROC_NAME (PID: $PID)"
        if kill -15 "$PID" &>/dev/null; then
            sleep 2 # Esperar 2 segundos para un cierre seguro
            if ! kill -0 "$PID" &>/dev/null; then
                echo "   ✅ El proceso fue terminado correctamente."
            else
                echo "   ❌ El proceso no respondió. Forzando terminación con SIGKILL..."
                kill -9 "$PID" &>/dev/null || true # Ignorar errores si el proceso ya no existe
                echo "   ✅ Proceso terminado con SIGKILL."
            fi
        else
            echo "   ❌ Error al intentar terminar el proceso $PROC_NAME (PID: $PID)."
        fi
    done

    # 2. Reducir la prioridad de procesos intensivos de CPU (> 50%)
    echo "---------------------------------------------------"
    echo "📉 Ajustando la prioridad de procesos intensivos..."
    
    ps aux --sort=-%cpu | awk -v threshold="$CPU_RENICE_THRESHOLD" '$3 > threshold {print $2, $11}' | while read PID PROC_NAME; do
        local is_whitelisted=false
        for excluded in "${WHITELIST[@]}"; do
            if [[ "$PROC_NAME" == *"$excluded"* ]]; then
                is_whitelisted=true
                break
            fi
        done

        if [[ "$is_whitelisted" == "true" ]]; then
            echo "   ⏩ Saltando proceso en lista blanca: $PROC_NAME (PID: $PID)"
            continue
        fi

        echo "   ⚙️  Cambiando prioridad del proceso: $PROC_NAME (PID: $PID)"
        renice +10 "$PID" &>/dev/null || echo "   ❌ No se pudo ajustar la prioridad."
    done

    # 3. Establecer el modo de CPU en 'powersave' para reducir el consumo
    echo "---------------------------------------------------"
    echo "🌿 Configurando la CPU en modo de ahorro de energía..."
    if ! command -v cpufreq-set &> /dev/null; then
        echo "   ⚠️  cpufreq-set no está instalado. Omite este paso. Por favor, instale el paquete 'cpufrequtils'."
    else
        cpufreq-set -g powersave
        echo "   ✅ La CPU se ha configurado en modo 'powersave'."
    fi

    # 4. Detener servicios no esenciales
    echo "---------------------------------------------------"
    echo "🛑 Deteniendo servicios no esenciales..."
    
    # La lista de servicios se obtiene dinámicamente o se define en la constante SERVICE_WHITELIST
    # Nota: Detener servicios de forma indiscriminada puede ser peligroso.
    # Esta es una lista de ejemplo.
    local services_to_stop=("bluetooth" "cups" "cups-browsed")

    for service in "${services_to_stop[@]}"; do
        local is_whitelisted=false
        for excluded in "${SERVICE_WHITELIST[@]}"; do
            if [[ "$service" == "$excluded" ]]; then
                is_whitelisted=true
                break
            fi
        done

        if [[ "$is_whitelisted" == "true" ]]; then
            echo "   ⏩ Saltando servicio en lista blanca: $service"
            continue
        fi
        
        echo "   Stopping service: $service"
        if sudo systemctl stop "$service" &>/dev/null; then
            echo "   ✅ Servicio $service detenido."
        else
            echo "   ❌ Error al detener el servicio $service."
        fi
    done
    
    echo "---------------------------------------------------"
    echo "✅ Optimización completada."
}

main

