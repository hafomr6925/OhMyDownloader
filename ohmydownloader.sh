#!/bin/bash
# =================================================================
# NOMBRE: flujo_soberano_resiliente.sh
# DESCRIPCIÓN: Gestor con recuperación de terminal para Zenity.
# AUDITORÍA: Detección DPKG, fallback a terminal y ruteo YAD.
# =================================================================

# Colores para terminal (Soberanía Visual)
CIAN='\033[0;36m'
AMARILLO='\033[1;33m'
RESET='\033[0m'

# 1. Auditoría de Supervivencia (Zenity)
if ! dpkg -l | grep -q "^ii  zenity " ; then
    echo -e "${AMARILLO}[!] ALERTA DE SISTEMA:${RESET} El componente 'zenity' no está instalado."
    echo -e "${CIAN}[?]${RESET} ¿Deseas instalarlo desde la terminal para habilitar la interfaz gráfica? (s/n)"
    read -r resp
    if [[ "$resp" == "s" || "$resp" == "S" ]]; then
        sudo apt update && sudo apt install zenity -y
    else
        echo -e "${AMARILLO}[!] Abortando:${RESET} Se requiere zenity para el ruteo de datos."
        exit 1
    fi
fi

# 2. Auditoría de Dependencias Secundarias (Aria2 y Yad)
declare -A DEPS=( ["aria2"]="aria2c" ["yad"]="yad" )

for pkg in "${!DEPS[@]}"; do
    if ! dpkg -l | grep -q "^ii  $pkg " ; then
        zenity --question --title="Auditoría de Sistema" \
            --text="El componente '$pkg' no se detecta.\n¿Deseas instalarlo ahora?" \
            --width=350 || exit 1

        PASS=$(zenity --password --title="Privilegios de Root")
        [ -z "$PASS" ] && exit 1

        (
        echo "20"; echo "# Sincronizando repositorios..."
        echo "$PASS" | sudo -S apt update > /dev/null 2>&1
        echo "60"; echo "# Instalando $pkg..."
        echo "$PASS" | sudo -S apt install "$pkg" -y > /dev/null 2>&1
        echo "100"; echo "# Componente $pkg listo."
        ) | zenity --progress --title="Instalación" --auto-close --percentage=0
    fi
done

# 3. Configuración de Parámetros
URL_INICIAL=$1
RUTA_DEFECTO="$HOME/Downloads/"

# 4. La Ventana Soberana (Yad)
CONFIG=$(yad --title="Configuración de Ruteo" --form --width=600 \
    --text="Gestión de Flujo de Datos - Workstation Hafid" \
    --field="URL del archivo" "$URL_INICIAL" \
    --field="Carpeta de destino:DIR" "$RUTA_DEFECTO" \
    --button="Iniciar Ruteo:0" --button="Cancelar:1")

[ $? -ne 0 ] && exit 1

URL=$(echo "$CONFIG" | cut -d'|' -f1)
DIR=$(echo "$CONFIG" | cut -d'|' -f2)
[ -z "$DIR" ] && DIR="$RUTA_DEFECTO"

# 5. Ejecución y Monitoreo (Kernel 6.14)
(
aria2c -c -m 0 --retry-wait=5 --summary-interval=1 -d "$DIR" "$URL" 2>&1 | \
stdbuf -oL sed -u -n 's/.*(\([0-9]*\)%).*DL:\([^ ]* [^ ]*\).*/\1\n# Descargando: \1% | Velocidad: \2/p' | \
while read -r LINE; do
    echo "$LINE"
done
) | zenity --progress --title="Monitoreo de Flujo" \
    --text="Iniciando ruteo en: $DIR" \
    --auto-close --percentage=0

# 6. Auditoría Final y Ruteo Sonoro
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    # Verificación de recursos de audio
    AUDIO="/usr/share/sounds/freedesktop/stereo/complete.oga"
    if command -v paplay >/dev/null 2>&1 && [ -f "$AUDIO" ]; then
        paplay "$AUDIO" &
    fi
    zenity --info --text="Ruteo completado con éxito." --timeout=5
else
    zenity --warning --text="Flujo interrumpido o red inestable."
fi
