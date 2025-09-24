#!/bin/bash
#
# Script mejorado para configurar un entorno de servidor web 
# ---------------------------------------------------
# Autor: Ricardo Rosero
# Descripción:
# Un script más seguro y robusto para la configuración interactiva de Apache,
# PHP, Certbot y bases de datos. Incluye validación de entrada, manejo de errores
# y prácticas de seguridad mejoradas.
# ---------------------------------------------------

# Habilitar el modo de depuración y salir en caso de error
set -e
trap 'echo "🚫 Error: El script ha fallado en la línea $LINENO. Saliendo..." >&2; exit 1' ERR

# Función para solicitar la entrada del usuario de forma segura
function prompt_input() {
    local input
    read -p "$1 [$2]: " input
    echo "${input:-$2}"
}

# Función para solicitar una contraseña de forma segura
function prompt_password() {
    local password
    while true; do
        read -s -p "$1: " password
        echo
        if [[ -n "$password" ]]; then
            echo "$password"
            break
        else
            echo "🚫 La contraseña no puede estar vacía. Inténtalo de nuevo."
        fi
    done
}

# --- Chequeo de privilegios de root ---
if [[ $EUID -ne 0 ]]; then
   echo "🚫 Este script debe ejecutarse como root. Por favor, usa 'sudo'."
   exit 1
fi

# --- Instalación básica ---
echo "✅ Actualizando el sistema e instalando dependencias..."
apt update && apt install -y apache2 php libapache2-mod-php certbot python3-certbot-apache

# --- Parámetros interactivos ---
DOCROOT=$(prompt_input "Ingrese el directorio raíz del sitio web (DocumentRoot)" "/var/www/html")
DOMAIN=$(prompt_input "Ingrese el dominio para el sitio web" "midominio.com")

if [[ ! -d "$DOCROOT" ]]; then
    echo "✅ Creando el directorio raíz del sitio: $DOCROOT"
    mkdir -p "$DOCROOT"
    chown -R www-data:www-data "$DOCROOT"
fi

# --- Configuración de Apache VirtualHost ---
APACHE_CONF_FILE="/etc/apache2/sites-available/$DOMAIN.conf"
echo "✅ Creando y configurando Apache VirtualHost para $DOMAIN..."

cat <<EOL > $APACHE_CONF_FILE
<VirtualHost *:80>
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN
    DocumentRoot $DOCROOT
    ErrorDocument 400 /400.html
    ErrorDocument 401 /401.html
    ErrorDocument 403 /403.html
    ErrorDocument 404 /404.html
    
    <Directory $DOCROOT>
        Options +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/$DOMAIN-error.log
    CustomLog \${APACHE_LOG_DIR}/$DOMAIN-access.log combined
    
    RewriteEngine on
    RewriteCond %{SERVER_NAME} =$DOMAIN
    RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>
EOL

# Habilitar el sitio y verificar la configuración de Apache
echo "✅ Habilitando el sitio y verificando configuración de Apache..."
a2dissite 000-default.conf
a2ensite "$DOMAIN.conf"
apache2ctl configtest
systemctl restart apache2

# --- Certificado SSL con Certbot ---
echo "✅ Obteniendo certificado SSL para $DOMAIN..."
certbot --apache --agree-tos --redirect -d "$DOMAIN" --email "webmaster@$DOMAIN"

# --- Selección de Base de Datos ---
echo "---"
echo "✅ ¿Qué motor de base de datos desea instalar?"
echo "1) PostgreSQL"
echo "2) MariaDB"
echo "3) MongoDB"
echo "4) Ninguno"
echo "---"

read -p "Seleccione una opción [1-4]: " db_choice

case $db_choice in
    1)
        echo "✅ Instalando PostgreSQL..."
        apt install -y postgresql postgresql-contrib
        DB_USER=$(prompt_input "Ingrese el nombre de usuario para PostgreSQL" "pg_user")
        DB_PASS=$(prompt_password "Ingrese la contraseña para el usuario '$DB_USER'")
        echo "✅ Creando usuario y base de datos en PostgreSQL..."
        sudo -u postgres psql -c "CREATE USER \"$DB_USER\" WITH PASSWORD '$DB_PASS';"
        sudo -u postgres psql -c "CREATE DATABASE \"${DB_USER}_db\" OWNER \"$DB_USER\";"
        echo "PostgreSQL configurado con el usuario '$DB_USER'."
        ;;
    2)
        echo "✅ Instalando MariaDB..."
        apt install -y mariadb-server mariadb-client
        DB_USER=$(prompt_input "Ingrese el nombre de usuario para MariaDB" "mdb_user")
        DB_PASS=$(prompt_password "Ingrese la contraseña para el usuario '$DB_USER'")
        echo "✅ Creando usuario y base de datos en MariaDB..."
        mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
        mysql -u root -e "CREATE DATABASE ${DB_USER}_db;"
        mysql -u root -e "GRANT ALL PRIVILEGES ON ${DB_USER}_db.* TO '$DB_USER'@'localhost';"
        mysql -u root -e "FLUSH PRIVILEGES;"
        echo "MariaDB configurado con el usuario '$DB_USER'."
        ;;
    3)
        echo "✅ Instalando MongoDB..."
        apt install -y mongodb
        systemctl start mongodb && systemctl enable mongodb
        DB_USER=$(prompt_input "Ingrese el nombre de usuario para MongoDB" "mongo_user")
        DB_PASS=$(prompt_password "Ingrese la contraseña para el usuario '$DB_USER'")
        echo "✅ Creando usuario y base de datos en MongoDB..."
        mongo --eval "db.createUser({ user: '$DB_USER', pwd: '$DB_PASS', roles: [{ role: 'readWrite', db: '${DB_USER}_db' }] });"
        echo "MongoDB configurado con el usuario '$DB_USER'."
        ;;
    4)
        echo "✅ No se instalará ningún motor de base de datos."
        ;;
    *)
        echo "🚫 Opción inválida. No se instalará ningún motor de base de datos."
        ;;
esac

# --- Limpieza y finalización ---
echo "✅ Limpiando paquetes innecesarios..."
apt autoremove -y

echo "✅ Verificando el estado del servicio Apache..."
systemctl status apache2 --no-pager

echo "✅ Configuración completada exitosamente."
