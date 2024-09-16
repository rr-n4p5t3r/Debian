#!/bin/bash

# -----------------------------------------
# Autor: Ricardo Rosero
# Email: rrosero2000@gmail.com
# GitHub: https://github.com/rr-n4p5t3r
# 
# Descripción:
# Este script optimiza el uso de la CPU en un sistema Debian/Linux
# de manera automática. Realiza las siguientes acciones:
# 1. Identifica y finaliza procesos que consumen más del 80% de la CPU.
# 2. Ajusta la prioridad de procesos que consumen más del 50% de CPU.
# 3. Configura el gobernador de la CPU en modo 'powersave' para ahorrar energía.
# 4. Detiene servicios no esenciales como bluetooth y cups.
# 5. Limpia cachés de disco para liberar recursos.
#
# Uso:
# Puede ejecutarse manualmente o programarse con 'cron' para su ejecución periódica.
# -----------------------------------------

echo "Iniciando optimización de CPU..."

# 1. Identificar y matar procesos que consumen demasiada CPU (> 80% CPU)
echo "Finalizando procesos con más del 80% de CPU..."
for PID in $(ps aux --sort=-%cpu | awk '$3>80 {print $2}'); do
    echo "Matando proceso con PID: $PID"
    kill -9 $PID
done

# 2. Reducir la prioridad de procesos intensivos de CPU
echo "Ajustando la prioridad de procesos intensivos..."
for PID in $(ps aux --sort=-%cpu | awk '$3>50 {print $2}'); do
    echo "Cambiando prioridad del proceso PID: $PID"
    renice +10 $PID
done

# 3. Establecer el modo de CPU en 'powersave' para reducir el consumo
echo "Configurando la CPU en modo de ahorro de energía..."
sudo cpufreq-set -g powersave

# 4. Detener servicios innecesarios (ejemplo: bluetooth y cups)
echo "Deteniendo servicios no esenciales..."
sudo systemctl stop bluetooth
#sudo systemctl stop cups

# 5. Limpiar cachés innecesarias (opcional)
echo "Limpiando cachés de disco..."
sudo sync; sudo sysctl -w vm.drop_caches=3

echo "Optimización completada."
