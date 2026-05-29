# ==========================================================
# Herramienta de Administración de Data Center - PowerShell
# Proyecto Sistemas Operativos / Administración
# ==========================================================

function Pausar {
    Write-Host ""
    Read-Host "Presione ENTER para volver al menu"
}

function Mostrar-Usuarios {
    Clear-Host
    Write-Host "=============================================="
    Write-Host " USUARIOS DEL SISTEMA Y ULTIMO LOGIN"
    Write-Host "=============================================="
    Write-Host ""

    try {
        $usuarios = Get-LocalUser | Select-Object Name, LastLogon

        foreach ($usuario in $usuarios) {
            if ($null -eq $usuario.LastLogon) {
                $ultimoLogin = "Nunca ha iniciado sesion"
            } else {
                $ultimoLogin = $usuario.LastLogon
            }

            Write-Host "Usuario: $($usuario.Name)"
            Write-Host "Ultimo login: $ultimoLogin"
            Write-Host "----------------------------------------------"
        }
    }
    catch {
        Write-Host "Error al obtener los usuarios del sistema."
        Write-Host "Detalle: $_"
    }

    Pausar
}

function Mostrar-Discos {
    Clear-Host
    Write-Host "=============================================="
    Write-Host " DISCOS / FILESYSTEMS CONECTADOS"
    Write-Host "=============================================="
    Write-Host ""

    try {
        $discos = Get-CimInstance Win32_LogicalDisk | Select-Object DeviceID, VolumeName, DriveType, Size, FreeSpace

        foreach ($disco in $discos) {

            switch ($disco.DriveType) {
                2 { $tipo = "Removible / USB" }
                3 { $tipo = "Disco local" }
                4 { $tipo = "Unidad de red" }
                5 { $tipo = "CD/DVD" }
                default { $tipo = "Otro" }
            }

            Write-Host "Unidad: $($disco.DeviceID)"
            Write-Host "Nombre: $($disco.VolumeName)"
            Write-Host "Tipo: $tipo"
            Write-Host "Tamaño total: $($disco.Size) bytes"
            Write-Host "Espacio libre: $($disco.FreeSpace) bytes"
            Write-Host "----------------------------------------------"
        }
    }
    catch {
        Write-Host "Error al obtener los discos conectados."
        Write-Host "Detalle: $_"
    }

    Pausar
}

function Mostrar-ArchivosGrandes {
    Clear-Host
    Write-Host "=============================================="
    Write-Host " 10 ARCHIVOS MAS GRANDES"
    Write-Host "=============================================="
    Write-Host ""

    $ruta = Read-Host "Ingrese la ruta o disco a analizar. Ejemplo: C:\ o C:\Users"

    if (-not (Test-Path $ruta)) {
        Write-Host ""
        Write-Host "Error: la ruta ingresada no existe."
        Pausar
        return
    }

    Write-Host ""
    Write-Host "Buscando archivos grandes..."
    Write-Host "Esto puede tardar dependiendo del tamaño de la ruta."
    Write-Host ""

    try {
        $archivos = Get-ChildItem -Path $ruta -Recurse -File -ErrorAction SilentlyContinue |
                    Sort-Object Length -Descending |
                    Select-Object -First 10 FullName, Length

        if ($archivos.Count -eq 0) {
            Write-Host "No se encontraron archivos en la ruta especificada."
        }
        else {
            Write-Host "Los 10 archivos mas grandes encontrados son:"
            Write-Host "----------------------------------------------"

            foreach ($archivo in $archivos) {
                Write-Host "Archivo: $($archivo.FullName)"
                Write-Host "Tamano: $($archivo.Length) bytes"
                Write-Host "----------------------------------------------"
            }
        }
    }
    catch {
        Write-Host "Error al buscar los archivos."
        Write-Host "Detalle: $_"
    }

    Pausar
}

function Mostrar-MemoriaSwap {
    Clear-Host
    Write-Host "=============================================="
    Write-Host " MEMORIA LIBRE Y SWAP EN USO"
    Write-Host "=============================================="
    Write-Host ""

    try {
        # Obtener informacion de memoria fisica
        $sistema = Get-CimInstance Win32_OperatingSystem

        # FreePhysicalMemory viene en KB, se convierte a bytes
        $memoriaLibreBytes = [int64]$sistema.FreePhysicalMemory * 1024
        $memoriaTotalBytes = [int64]$sistema.TotalVisibleMemorySize * 1024

        Write-Host "Memoria fisica total: $memoriaTotalBytes bytes"
        Write-Host "Memoria fisica libre: $memoriaLibreBytes bytes"
        Write-Host ""

        # Obtener informacion del archivo de paginacion
        # En Windows, el archivo de paginacion cumple una funcion similar al swap
        $pagefiles = Get-CimInstance Win32_PageFileUsage

        if ($null -eq $pagefiles) {
            Write-Host "No se encontro informacion del archivo de paginacion."
        }
        else {
            $swapTotalMB = 0
            $swapUsadoMB = 0

            foreach ($pagefile in $pagefiles) {
                $swapTotalMB += $pagefile.AllocatedBaseSize
                $swapUsadoMB += $pagefile.CurrentUsage
            }

            # Convertir MB a bytes
            $swapTotalBytes = [int64]$swapTotalMB * 1024 * 1024
            $swapUsadoBytes = [int64]$swapUsadoMB * 1024 * 1024

            if ($swapTotalBytes -gt 0) {
                $porcentajeSwap = [math]::Round(($swapUsadoBytes / $swapTotalBytes) * 100, 2)
            }
            else {
                $porcentajeSwap = 0
            }

            Write-Host "Swap/Pagefile total: $swapTotalBytes bytes"
            Write-Host "Swap/Pagefile en uso: $swapUsadoBytes bytes"
            Write-Host "Porcentaje de swap/pagefile en uso: $porcentajeSwap %"
        }
    }
    catch {
        Write-Host "Error al obtener informacion de memoria y swap."
        Write-Host "Detalle: $_"
    }

    Pausar
}

