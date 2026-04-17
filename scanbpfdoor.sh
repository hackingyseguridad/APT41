#!/bin/sh
# hakingyseguridad.com 2026  @antonio_taboada 
# Script SIMPLE para escanear detectar BPFdoor via ICMP
# Busca respuesta al paquete mágico 0xFFFFFFFF

FICHERO="ip.txt"

while read ip; do
    if [ -z "$ip" ]; then
        continue
    fi

    echo -n "Probando $ip ... "

    # Enviar ping con el patrón mágico ffffffff
    if ping -c 1 -p ffffffff -W 2 $ip > /dev/null 2>&1; then
        echo "¡¡¡ ALERTA !!!"
        echo ">>> $ip RESPONDE al paquete 0xFFFFFFFF <<<"
        echo ">>> POSIBLE BPFdoor DETECTADO <<<"
        echo "$ip - POSIBLE BPFdoor" >> bpfdoor_detectados.txt
    else
        echo "Sin respuesta"
    fi
done < $FICHERO

echo ""
