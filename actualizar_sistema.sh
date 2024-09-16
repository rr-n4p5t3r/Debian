#!/bin/bash

# -----------------------------------------
# Autor: Ricardo Rosero
# Email: rrosero2000@gmail.com
# GitHub: https://github.com/rr-n4p5t3r
#
# Descripción:
# Este script automatiza la actualización, limpieza y optimización de un sistema Debian/Linux. Realiza las siguientes acciones:
# 1. Actualiza la lista de paquetes.
# 2. Actualiza todos los paquetes desactualizados.
# 3. Actualiza el firmware del sistema.
# 4. Actualiza los controladores del sistema.
# 5. Autoremueve paquetes obsoletos o no necesarios.
# 6. Repara paquetes rotos o perdidos.
# 7. Limpia paquetes y dependencias innecesarias.
# 8. Remueve versiones antiguas del kernel, preservando el kernel actual en uso.
# 9. Optimiza el sistema base instalado.
# 10. Verifica si es necesario reiniciar el sistema después de las actualizaciones.
#
# Uso:
# Se puede ejecutar manualmente o automatizar su ejecución mediante 'cron'. Al finalizar, el script indicará si el sistema requiere reiniciarse.
# -----------------------------------------

# Función para mostrar mensajes
function print_message() {
    echo "=================================================================="
    echo "$1"
    echo "=================================================================="
}

# Obtener la versión actual del kernel en uso
KERNEL_VERSION=$(uname -r)

# Actualizar lista de paquetes
print_message "Actualizando la lista de paquetes..."
sudo apt update

# Actualizar todos los paquetes desactualizados
print_message "Actualizando todos los paquetes desactualizados..."
sudo apt upgrade -y

# Actualizar firmware
print_message "Actualizando firmware..."
sudo apt install --install-recommends linux-firmware -y

# Actualizar controladores del sistema
print_message "Actualizando controladores..."
sudo apt install --install-recommends firmware-linux-nonfree -y

# Autoremover paquetes obsoletos o no necesarios
print_message "Autoremoviendo paquetes obsoletos..."
sudo apt autoremove -y

# Autoreparar paquetes rotos o perdidos
print_message "Autoreparando paquetes rotos o perdidos..."
sudo apt --fix-broken install -y

# Limpiar paquetes y dependencias innecesarias
print_message "Limpiando paquetes obsoletos y dependencias innecesarias..."
sudo apt autoclean
sudo apt clean

# Remover versiones anteriores de kernels o paquetes, excepto el kernel en uso
print_message "Removiendo versiones anteriores de kernels y paquetes, excepto el kernel en uso ($KERNEL_VERSION)..."
INSTALLED_KERNELS=$(dpkg -l | grep linux-image | awk '{ print $2 }')
for KERNEL in $INSTALLED_KERNELS; do
    if [[ "$KERNEL" != *"$KERNEL_VERSION"* ]]; then
        print_message "Eliminando el kernel: $KERNEL"
        sudo apt purge -y "$KERNEL"
    else
        print_message "Preservando el kernel actual: $KERNEL"
    fi
done

# Optimización del sistema base
print_message "Optimización del sistema base instalado..."
sudo dpkg --configure -a
sudo apt install -f
sudo apt autoremove --purge -y
sudo apt clean

# Verificar si el sistema requiere un reinicio
if [ -f /var/run/reboot-required ]; then
    print_message "El sistema requiere un reinicio para aplicar las actualizaciones."
    read -p "¿Deseas reiniciar ahora? (s/n): " reboot_answer
    if [[ "$reboot_answer" == "s" || "$reboot_answer" == "S" ]]; then
        print_message "Reiniciando el sistema..."
        sudo reboot
    else
        print_message "No se reiniciará el sistema. Puedes reiniciarlo manualmente más tarde."
    fi
else
    print_message "El sistema no requiere un reinicio."
fi

print_message "¡Actualización y optimización completadas!"
