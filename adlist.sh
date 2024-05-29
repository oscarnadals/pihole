#Creado y desarrollado por oscarnadals.

#!/bin/bash

# Función para pedir información al usuario
ask() {
    local prompt default reply

    prompt=$1
    default=$2

    # Preguntar al usuario
    if [ -z "$default" ]; then
        read -p "$prompt: " reply
    else
        read -p "$prompt [$default]: " reply
        reply=${reply:-$default}
    fi

    echo "$reply"
}

# Mostrar interfaces de red disponibles
echo "Interfaces de red disponibles:"
ip -o link show | awk -F': ' '{print $2}'

# Actualizar el sistema
echo "Actualizando el sistema..."
sudo apt update && sudo apt upgrade -y

# Instalar dependencias necesarias
echo "Instalando dependencias necesarias..."
sudo apt install -y curl

# Descargar e instalar Pi-hole
echo "Descargando e instalando Pi-hole..."
curl -sSL https://install.pi-hole.net | bash

# Preguntar al usuario por la configuración deseada
USERNAME=$(ask "Ingrese su nombre de usuario" "$USER")
PIHOLE_INTERFACE=$(ask "Ingrese la interfaz de red para Pi-hole" "eth0")
PIHOLE_IPV4_ADDRESS=$(ask "Ingrese la dirección IP estática para Pi-hole (ej. 192.168.1.2/24)" "192.168.1.2/24")
PIHOLE_WEBPASSWORD=$(ask "Ingrese la contraseña para la interfaz web de Pi-hole" "your_password_here")
ADD_ADLIST=$(ask "¿Desea añadir una adlist personalizada? (s/n)" "s")

# Configurar IP estática
echo "Configurando IP estática..."
sudo tee /etc/dhcpcd.conf > /dev/null <<EOL
interface $PIHOLE_INTERFACE
static ip_address=$PIHOLE_IPV4_ADDRESS
static routers=192.168.1.1  # Ajusta según tu configuración de red
static domain_name_servers=127.0.0.1
EOL

# Reiniciar el servicio de red para aplicar cambios
echo "Reiniciando servicio de red..."
sudo service dhcpcd restart

# Configurar Pi-hole desde el comando
echo "Configurando Pi-hole..."
pihole -a -p $PIHOLE_WEBPASSWORD  # Establecer contraseña para la interfaz web

# Añadir adlist personalizada si el usuario lo desea
if [ "$ADD_ADLIST" = "s" ] || [ "$ADD_ADLIST" = "S" ]; then
    ADLIST_URL=$(ask "Ingrese la URL de la adlist")
    ADLIST_FILE="/home/$USERNAME/adlist.txt"
    
    echo "Descargando adlist personalizada..."
    curl -o $ADLIST_FILE $ADLIST_URL

    echo "Añadiendo adlist personalizada a Pi-hole..."
    sudo tee -a /etc/pihole/adlists.list > /dev/null <<EOL
file://$ADLIST_FILE
EOL
fi

# Actualizar listas de Pi-hole
echo "Actualizando listas de Pi-hole..."
pihole -g

# Reiniciar Pi-hole para aplicar todas las configuraciones
echo "Reiniciando Pi-hole..."
pihole restartdns

echo "Instalación y configuración de Pi-hole completadas."
echo "Puedes acceder a la interfaz web de Pi-hole en http://$(echo $PIHOLE_IPV4_ADDRESS | cut -d'/' -f1)/admin con la contraseña que configuraste."
echo "Muchas gracias por emplear el script de oscarnadals."

# Fin del script
