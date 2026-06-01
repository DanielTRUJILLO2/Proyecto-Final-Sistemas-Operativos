# Proyecto DataCenter Admin

Herramientas de administracion para un data center, implementadas en PowerShell y Bash.

## Integrantes

- Daniel Stiven Trujillo Marin - A00398810

## Opciones del menu

1. Desplegar usuarios creados en el sistema y fecha/hora de ultimo login.
2. Desplegar discos o filesystems conectados, con tamano y espacio libre en bytes.
3. Mostrar los 10 archivos mas grandes de una ruta indicada por el usuario.
4. Mostrar memoria libre y swap/pagefile en uso en bytes y porcentaje.
5. Hacer backup de un directorio a una memoria USB y generar un catalogo CSV.
6. Salir.

## PowerShell

Ejecutar en Windows PowerShell:

```powershell
cd powershell
.\admin_datacenter.ps1
```

Si Windows bloquea la ejecucion de scripts, ejecutar una vez:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

## Bash

Ejecutar en Linux:

```bash
cd bash
chmod +x admin_datacenter.sh
./admin_datacenter.sh
```

## Backup a USB

La opcion de backup solo permite continuar si detecta una memoria USB:

- En PowerShell se usan unidades removibles de Windows.
- En Bash se usan dispositivos USB montados detectados con `lsblk`. En WSL tambien se aceptan unidades montadas como `/mnt/d`.

El backup crea una carpeta con fecha y hora, copia los archivos del directorio origen y genera `catalogo_backup.csv` con la ruta de cada archivo y su ultima modificacion.
