#!/bin/bash

# ==============================
# Monitor de temperatura del procesador
# Desarrollado por Ricardo Rosero
# ==============================

# Habilitar el modo de depuración y salir si un comando falla
set -e
trap 'echo "🚫 Error: El script ha fallado en la línea $LINENO." >&2; exit 1' ERR

# --- Funciones de utilidad ---

function install_sensors() {
    echo "El paquete lm-sensors no está instalado."
    read -rp "¿Desea instalarlo ahora? (s/n): " confirm
    if [[ $confirm == "s" || $confirm == "S" ]]; then
        sudo apt update
        sudo apt install -y lm-sensors
        echo "✅ lm-sensors instalado. Ejecute 'sudo sensors-detect' y reinicie su sistema si es la primera vez que lo instala."
        exit 0
    else
        echo "Instalación cancelada. Saliendo..."
        exit 1
    fi
}

# --- Lógica principal ---
# Verificar si 'sensors' está instalado
if ! command -v sensors &> /dev/null; then
    install_sensors
fi

# Preguntar por un umbral de alerta
read -rp "Ingrese un umbral de temperatura en Celsius para recibir alertas (ej. 75, 80). (O presione Enter para no establecer uno): " THRESHOLD

echo "Monitoreando la temperatura del procesador. Presione Ctrl+C para salir."

# Bucle principal de monitoreo
while true; do
    clear
    echo "======================================="
    echo "  Monitor de Temperatura del Procesador"
    echo "======================================="

    # Obtener la temperatura de forma segura, ignorando los errores
    TEMP_DATA=$(sensors 2>/dev/null)

    # Validar si se encontraron datos de sensores
    if [[ -z "$TEMP_DATA" ]]; then
        echo "🚫 No se detectaron sensores de temperatura. Asegúrese de haber ejecutado 'sudo sensors-detect' y reiniciado su sistema."
        echo "Saliendo..."
        exit 1
    fi

    echo "$TEMP_DATA"

    # Extraer la temperatura de la CPU, en Celsius
    CPU_TEMP=$(echo "$TEMP_DATA" | grep 'Core' | awk '{print $3}' | cut -c2- | cut -d'.' -f1)

    # Comprobar si se ha superado el umbral de alerta
    if [[ -n "$THRESHOLD" && "$CPU_TEMP" -ge "$THRESHOLD" ]]; then
        echo ""
        echo "⚠️  ¡ATENCIÓN! La temperatura ($CPU_TEMP°C) ha superado el umbral de $THRESHOLD°C."
        echo ""
    fi
    
    echo "---------------------------------------"
    echo "Presione Ctrl+C para salir."
    sleep 2
done

