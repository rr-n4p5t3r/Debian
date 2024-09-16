#!/bin/bash

# Actualizar la lista de paquetes
echo "Actualizando la lista de paquetes..."
sudo apt update

# Verificar si hay actualizaciones disponibles
echo "Verificando si hay actualizaciones de controladores o paquetes disponibles..."
UPDATES=$(sudo apt list --upgradable 2>/dev/null | grep -i "firmware")

if [ -z "$UPDATES" ]; then
    echo "No se encontraron actualizaciones para controladores."
else
    echo "Se encontraron las siguientes actualizaciones:"
    echo "$UPDATES"
    
    # Preguntar si desea instalar las actualizaciones
    read -p "¿Deseas instalar las actualizaciones ahora? (s/n): " answer
    if [[ "$answer" == "s" || "$answer" == "S" ]]; then
        # Instalar las actualizaciones disponibles
        echo "Instalando actualizaciones..."
        sudo apt upgrade -y
        
        # Reiniciar si es necesario (por ejemplo, después de una actualización del kernel)
        if [ -f /var/run/reboot-required ]; then
            echo "Es necesario reiniciar el sistema para aplicar las actualizaciones."
            read -p "¿Deseas reiniciar ahora? (s/n): " reboot_answer
            if [[ "$reboot_answer" == "s" || "$reboot_answer" == "S" ]]; then
                sudo reboot
            else
                echo "No se reinició el sistema. Por favor, reinicia manualmente más tarde."
            fi
        fi
    else
        echo "Actualizaciones canceladas."
    fi
fi