function Hacer-Backup {
    Clear-Host
    Write-Host "=============================================="
    Write-Host " BACKUP DE DIRECTORIO A USB"
    Write-Host "=============================================="
    Write-Host ""

    $origen = Read-Host "Ingrese la ruta del directorio que desea respaldar"

    if (-not (Test-Path $origen)) {
        Write-Host ""
        Write-Host "Error: el directorio de origen no existe."
        Pausar
        return
    }

    if (-not (Test-Path $origen -PathType Container)) {
        Write-Host ""
        Write-Host "Error: la ruta de origen no es un directorio."
        Pausar
        return
    }

    Write-Host ""
    Write-Host "Unidades removibles detectadas:"
    Write-Host "----------------------------------------------"

    $usbDetectadas = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 }

    if ($usbDetectadas.Count -eq 0) {
        Write-Host "No se detectaron memorias USB."
        Write-Host "Puede ingresar manualmente una ruta destino para pruebas."
    }
    else {
        foreach ($usb in $usbDetectadas) {
            Write-Host "Unidad USB: $($usb.DeviceID) - Espacio libre: $($usb.FreeSpace) bytes"
        }
    }

    Write-Host ""
    $destinoBase = Read-Host "Ingrese la ruta destino del backup. Ejemplo: E:\ o C:\Users\danny\Documents\PruebaBackup"

    if (-not (Test-Path $destinoBase)) {
        Write-Host ""
        Write-Host "La ruta destino no existe. Creandola..."
        New-Item -Path $destinoBase -ItemType Directory -Force | Out-Null
    }

    $fecha = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $nombreOrigen = Split-Path $origen -Leaf

    if ([string]::IsNullOrWhiteSpace($nombreOrigen)) {
        $nombreOrigen = "Directorio"
    }

    $carpetaBackup = Join-Path $destinoBase "backup_${nombreOrigen}_$fecha"

    try {
        New-Item -Path $carpetaBackup -ItemType Directory -Force | Out-Null

        Write-Host ""
        Write-Host "Copiando archivos..."
        Write-Host "Origen: $origen"
        Write-Host "Destino: $carpetaBackup"
        Write-Host ""

        Copy-Item -Path $origen\* -Destination $carpetaBackup -Recurse -Force -ErrorAction Stop

        $catalogo = Join-Path $carpetaBackup "catalogo_backup.csv"

        Get-ChildItem -Path $origen -Recurse -File |
        Select-Object FullName, LastWriteTime |
        Export-Csv -Path $catalogo -NoTypeInformation -Encoding UTF8

        Write-Host "Backup realizado correctamente."
        Write-Host "Carpeta del backup: $carpetaBackup"
        Write-Host "Catalogo generado: $catalogo"
    }
    catch {
        Write-Host ""
        Write-Host "Error al realizar el backup."
        Write-Host "Detalle: $_"
    }

    Pausar
}

function Mostrar-Menu {
    Clear-Host
    Write-Host "=============================================="
    Write-Host " HERRAMIENTA DE ADMINISTRACION DATA CENTER"
    Write-Host "=============================================="
    Write-Host "1. Desplegar usuarios creados y ultimo login"
    Write-Host "2. Desplegar filesystems o discos conectados"
    Write-Host "3. Mostrar los 10 archivos mas grandes"
    Write-Host "4. Mostrar memoria libre y swap en uso"
    Write-Host "5. Hacer backup de un directorio a USB"
    Write-Host "6. Salir"
    Write-Host "=============================================="
}

do {
    Mostrar-Menu
    $opcion = Read-Host "Seleccione una opcion"

    switch ($opcion) {
        "1" {
            Mostrar-Usuarios
        }

        "2" {
            Mostrar-Discos
        }

        "3" {
            Mostrar-ArchivosGrandes
        }

        "4" {
            Mostrar-MemoriaSwap
        }

        "5" {
            Hacer-Backup
        }

        "6" {
            Clear-Host
            Write-Host "Saliendo de la herramienta..."
        }

        default {
            Clear-Host
            Write-Host "Opcion no valida. Intente nuevamente."
            Pausar
        }
    }

} while ($opcion -ne "6")