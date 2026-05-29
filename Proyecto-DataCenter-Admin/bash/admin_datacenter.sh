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

mostrar_archivos_grandes() {
    clear
    echo "=============================================="
    echo " 10 ARCHIVOS MAS GRANDES"
    echo "=============================================="
    echo ""

    read -p "Ingrese la ruta o filesystem a analizar: " ruta

    if [ ! -e "$ruta" ]; then
        echo ""
        echo "Error: la ruta ingresada no existe."
        pausar
        return
    fi

    if [ ! -d "$ruta" ]; then
        echo ""
        echo "Error: la ruta ingresada no es un directorio."
        pausar
        return
    fi

    echo ""
    echo "Buscando archivos grandes..."
    echo "Esto puede tardar dependiendo del tamano de la ruta."
    echo ""

    archivos=$(find "$ruta" -type f -printf "%s|%p\n" 2>/dev/null | sort -nr | head -10)

    if [ -z "$archivos" ]; then
        echo "No se encontraron archivos en la ruta especificada."
    else
        echo "Los 10 archivos mas grandes encontrados son:"
        echo "----------------------------------------------"

        echo "$archivos" | while IFS="|" read -r tamano archivo; do
            echo "Archivo: $archivo"
            echo "Tamano: $tamano bytes"
            echo "----------------------------------------------"
        done
    fi

    pausar
}

mostrar_memoria_swap() {
    clear
    echo "=============================================="
    echo " MEMORIA LIBRE Y SWAP EN USO"
    echo "=============================================="
    echo ""

    if [ ! -r /proc/meminfo ]; then
        echo "Error: no se pudo leer la informacion de memoria del sistema."
        pausar
        return
    fi

    memoria_libre_kb=$(grep "MemAvailable" /proc/meminfo | awk '{print $2}')

    if [ -z "$memoria_libre_kb" ]; then
        memoria_libre_kb=$(grep "MemFree" /proc/meminfo | awk '{print $2}')
    fi

    swap_total_kb=$(grep "SwapTotal" /proc/meminfo | awk '{print $2}')
    swap_libre_kb=$(grep "SwapFree" /proc/meminfo | awk '{print $2}')

    memoria_libre_bytes=$((memoria_libre_kb * 1024))
    swap_total_bytes=$((swap_total_kb * 1024))
    swap_libre_bytes=$((swap_libre_kb * 1024))
    swap_usado_bytes=$((swap_total_bytes - swap_libre_bytes))

    if [ "$swap_total_bytes" -gt 0 ]; then
        porcentaje_swap=$(awk "BEGIN {printf \"%.2f\", ($swap_usado_bytes / $swap_total_bytes) * 100}")
    else
        porcentaje_swap="0.00"
    fi

    echo "Memoria libre: $memoria_libre_bytes bytes"
    echo ""
    echo "Swap total: $swap_total_bytes bytes"
    echo "Swap en uso: $swap_usado_bytes bytes"
    echo "Porcentaje de swap en uso: $porcentaje_swap %"

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
            mostrar_archivos_grandes
            ;;

        4)
            mostrar_memoria_swap
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
