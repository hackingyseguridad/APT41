#!/bin/sh

# Script: busca_bpfdoor.sh
# Descripción: Busca evidencias de BPFdoor y variantes en Linux
# Compatible con Bash/sh antiguos (sin arrays, sin funciones modernas)
# Uso: sh busca_bpfdoor.sh   o   chmod +x busca_bpfdoor.sh && ./busca_bpfdoor.sh

# Componente	Indicadores buscados
# Procesos	hpasmlited, agetty, auditd, systemd-journald, udevd (posible suplantación)
# Archivos	/etc/init.d/, /sbin/, /dev/shm/, /tmp/, /var/tmp/ con nombres como kdmtmpout, ps_init
# Red	Paquetes ICMP de gran tamaño, sockets RAW, tráfico ICMP anómalo
# Kernel	Módulos BPF/eBPF sospechosos, parámetros bpf_enable_unprivileged
# Precarga	Archivo /etc/ld.so.preload (técnica común de rootkit)
# Integridad	Tamaño anormal de binarios como ps, netstat, ss
#


echo "[*] Iniciando búsqueda de indicadores de BPFdoor y malware similar..."
echo "[*] Fecha: $(date)"
echo "============================================"

# Colores para resaltar (si el terminal lo soporta)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; NC=''
fi

# Contador de hallazgos
found=0

# 1. Buscar procesos sospechosos (imitando hpasmlited, agetty, auditd, etc.)
echo -e "\n${YELLOW}[1] Revisando procesos en ejecución...${NC}"
ps aux | grep -E "hpasmlited|agetty|auditd|systemd-journald|udevd" | grep -v grep
if [ $? -eq 0 ]; then
    echo -e "${RED}[!] Posible proceso suplantado por BPFdoor detectado.${NC}"
    found=$((found+1))
else
    echo "[+] No se encontraron procesos sospechosos conocidos."
fi

# 2. Revisar archivos en ubicaciones comunes donde se esconde el malware
echo -e "\n${YELLOW}[2] Buscando binarios en rutas comunes...${NC}"
for dir in /etc/init.d /sbin /usr/lib/systemd /dev/shm /var/tmp /tmp; do
    if [ -d "$dir" ]; then
        echo "    Revisando $dir ..."
        find "$dir" -type f \( -name "hpasmlited" -o -name "kdmtmpout" -o -name "ps_init" -o -name "*.elf" -o -name "icmpshell*" \) 2>/dev/null
        if [ $? -eq 0 ]; then
            found=$((found+1))
        fi
    fi
done

# 3. Buscar archivos temporales o en memoria que podrían ser inyectados
echo -e "\n${YELLOW}[3] Buscando archivos en /dev/shm sospechosos...${NC}"
ls -la /dev/shm/ 2>/dev/null | grep -E "kdmtmpout|ps_init|\.shm"
if [ $? -eq 0 ]; then
    echo -e "${RED}[!] Posibles archivos de memoria de BPFdoor.${NC}"
    found=$((found+1))
fi

# 4. Revisar filtros BPF cargados (si bpftool está disponible)
echo -e "\n${YELLOW}[4] Revisando programas eBPF/BPF cargados...${NC}"
if command -v bpftool >/dev/null 2>&1; then
    bpftool prog list 2>/dev/null | grep -E "socket_filter|name|tag" | head -20
    echo "[*] Si ve programas con nombres aleatorios o inusuales, investigar."
else
    echo "[-] bpftool no instalado, no se pueden listar filtros BPF."
fi

# 5. Buscar tráfico ICMP con payloads grandes o patrones 0xFFFFFFFF (requiere tshark o tcpdump)
echo -e "\n${YELLOW}[5] Buscando tráfico ICMP anómalo (últimos 1000 paquetes)...${NC}"
if command -v tcpdump >/dev/null 2>&1; then
    timeout 5 tcpdump -i any -c 1000 'icmp[icmptype]=icmp-echo' -n 2>/dev/null | grep -E "length [5-9][0-9]|length 1[0-9][0-9]"
    if [ $? -eq 0 ]; then
        echo -e "${RED}[!] Posibles paquetes ICMP grandes o sospechosos.${NC}"
        found=$((found+1))
    else
        echo "[+] No se detectaron paquetes ICMP inusuales en la muestra."
    fi
else
    echo "[-] tcpdump no disponible."
fi

# 6. Revisar conexiones de red ocultas (raw sockets)
echo -e "\n${YELLOW}[6] Revisando sockets RAW (pueden indicar BPFdoor)...${NC}"
if command -v netstat >/dev/null 2>&1; then
    netstat -lpn 2>/dev/null | grep -E "raw|icmp"
elif command -v ss >/dev/null 2>&1; then
    ss -lpn 2>/dev/null | grep -E "raw|icmp"
else
    echo "[-] netstat/ss no disponibles."
fi

# 7. Buscar inyección en /etc/ld.so.preload (rootkit común)
echo -e "\n${YELLOW}[7] Revisando precarga de bibliotecas...${NC}"
if [ -f /etc/ld.so.preload ]; then
    cat /etc/ld.so.preload 2>/dev/null
    echo -e "${RED}[!] Archivo ld.so.preload presente, posible rootkit.${NC}"
    found=$((found+1))
else
    echo "[+] No hay precarga sospechosa."
fi

# 8. Buscar módulos de kernel cargados inusuales
echo -e "\n${YELLOW}[8] Revisando módulos del kernel...${NC}"
lsmod | grep -E "bpf|ebpf|hidden|rootkit"
if [ $? -eq 0 ]; then
    echo -e "${RED}[!] Posible módulo kernel malicioso.${NC}"
    found=$((found+1))
fi

# 9. Buscar logs de auditoría con cambios en parámetros del kernel
echo -e "\n${YELLOW}[9] Revisando logs de auditoría recientes...${NC}"
if [ -f /var/log/audit/audit.log ]; then
    ausearch -ts recent -m kernel 2>/dev/null | grep -E "bpf|ebpf" | head -5
fi

# 10. Verificar integridad de binarios críticos (muy básico, requiere sumas precalculadas)
echo -e "\n${YELLOW}[10] Verificación rápida de integridad (ps, netstat, ss)...${NC}"
for cmd in ps netstat ss lsmod; do
    path=$(command -v $cmd 2>/dev/null)
    if [ -n "$path" ]; then
        echo "    $cmd -> $path"
        # No tenemos checksums de referencia, solo avisar si el tamaño es muy pequeño
        size=$(stat -c%s "$path" 2>/dev/null)
        if [ "$size" -lt 10000 ] 2>/dev/null; then
            echo -e "${RED}[!] $cmd tiene tamaño anormalmente pequeño ($size bytes). Posible reemplazo.${NC}"
            found=$((found+1))
        fi
    fi
done

echo "============================================"
if [ $found -gt 0 ]; then
    echo -e "${RED}[RESUMEN] Se encontraron $found indicios de posible infección por BPFdoor.${NC}"
    echo "[*] Recomendaciones:"
    echo "    1. Revisar manualmente los procesos y archivos listados."
    echo "    2. Usar 'bpftool prog list' y 'bpftool map list' para inspeccionar eBPF."
    echo "    3. Verificar el parámetro kernel: sysctl kernel.bpf_enable_unprivileged"
    echo "    4. Considerar el uso de Falco o auditd para monitoreo continuo."
    exit 1
else
    echo -e "${GREEN}[RESUMEN] No se encontraron indicios claros de BPFdoor.${NC}"
    echo "[*] Tenga en cuenta que el malware puede estar muy oculto. Revise periódicamente."
    exit 0
fi
