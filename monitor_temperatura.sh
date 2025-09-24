#!/bin/bash

# Verificar si sensors está instalado
if ! command -v sensors &> /dev/null; then
    echo "El paquete lm-sensors no está instalado. Por favor, instálalo con: sudo apt install lm-sensors"
    exit 1
fi

# Monitorear temperatura del procesador
while true; do
    clear
    echo "Monitoreando la temperatura del procesador..."
    sensors
    echo "Presiona Ctrl+C para salir."
    sleep 2
done
