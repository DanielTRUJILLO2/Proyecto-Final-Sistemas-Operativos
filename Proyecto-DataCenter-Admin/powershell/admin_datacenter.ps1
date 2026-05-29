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
            Clear-Host
            Write-Host "Opcion 2 en construccion..."
            Pausar
        }

        "3" {
            Clear-Host
            Write-Host "Opcion 3 en construccion..."
            Pausar
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