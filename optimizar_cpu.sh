#!/bin/bash

# -----------------------------------------
# Autor: Ricardo Rosero
# Email: rrosero2000@gmail.com
# GitHub: https://github.com/rr-n4p5t3r
# 
# Descripción:
# Este script optimiza el uso de la CPU en un sistema Debian/Linux
# de manera automática. Realiza las siguientes acciones:
# 1. Identifica y finaliza amigablemente (SIGTERM) procesos que consumen más del 80% de la CPU.
#    Si el proceso no responde a SIGTERM, se usa SIGKILL como último recurso.
# 2. Ajusta la prioridad de procesos que consumen más del 50% de CPU.
# 3. Configura el gobernador de la CPU en modo 'powersave' para ahorrar energía.
# 4. Detiene servicios no esenciales, a excepción de los servicios en la lista blanca.
#
# Uso:
# Puede ejecutarse manualmente o programarse con 'cron' para su ejecución periódica.
# -----------------------------------------

# Definir lista blanca de procesos que NO deben ser finalizados
WHITELIST=("systemd" "bash" "sshd" "nginx" "mysqld" "apache2" "php" "mariadb" "oracle" "postgresql" "tomcat" "cron" "NetworkManager" "wpa_supplicant" "dhclient")

# Definir lista blanca de servicios que NO deben ser detenidos
SERVICE_WHITELIST=("cups" "ntp" "cron" "rsync" "systemd-timesyncd" "anacron")

# Función para verificar si un proceso está en la lista blanca
is_in_whitelist() {
    for process in "${WHITELIST[@]}"; do
        if [[ "$1" == *"$process"* ]]; then
            return 0
        fi
    done
    return 1
}

# Función para verificar si un servicio está en la lista blanca
is_service_in_whitelist() {
    for service in "${SERVICE_WHITELIST[@]}"; do
        if [[ "$1" == "$service" ]]; then
            return 0
        fi
    done
    return 1
}

echo "Iniciando optimización de CPU..."

# 1. Identificar y matar procesos que consumen demasiada CPU (> 80% CPU)
echo "Finalizando procesos con más del 80% de CPU (método amigable)..."
for PID in $(ps aux --sort=-%cpu | awk '$3>80 {print $2}'); do
    PROC_NAME=$(ps -p $PID -o comm=)
    
    # Verificar si el proceso está en la lista blanca
    if is_in_whitelist "$PROC_NAME"; then
        echo "Saltando proceso en lista blanca: $PROC_NAME (PID: $PID)"
        continue
    fi

    # Intentar matar el proceso con SIGTERM (kill -15)
    echo "Intentando terminar proceso amigablemente: $PROC_NAME (PID: $PID)"
    kill -9 $PID
    
    # Esperar un momento para ver si el proceso se cierra
    sleep 2
    
    # Verificar si el proceso sigue vivo
    if kill -0 $PID 2>/dev/null; then
        echo "El proceso $PROC_NAME (PID: $PID) no respondió a SIGTERM, forzando terminación con SIGKILL..."
        kill -9 $PID
    else
        echo "El proceso $PROC_NAME (PID: $PID) fue terminado correctamente."
    fi
done

# 2. Reducir la prioridad de procesos intensivos de CPU
echo "Ajustando la prioridad de procesos intensivos..."
for PID in $(ps aux --sort=-%cpu | awk '$3>50 {print $2}'); do
    PROC_NAME=$(ps -p $PID -o comm=)
    
    # Verificar si el proceso está en la lista blanca
    if is_in_whitelist "$PROC_NAME"; then
        echo "Saltando proceso en lista blanca: $PROC_NAME (PID: $PID)"
        continue
    fi
    
    echo "Cambiando prioridad del proceso PID: $PID ($PROC_NAME)"
    renice +10 $PID
done

# 3. Establecer el modo de CPU en 'powersave' para reducir el consumo
echo "Configurando la CPU en modo de ahorro de energía..."
sudo cpufreq-set -g powersave

# 4. Detener servicios innecesarios (ejemplo: bluetooth y cups), exceptuando los que están en la lista blanca
echo "Deteniendo servicios no esenciales..."
for service in bluetooth cups cups-browsed; do
    # Verificar si el servicio está en la lista blanca
    if is_service_in_whitelist "$service"; then
        echo "Saltando servicio en lista blanca: $service"
        continue
    fi
    sudo systemctl stop $service
done

echo "Optimización completada."
