#!/bin/bash
# =================================================================
# NOMBRE: descarga_soberana_zenity.sh
# DESCRIPCIÓN: Gestor de descargas resiliente con interfaz gráfica.
# PROCESOS: aria2c (motor), zenity (interfaz).
# AUDITORÍA: Requiere paquetes aria2 y zenity.
# =================================================================

# 1. Captura de la URL (si no se pasa como argumento, la pide)
URL=$1
if [ -z "$URL" ]; then
    URL=$(zenity --entry --title="Ruteo de Descarga" --text="Ingresa la URL del archivo:" --width=400)
    [ -z "$URL" ] && exit 1
fi

# 2. Definición del Directorio
DIR="$HOME/Downloads"

# 3. Lanzamiento del proceso con ruteo de salida hacia Zenity
# Explicación de banderas aria2c:
# --summary-interval=1: Reporta progreso cada segundo para la barra.
# -m 0: Reintentos infinitos para tu conexión inestable.
# -c: Continúa descargas truncadas.

(
aria2c -c -m 0 --retry-wait=5 --summary-interval=1 -d "$DIR" "$URL" 2>&1 | \
stdbuf -oL sed -n 's/.*(\([0-9]*\)%).*/\1/p' | \
while read -r PRG; do
    echo "$PRG"
    echo "# Descargando... ${PRG}% completado"
done
) | zenity --progress --title="Descarga en Curso" --text="Iniciando ruteo de bits..." --auto-close --percentage=0

# 4. Notificación Final
if [ $? -eq 0 ]; then
    zenity --info --text="Descarga completada con éxito en $DIR" --timeout=5
else
    zenity --error --text="El ruteo fue interrumpido o la URL es inválida."
fi
