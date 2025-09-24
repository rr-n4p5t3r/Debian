#!/bin/bash

# ==================================================
# Auditor de Usuarios y Permisos de Bases de Datos
# Desarrollado por Ricardo Rosero
# ==================================================

# Habilitar el modo de depuración y salir si un comando falla
set -e
trap 'echo "🚫 Error: El script ha fallado en la línea $LINENO." >&2; exit 1' ERR

# --- Funciones de Auditoría por Motor ---

# Auditoría para MySQL/MariaDB
audit_mysql() {
    echo "Iniciando auditoría de MySQL..."

    if ! command -v mysql &> /dev/null; then
        echo "🚫 Error: El cliente 'mysql' no está instalado. Instálelo e inténtelo de nuevo." >&2
        return 1
    fi

    # Solicitar la contraseña de manera segura
    echo "Ingrese la contraseña para el usuario 'root' de MySQL:"
    read -rs MYSQL_ROOT_PASSWORD

    local query="SELECT user, host, authentication_string FROM mysql.user;"
    echo "--------------------------------------------------------"
    echo "--- Usuarios de MySQL ---"
    echo "--------------------------------------------------------"
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "$query" 2>/dev/null

    echo ""
    local query_grants="SELECT user, host, super_priv, Grant_priv FROM mysql.user;"
    echo "--------------------------------------------------------"
    echo "--- Permisos de Usuarios de MySQL (SUPER y GRANT) ---"
    echo "--------------------------------------------------------"
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "$query_grants" 2>/dev/null
}

# Auditoría para PostgreSQL
audit_postgres() {
    echo "Iniciando auditoría de PostgreSQL..."

    if ! command -v psql &> /dev/null; then
        echo "🚫 Error: El cliente 'psql' no está instalado. Instálelo e inténtelo de nuevo." >&2
        return 1
    fi

    echo "--------------------------------------------------------"
    echo "--- Usuarios de PostgreSQL ---"
    echo "--------------------------------------------------------"
    sudo -u postgres psql -c "SELECT usename, usesuper, usecreatedb, userepl, usebypassrls, userepl FROM pg_user;"

    # Verificar si se solicitan los permisos detallados
    if [[ -n "$AUDIT_PERMISSIONS" ]]; then
        echo ""
        local query_grants="SELECT table_schema, table_name, grantee, privilege_type FROM information_schema.role_table_grants WHERE grantee IN (SELECT usename FROM pg_user);"
        echo "--------------------------------------------------------"
        echo "--- Permisos de Usuarios de PostgreSQL ---"
        echo "--------------------------------------------------------"
        sudo -u postgres psql -c "$query_grants"
    else
        echo ""
        echo "✅ Omitiendo la auditoría de permisos. Para incluirla, ejecute el script de esta manera: AUDIT_PERMISSIONS=1 ./auditor_bd.sh postgres"
    fi
}

# Auditoría para SQLite3
audit_sqlite3() {
    echo "Iniciando auditoría de SQLite3..."

    if ! command -v sqlite3 &> /dev/null; then
        echo "🚫 Error: El cliente 'sqlite3' no está instalado. Instálelo e inténtelo de nuevo." >&2
        return 1
    fi

    local db_file="$1"
    if [[ ! -f "$db_file" ]]; then
        echo "🚫 Error: Archivo de base de datos no encontrado: $db_file" >&2
        return 1
    fi

    echo "--------------------------------------------------------"
    echo "--- Permisos de archivo de SQLite3 ---"
    echo "--------------------------------------------------------"
    ls -l "$db_file"
    echo ""
    echo "✅ Nota: Los permisos en SQLite3 se gestionan a nivel de archivo."
}

# Auditoría para MongoDB
audit_mongodb() {
    echo "Iniciando auditoría de MongoDB..."

    if ! command -v mongo &> /dev/null; then
        echo "🚫 Error: El cliente 'mongo' no está instalado. Instálelo e inténtelo de nuevo." >&2
        return 1
    fi

    echo "--------------------------------------------------------"
    echo "--- Usuarios de MongoDB ---"
    echo "--------------------------------------------------------"
    mongo --quiet --eval 'db.getUsers()'
}

# --- Lógica principal del script ---

main() {
    echo "======================================================================================="
    echo "        Auditor de Usuarios y Permisos de Bases de Datos"
    echo "======================================================================================="

    if [[ -z "$1" ]]; then
        echo "🚫 ERROR: Por favor, especifique el motor de la base de datos."
        echo "Uso: $0 <motor_bd>"
        echo "Motores soportados: mysql, postgres, sqlite3, mongodb"
        exit 1
    fi

    local db_engine="$1"
    local db_file="$2"

    case "$db_engine" in
        mysql)
            audit_mysql
            ;;
        postgres)
            audit_postgres
            ;;
        sqlite3)
            if [[ -z "$db_file" ]]; then
                echo "🚫 ERROR: Para SQLite3, debe especificar el archivo de la base de datos."
                echo "Uso: $0 sqlite3 <ruta_al_archivo>"
                exit 1
            fi
            audit_sqlite3 "$db_file"
            ;;
        mongodb)
            audit_mongodb
            ;;
        *)
            echo "🚫 ERROR: Motor de base de datos no soportado: $db_engine"
            echo "Motores soportados: mysql, postgres, sqlite3, mongodb"
            exit 1
            ;;
    esac

    echo "✅ Auditoría completada."
}

# Ejecutar la función principal
main "$@"

