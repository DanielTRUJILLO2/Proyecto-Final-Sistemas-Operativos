#!/bin/bash

# ==========================================================
# Herramienta de Administracion de Data Center - BASH
# Proyecto Sistemas Operativos / Administracion
# ==========================================================

pausar() {
    echo ""
    read -r -p "Presione ENTER para volver al menu"
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

    read -r -p "Ingrese la ruta o filesystem a analizar: " ruta

    if [ ! -d "$ruta" ]; then
        echo ""
        echo "Error: la ruta ingresada no existe o no es un directorio."
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

    memoria_total_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
    memoria_libre_kb=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)

    if [ -z "$memoria_libre_kb" ]; then
        memoria_libre_kb=$(awk '/^MemFree:/ {print $2}' /proc/meminfo)
    fi

    swap_total_kb=$(awk '/^SwapTotal:/ {print $2}' /proc/meminfo)
    swap_libre_kb=$(awk '/^SwapFree:/ {print $2}' /proc/meminfo)

    memoria_total_bytes=$((memoria_total_kb * 1024))
    memoria_libre_bytes=$((memoria_libre_kb * 1024))
    swap_total_bytes=$((swap_total_kb * 1024))
    swap_libre_bytes=$((swap_libre_kb * 1024))
    swap_usado_bytes=$((swap_total_bytes - swap_libre_bytes))

    if [ "$memoria_total_bytes" -gt 0 ]; then
        porcentaje_memoria_libre=$(awk "BEGIN {printf \"%.2f\", ($memoria_libre_bytes / $memoria_total_bytes) * 100}")
    else
        porcentaje_memoria_libre="0.00"
    fi

    if [ "$swap_total_bytes" -gt 0 ]; then
        porcentaje_swap=$(awk "BEGIN {printf \"%.2f\", ($swap_usado_bytes / $swap_total_bytes) * 100}")
    else
        porcentaje_swap="0.00"
    fi

    echo "Memoria total: $memoria_total_bytes bytes"
    echo "Memoria libre: $memoria_libre_bytes bytes"
    echo "Porcentaje de memoria libre: $porcentaje_memoria_libre %"
    echo ""
    echo "Swap total: $swap_total_bytes bytes"
    echo "Swap en uso: $swap_usado_bytes bytes"
    echo "Porcentaje de swap en uso: $porcentaje_swap %"

    pausar
}

obtener_usb_montadas() {
    {
        # En Linux normal se detectan memorias USB por el transporte "usb".
        if command -v lsblk >/dev/null 2>&1; then
            while IFS= read -r disco_usb; do
                lsblk -nrpo MOUNTPOINT "$disco_usb" 2>/dev/null | awk 'NF {print}'
            done < <(lsblk -nrpo NAME,TRAN,TYPE 2>/dev/null | awk '$2 == "usb" && ($3 == "disk" || $3 == "part") {print $1}')
        fi

        # En WSL la USB de Windows suele aparecer como una unidad montada, por ejemplo /mnt/d.
        if grep -qi microsoft /proc/version 2>/dev/null; then
            for punto_montaje in /mnt/[d-z]; do
                if [ -d "$punto_montaje" ] && mountpoint -q "$punto_montaje"; then
                    echo "$punto_montaje"
                fi
            done
        fi
    } | sort -u
}

hacer_backup() {
    clear
    echo "=============================================="
    echo " BACKUP DE DIRECTORIO A USB"
    echo "=============================================="
    echo ""

    read -r -p "Ingrese la ruta del directorio que desea respaldar: " origen

    if [ ! -d "$origen" ]; then
        echo ""
        echo "Error: la ruta de origen no existe o no es un directorio."
        pausar
        return
    fi

    mapfile -t usb_montadas < <(obtener_usb_montadas)

    if [ "${#usb_montadas[@]}" -eq 0 ]; then
        echo ""
        echo "No se detectaron memorias USB montadas."
        echo "Conecte y monte una USB, luego intente de nuevo."
        pausar
        return
    fi

    echo ""
    echo "Memorias USB montadas detectadas:"
    echo "----------------------------------------------"

    for i in "${!usb_montadas[@]}"; do
        libre=$(df -B1 --output=avail "${usb_montadas[$i]}" 2>/dev/null | tail -1 | tr -d ' ')
        echo "$((i + 1)). ${usb_montadas[$i]} - Libre: $libre bytes"
    done

    echo "----------------------------------------------"
    read -r -p "Seleccione el numero de la USB destino: " seleccion

    if ! [[ "$seleccion" =~ ^[0-9]+$ ]] || [ "$seleccion" -lt 1 ] || [ "$seleccion" -gt "${#usb_montadas[@]}" ]; then
        echo ""
        echo "Error: seleccion de USB no valida."
        pausar
        return
    fi

    destino_base="${usb_montadas[$((seleccion - 1))]}"
    tamano_origen=$(find "$origen" -type f -printf "%s\n" 2>/dev/null | awk '{s += $1} END {print s + 0}')
    espacio_libre=$(df -B1 --output=avail "$destino_base" 2>/dev/null | tail -1 | tr -d ' ')

    if [ "$espacio_libre" -lt "$tamano_origen" ]; then
        echo ""
        echo "Error: la USB no tiene espacio libre suficiente."
        echo "Tamano aproximado del directorio: $tamano_origen bytes"
        echo "Espacio libre en USB: $espacio_libre bytes"
        pausar
        return
    fi

    fecha=$(date +"%Y-%m-%d_%H-%M-%S")
    nombre_origen=$(basename "$origen")

    if [ -z "$nombre_origen" ] || [ "$nombre_origen" = "/" ]; then
        nombre_origen="Directorio"
    fi

    carpeta_backup="$destino_base/backup_${nombre_origen}_$fecha"

    if ! mkdir -p "$carpeta_backup"; then
        echo ""
        echo "Error: no se pudo crear la carpeta del backup en la USB."
        pausar
        return
    fi

    echo ""
    echo "Copiando archivos a la USB..."
    echo "Origen: $origen"
    echo "Destino: $carpeta_backup"
    echo ""

    if command -v rsync >/dev/null 2>&1; then
        rsync -r --no-perms --no-owner --no-group --omit-dir-times "$origen/" "$carpeta_backup/"
        resultado_copia=$?
    else
        cp -R "$origen/." "$carpeta_backup/"
        resultado_copia=$?
    fi

    if [ "$resultado_copia" -ne 0 ]; then
        echo "Error: ocurrio un problema al copiar los archivos."
        pausar
        return
    fi

    catalogo="$carpeta_backup/catalogo_backup.csv"

    echo "Archivo,UltimaModificacion" > "$catalogo"
    find "$origen" -type f -printf "\"%p\",\"%TY-%Tm-%Td %TH:%TM:%TS\"\n" 2>/dev/null >> "$catalogo"

    echo ""
    echo "Backup realizado correctamente en la memoria USB."
    echo "Carpeta del backup: $carpeta_backup"
    echo "Catalogo generado: $catalogo"

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

opcion=""

while [ "$opcion" != "6" ]; do
    mostrar_menu
    read -r -p "Seleccione una opcion: " opcion

    case $opcion in
        1) mostrar_usuarios ;;
        2) mostrar_discos ;;
        3) mostrar_archivos_grandes ;;
        4) mostrar_memoria_swap ;;
        5) hacer_backup ;;
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
