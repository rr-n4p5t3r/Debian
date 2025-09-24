Repositorio de Scripts de Debian

Este repositorio contiene una colección de scripts de Bash diseñados para la gestión y administración de sistemas operativos basados en Debian, como Ubuntu y Linux Mint. Los scripts están orientados a automatizar tareas comunes de mantenimiento, optimización y configuración del sistema, mejorando la eficiencia y la fiabilidad.
Guía de Uso

Para usar cualquiera de estos scripts, asegúrate de tener los permisos de ejecución necesarios.

chmod +x <nombre_del_script.sh>

Muchos scripts requieren privilegios de superusuario, por lo que debes ejecutarlos con sudo.

sudo ./<nombre_del_script.sh>

Listado de Scripts y Funcionalidades

A continuación, se detalla la función de cada script para ayudarte a elegir el adecuado para tus necesidades.

Nombre del Script
	

Descripción

actualizar_mint.sh
	

Automatiza la actualización y limpieza de un sistema Linux Mint, incluyendo la gestión de kernels antiguos.

actualizar_sistema.sh
	

Actualiza de forma segura todos los paquetes de un sistema basado en Debian y realiza una limpieza de los archivos innecesarios.

ajustar_hora_y_zona_completo.sh
	

Configura la hora y la zona horaria del sistema de forma precisa, asegurando una sincronización correcta.

aumentar_swap.sh
	

Aumenta el tamaño de la memoria de intercambio (swap) en el sistema, ideal para mejorar el rendimiento en máquinas con poca RAM.

check_memory.sh
	

Monitorea el uso de RAM y swap para detectar problemas de memoria antes de que afecten el rendimiento del sistema.

configurar_apache.sh
	

Script interactivo para configurar un servidor web completo con Apache, PHP, Certbot (SSL) y una base de datos (PostgreSQL, MariaDB o MongoDB).

liberar_memoria.sh
	

Libera la memoria caché y del búfer de la RAM, lo que puede ser útil para recuperar recursos del sistema sin un reinicio.

limpiar_swap.sh
	

Desactiva y vuelve a activar el espacio de intercambio para liberar las páginas de memoria inactiva, reduciendo el uso de swap.

mantenimiento.sh
	

Realiza una serie de tareas de mantenimiento programadas, como actualizaciones y limpieza del sistema.

monitor_temperatura.sh
	

Monitorea la temperatura de la CPU y genera alertas si supera un umbral definido.

optimizar_cpu.sh
	

Optimiza el uso del procesador, ajustando la frecuencia y el plan de energía para mejorar el rendimiento o reducir el consumo.

ram_swap.sh
	

Muestra un resumen detallado del uso actual de la memoria RAM y la memoria de intercambio.

ranking.sh
	

Un script para ordenar y analizar el uso de recursos del sistema, como el uso de memoria o CPU por procesos.
