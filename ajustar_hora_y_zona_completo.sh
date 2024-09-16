#!/bin/bash

# ---------------------------------------------------------
# Script de configuracion automatica de la hora y zona horaria
# Autor: Ricardo Rosero
# Email: rrosero2000@gmail.com
# Github: https://github.com/rr-n4p5t3r
# ---------------------------------------------------------

# Función para verificar e instalar paquetes
verificar_instalar_paquete() {
    paquete=$1
    if ! dpkg -l | grep -q "^ii  $paquete "; then
        echo "El paquete $paquete no está instalado. Instalando..."
        apt-get update
        apt-get install -y $paquete
    else
        echo "El paquete $paquete ya está instalado."
    fi
}

# Verificar e instalar paquetes necesarios
verificar_instalar_paquete ntp
verificar_instalar_paquete ntpdate
verificar_instalar_paquete systemd-timesyncd
verificar_instalar_paquete util-linux

# Solicitar la zona horaria al usuario
read -p "Introduce la zona horaria (por ejemplo, America/Bogota): " zona_horaria

# Validar la zona horaria
if ! timedatectl list-timezones | grep -q "^$zona_horaria$"; then
    echo "Zona horaria inválida. Verifica la zona horaria ingresada."
    exit 1
fi

# Solicitar la hora al usuario
read -p "Introduce la hora en formato HH:MM (por ejemplo, 17:35): " hora_usuario

# Validar el formato de la hora
if [[ ! $hora_usuario =~ ^[0-9]{2}:[0-9]{2}$ ]]; then
    echo "Formato de hora inválido. Asegúrate de usar HH:MM."
    exit 1
fi

# Configurar la zona horaria
echo "Configurando la zona horaria a $zona_horaria..."
timedatectl set-timezone "$zona_horaria"

# Ajustar la hora manualmente
echo "Ajustando la hora manualmente a $hora_usuario..."
date -s "$hora_usuario"

# Verificar la hora actual
echo "Hora actual del sistema:"
date

# Deshabilitar NTP si está habilitado
echo "Deshabilitando NTP temporalmente..."
timedatectl set-ntp false

# Sincronizar hora con servidores NTP
if command -v ntpdate > /dev/null; then
    echo "Sincronizando la hora con ntpdate..."
    /usr/sbin/ntpdate pool.ntp.org
elif systemctl is-active --quiet systemd-timesyncd; then
    echo "Sincronizando la hora con systemd-timesyncd..."
    timedatectl set-ntp true
else
    echo "Ningún servicio NTP disponible. Sincronización manualmente desactivada."
fi

# Habilitar NTP nuevamente si es necesario
if systemctl is-active --quiet systemd-timesyncd; then
    echo "Habilitando NTP nuevamente..."
    timedatectl set-ntp true
fi

# Verificar el estado de NTP
echo "Verificando el estado de NTP..."
timedatectl status

# Verificar si hwclock está disponible y sincronizar RTC
if command -v hwclock > /dev/null; then
    echo "Sincronizando el reloj RTC con la hora del sistema..."
    /sbin/hwclock --systohc
else
    echo "hwclock no está disponible. Verifique la instalación de util-linux."
fi

# Verificar la hora del sistema después de los cambios
echo "Hora actual del sistema después de los ajustes:"
date
