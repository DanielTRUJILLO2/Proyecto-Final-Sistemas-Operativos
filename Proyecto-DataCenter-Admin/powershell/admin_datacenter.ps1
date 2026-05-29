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
            Clear-Host
            Write-Host "Opcion 4 en construccion..."
            Pausar
        }

        "5" {
            Clear-Host
            Write-Host "Opcion 5 en construccion..."
            Pausar
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