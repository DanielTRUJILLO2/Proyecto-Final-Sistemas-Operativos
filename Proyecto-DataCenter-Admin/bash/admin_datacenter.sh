#!/bin/bash

# ==========================================================
# Herramienta de Administracion de Data Center - BASH
# Proyecto Sistemas Operativos / Administracion
# ==========================================================

pausar() {
    echo ""
    read -p "Presione ENTER para volver al menu"
}

mostrar_usuarios() {
    clear
    echo "=============================================="
    echo " USUARIOS DEL SISTEMA Y ULTIMO LOGIN"
    echo "=============================================="
    echo ""

    if command -v lastlog >/dev/null 2>&1; then
        lastlog
    else
        echo "El comando lastlog no esta disponible en este sistema."
        echo ""
        echo "Usuarios encontrados en /etc/passwd:"
        cut -d: -f1 /etc/passwd
    fi

    pausar
}

mostrar_menu() {
    clear
    echo "=============================================="
    echo " HERRAMIENTA DE ADMINISTRACION DATA CENTER"
    echo "=============================================="
    echo "1. Desplegar usuarios creados y ultimo login"
    echo "2. Desplegar filesystems o discos conectados"
    echo "3. Mostrar los 10 archivos mas grandes"
    echo "4. Mostrar memoria libre y swap en uso"
    echo "5. Hacer backup de un directorio a USB"
    echo "6. Salir"
    echo "=============================================="
}

mostrar_discos() {
    clear
    echo "=============================================="
    echo " DISCOS / FILESYSTEMS CONECTADOS"
    echo "=============================================="
    echo ""

    if command -v df >/dev/null 2>&1; then
        df -B1 --output=source,target,size,avail
    else
        echo "Error: el comando df no esta disponible en este sistema."
    fi

    pausar
}

opcion=""

while [ "$opcion" != "6" ]; do
    mostrar_menu
    read -p "Seleccione una opcion: " opcion

    case $opcion in
        1)
            mostrar_usuarios
            ;;

        2)
            mostrar_discos
            ;;

        3)
            clear
            echo "Opcion 3 en construccion..."
            pausar
            ;;

        4)
            clear
            echo "Opcion 4 en construccion..."
            pausar
            ;;

        5)
            clear
            echo "Opcion 5 en construccion..."
            pausar
            ;;

        6)
            clear
            echo "Saliendo de la herramienta..."
            ;;

        *)
            clear
            echo "Opcion no valida. Intente nuevamente."
            pausar
            ;;
    esac
done
