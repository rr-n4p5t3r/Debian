#!/bin/bash
#
# Script para limpiar la swap en Linux
# ---------------------------------------------------
# Autor: Ricardo Rosero
# Email: rrosero2000@gmail.com
# GitHub: https://github.com/rr-n4p5t3r
#
# Descripción:
# Este script limpia la swap desactivándola y activándola nuevamente, liberando 
# cualquier memoria que se esté usando en swap innecesariamente.
#
# Uso:
# Ejecutar el script como root:
#     sudo ./limpiar_swap.sh
#
# ---------------------------------------------------

# Verifica si el script está siendo ejecutado como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor ejecuta el script como root"
  exit 1
fi

# Desactivar la swap
echo "Desactivando la swap..."
swapoff -a

# Activar la swap nuevamente
echo "Reactivando la swap..."
swapon -a

# Mostrar el estado de la swap
echo "Swap limpiada. Estado actual de la memoria:"
swapon --show
free -h
