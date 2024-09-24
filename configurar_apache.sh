#!/bin/bash

# -----------------------------------------
# Autor: Ricardo Rosero
# Email: rrosero2000@gmail.com
# GitHub: https://github.com/rr-n4p5t3r
#
# Descripción:
# Script interactivo para configurar Apache, PHP, y bases de datos (PostgreSQL, MariaDB, MongoDB)
# Funcionalidades del Script:
# 1. Instalación de Apache, PHP y Certbot: El script instala Apache, PHP, y Certbot.
# 2. Interacción con el Usuario:
#       Solicita al usuario ingresar el directorio raíz del sitio web (DocumentRoot).
#       Solicita ingresar el dominio a configurar.
# 3. Configuración de Apache:
#       Crea un archivo de configuración para el sitio web (VirtualHost).
#       Configura redirección de HTTP a HTTPS.
#       Configura páginas de error personalizadas (400, 401, 403, 404).
# 4. Certificado SSL:
#       Usa Certbot para generar un certificado SSL para el dominio especificado.
# 5. Selección de Base de Datos:
#       El script da la opción de instalar y configurar PostgreSQL, MariaDB, o MongoDB.
#       Crea un usuario y una base de datos para el motor de base de datos seleccionado.
# 6. Verificación y reinicio de Apache:
#       Verifica la configuración de Apache y reinicia el servicio para aplicar los cambios.
#
# Uso: El script te guiará a través de los pasos, pidiendo la información requerida y configurando todo automáticamente.
# 1. Guarda el script en un archivo, por ejemplo configurar_apache.sh.
# 2. Dale permisos de ejecución: sudo chmod +x configurar_apache.sh
# 3. Ejecuta el script: sudo ./configurar_apache.sh
#
# -----------------------------------------

# Función para leer entrada del usuario con un valor por defecto
function prompt_input() {
    read -p "$1 [$2]: " input
    echo "${input:-$2}"
}

# Asegurarse de estar como root
if [[ $EUID -ne 0 ]]; then
   echo "Este script debe ejecutarse como root" 
   exit 1
fi

# Instalación básica de Apache, PHP y Certbot
echo "Instalando Apache, PHP y Certbot..."
apt update
apt install -y apache2 php libapache2-mod-php certbot python3-certbot-apache

# Pedir parámetros interactivos al usuario
DOCROOT=$(prompt_input "Ingrese el directorio raíz del sitio web (DocumentRoot)" "/var/www/html")
DOMAIN=$(prompt_input "Ingrese el dominio para el sitio web" "midominio.com")
ERROR_PAGES_DIR="$DOCROOT"

# Configurar Apache VirtualHost
APACHE_CONF_FILE="/etc/apache2/sites-available/$DOMAIN.conf"

echo "Configurando Apache VirtualHost para $DOMAIN..."
cat <<EOL > $APACHE_CONF_FILE
<VirtualHost *:80>
    DocumentRoot $DOCROOT
    ServerName $DOMAIN

    <Directory $DOCROOT>
        Options +FollowSymlinks
        AllowOverride All
        DirectoryIndex index.php index.html

        <IfModule mod_dav.c>
            Dav off
        </IfModule>

        SetEnv HOME $DOCROOT
        SetEnv HTTP_HOME $DOCROOT
    </Directory>

    ErrorDocument 400 /400.html
    ErrorDocument 401 /401.html
    ErrorDocument 403 /403.html
    ErrorDocument 404 /404.html

    ErrorLog \${APACHE_LOG_DIR}/$DOMAIN_error.log
    CustomLog \${APACHE_LOG_DIR}/$DOMAIN_access.log combined

    RewriteEngine on
    RewriteCond %{SERVER_NAME} =$DOMAIN
    RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>
EOL

# Habilitar el sitio en Apache
a2ensite $DOMAIN.conf
systemctl reload apache2

# Configurar Certbot para HTTPS
echo "Obteniendo certificado SSL con Certbot para $DOMAIN..."
certbot --apache -d $DOMAIN

# Base de datos
echo "¿Qué motor de base de datos desea instalar?"
echo "1) PostgreSQL"
echo "2) MariaDB"
echo "3) MongoDB"
echo "4) Ninguno"

read -p "Seleccione una opción [1-4]: " db_choice

case $db_choice in
    1)
        echo "Instalando PostgreSQL..."
        apt install -y postgresql postgresql-contrib
        DB_USER=$(prompt_input "Ingrese el nombre de usuario para PostgreSQL" "postgres_user")
        DB_PASS=$(prompt_input "Ingrese la contraseña para PostgreSQL" "postgres_pass")
        DB_PORT=$(prompt_input "Ingrese el puerto para PostgreSQL" "5432")
        
        sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
        sudo -u postgres psql -c "CREATE DATABASE ${DB_USER}_db OWNER $DB_USER;"
        sudo -u postgres psql -c "ALTER USER $DB_USER WITH SUPERUSER;"
        
        echo "PostgreSQL configurado en el puerto $DB_PORT."
        ;;
    2)
        echo "Instalando MariaDB..."
        apt install -y mariadb-server mariadb-client
        DB_USER=$(prompt_input "Ingrese el nombre de usuario para MariaDB" "mariadb_user")
        DB_PASS=$(prompt_input "Ingrese la contraseña para MariaDB" "mariadb_pass")
        DB_PORT=$(prompt_input "Ingrese el puerto para MariaDB" "3306")

        mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
        mysql -u root -e "CREATE DATABASE ${DB_USER}_db;"
        mysql -u root -e "GRANT ALL PRIVILEGES ON ${DB_USER}_db.* TO '$DB_USER'@'localhost';"
        mysql -u root -e "FLUSH PRIVILEGES;"

        echo "MariaDB configurado en el puerto $DB_PORT."
        ;;
    3)
        echo "Instalando MongoDB..."
        apt install -y mongodb
        systemctl start mongodb
        systemctl enable mongodb
        DB_USER=$(prompt_input "Ingrese el nombre de usuario para MongoDB" "mongodb_user")
        DB_PASS=$(prompt_input "Ingrese la contraseña para MongoDB" "mongodb_pass")
        DB_PORT=$(prompt_input "Ingrese el puerto para MongoDB" "27017")
        
        mongo --eval "db.createUser({user: '$DB_USER', pwd: '$DB_PASS', roles: [{role: 'readWrite', db: '${DB_USER}_db'}]});"
        echo "MongoDB configurado en el puerto $DB_PORT."
        ;;
    4)
        echo "No se instalará ningún motor de base de datos."
        ;;
    *)
        echo "Opción inválida. No se instalará ningún motor de base de datos."
        ;;
esac

# Crear páginas de error personalizadas si no existen
echo "Creando páginas de error personalizadas..."
for code in 400 401 403 404; do
    if [ ! -f "$ERROR_PAGES_DIR/$code.html" ]; then
        cat <<EOF > "$ERROR_PAGES_DIR/$code.html"
<!DOCTYPE html>
<html>
<head>
    <title>Error $code</title>
</head>
<body>
    <h1>Error $code</h1>
    <p>La página solicitada ha generado un error.</p>
</body>
</html>
EOF
        chown www-data:www-data "$ERROR_PAGES_DIR/$code.html"
        chmod 644 "$ERROR_PAGES_DIR/$code.html"
    fi
done

# Verificar configuración de Apache
echo "Verificando configuración de Apache..."
apache2ctl configtest

# Reiniciar Apache
echo "Reiniciando Apache..."
systemctl restart apache2

echo "Configuración completada. Apache, PHP y base de datos instalados."
