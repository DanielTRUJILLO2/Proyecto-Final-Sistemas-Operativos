# ==========================================================
# Herramienta de Administracion de Data Center - PowerShell
# Proyecto Sistemas Operativos / Administracion
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
        $usuarios = @(Get-LocalUser | Select-Object Name, LastLogon)

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
        $discos = @(Get-CimInstance Win32_LogicalDisk | Select-Object DeviceID, VolumeName, DriveType, Size, FreeSpace)

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
            Write-Host "Tamano total: $($disco.Size) bytes"
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

    if (-not (Test-Path -LiteralPath $ruta -PathType Container)) {
        Write-Host ""
        Write-Host "Error: la ruta ingresada no existe o no es un directorio."
        Pausar
        return
    }

    Write-Host ""
    Write-Host "Buscando archivos grandes..."
    Write-Host "Esto puede tardar dependiendo del tamano de la ruta."
    Write-Host ""

    try {
        $archivos = @(Get-ChildItem -LiteralPath $ruta -Recurse -File -Force -ErrorAction SilentlyContinue |
            Sort-Object Length -Descending |
            Select-Object -First 10 FullName, Length)

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
        $sistema = Get-CimInstance Win32_OperatingSystem

        $memoriaLibreBytes = [int64]$sistema.FreePhysicalMemory * 1024
        $memoriaTotalBytes = [int64]$sistema.TotalVisibleMemorySize * 1024
        $porcentajeMemoriaLibre = [math]::Round(($memoriaLibreBytes / $memoriaTotalBytes) * 100, 2)

        Write-Host "Memoria fisica total: $memoriaTotalBytes bytes"
        Write-Host "Memoria fisica libre: $memoriaLibreBytes bytes"
        Write-Host "Porcentaje de memoria fisica libre: $porcentajeMemoriaLibre %"
        Write-Host ""

        $pagefiles = @(Get-CimInstance Win32_PageFileUsage)

        if ($pagefiles.Count -eq 0) {
            Write-Host "No se encontro informacion del archivo de paginacion."
        }
        else {
            $swapTotalMB = 0
            $swapUsadoMB = 0

            foreach ($pagefile in $pagefiles) {
                $swapTotalMB += $pagefile.AllocatedBaseSize
                $swapUsadoMB += $pagefile.CurrentUsage
            }

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

    if (-not (Test-Path -LiteralPath $origen -PathType Container)) {
        Write-Host ""
        Write-Host "Error: la ruta de origen no existe o no es un directorio."
        Pausar
        return
    }

    $usbDetectadas = @(Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 -and $_.DeviceID })

    if ($usbDetectadas.Count -eq 0) {
        Write-Host ""
        Write-Host "No se detectaron memorias USB. Conecte una USB e intente de nuevo."
        Pausar
        return
    }

    Write-Host ""
    Write-Host "Memorias USB detectadas:"
    Write-Host "----------------------------------------------"

    for ($i = 0; $i -lt $usbDetectadas.Count; $i++) {
        $usb = $usbDetectadas[$i]
        Write-Host "$($i + 1). Unidad: $($usb.DeviceID) - Nombre: $($usb.VolumeName) - Libre: $($usb.FreeSpace) bytes"
    }

    Write-Host "----------------------------------------------"
    $seleccion = Read-Host "Seleccione el numero de la USB destino"

    if (-not ($seleccion -as [int]) -or [int]$seleccion -lt 1 -or [int]$seleccion -gt $usbDetectadas.Count) {
        Write-Host ""
        Write-Host "Error: seleccion de USB no valida."
        Pausar
        return
    }

    $usbDestino = $usbDetectadas[[int]$seleccion - 1]
    $destinoBase = "$($usbDestino.DeviceID)\"
    $tamanoOrigen = (Get-ChildItem -LiteralPath $origen -Recurse -File -Force -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum).Sum

    if ($null -eq $tamanoOrigen) {
        $tamanoOrigen = 0
    }

    if ([int64]$usbDestino.FreeSpace -lt [int64]$tamanoOrigen) {
        Write-Host ""
        Write-Host "Error: la USB no tiene espacio libre suficiente."
        Write-Host "Tamano aproximado del directorio: $tamanoOrigen bytes"
        Write-Host "Espacio libre en USB: $($usbDestino.FreeSpace) bytes"
        Pausar
        return
    }

    $fecha = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $nombreOrigen = Split-Path -Path $origen -Leaf

    if ([string]::IsNullOrWhiteSpace($nombreOrigen)) {
        $nombreOrigen = "Directorio"
    }

    $carpetaBackup = Join-Path $destinoBase "backup_${nombreOrigen}_$fecha"

    try {
        New-Item -Path $carpetaBackup -ItemType Directory -Force | Out-Null

        Write-Host ""
        Write-Host "Copiando archivos a la USB..."
        Write-Host "Origen: $origen"
        Write-Host "Destino: $carpetaBackup"
        Write-Host ""

        Get-ChildItem -LiteralPath $origen -Force | Copy-Item -Destination $carpetaBackup -Recurse -Force -ErrorAction Stop

        $catalogo = Join-Path $carpetaBackup "catalogo_backup.csv"

        Get-ChildItem -LiteralPath $origen -Recurse -File -Force -ErrorAction SilentlyContinue |
            Select-Object FullName, LastWriteTime |
            Export-Csv -Path $catalogo -NoTypeInformation -Encoding UTF8

        Write-Host "Backup realizado correctamente en la memoria USB."
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
        "1" { Mostrar-Usuarios }
        "2" { Mostrar-Discos }
        "3" { Mostrar-ArchivosGrandes }
        "4" { Mostrar-MemoriaSwap }
        "5" { Hacer-Backup }
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
