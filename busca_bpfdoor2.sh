#!/bin/sh
# detect_bpfdoor_advanced.sh - Búsqueda exhaustiva de BPFdoor y variantes
# Uso: sh detect_bpfdoor_advanced.sh  (preferiblemente como root)

# Colores (si soporta)
if [ -t 1 ]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; NC=''
fi

TOTAL_HALLADOS=0
FECHA=$(date "+%Y-%m-%d %H:%M:%S")

echo "${BLUE}========================================${NC}"
echo "${BLUE}=== DETECTOR BPFDOOR - Red Menshen   ===${NC}"
echo "${BLUE}=== Fecha: $FECHA              ===${NC}"
echo "${BLUE}========================================${NC}"

# -------------------------------------------------------------------
# Función para reportar hallazgos
# -------------------------------------------------------------------
reportar() {
    echo "${RED}[!] $1${NC}"
    TOTAL_HALLADOS=$((TOTAL_HALLADOS + 1))
}

# -------------------------------------------------------------------
# 1. Verificar si se ejecuta como root (recomendado)
# -------------------------------------------------------------------
if [ "$(id -u)" != "0" ]; then
    echo "${YELLOW}[!] No se ejecuta como root. Algunas comprobaciones fallarán.${NC}"
else
    echo "${GREEN}[+] Ejecutando con privilegios root.${NC}"
fi

# -------------------------------------------------------------------
# 2. Procesos sospechosos (suplantación de HPE, Docker, systemd)
# -------------------------------------------------------------------
echo "\n${YELLOW}[2] Procesos en ejecución - Búsqueda de suplantación...${NC}"
PROCESOS_SOSPECHOSOS="hpasmlited|hpasmlited_|hplog|hpasm|hparray|agetty|auditd|systemd-journald|udevd|containerd-shim|dockerd|kubelet|amf|smf|udm"
ps aux 2>/dev/null | grep -E "$PROCESOS_SOSPECHOSOS" | grep -v grep | while read linea; do
    PID=$(echo "$linea" | awk '{print $2}')
    CMD=$(echo "$linea" | awk '{for(i=11;i<=NF;i++) printf "%s ", $i; print ""}')
    # Verificar si el binario existe en disco o es un proceso fantasma
    if [ ! -f "/proc/$PID/exe" ] 2>/dev/null; then
        reportar "Proceso $PID ($CMD) - Posible implante BPFdoor (no tiene binario en disco)"
    else
        BINARIO=$(readlink "/proc/$PID/exe" 2>/dev/null)
        if echo "$BINARIO" | grep -q "(deleted)"; then
            reportar "Proceso $PID ($CMD) - Binario eliminado, típico de malware"
        fi
    fi
done

# -------------------------------------------------------------------
# 3. Verificar BPF clásico (filtros de socket)
# -------------------------------------------------------------------
echo "\n${YELLOW}[3] Verificando filtros BPF activos...${NC}"
if [ -d "/proc/sys/net/core" ]; then
    SOCKET_FILTERS=$(find /proc -name "filter" -type f 2>/dev/null | head -20)
    if [ -n "$SOCKET_FILTERS" ]; then
        for filter in $SOCKET_FILTERS; do
            if [ -s "$filter" ] 2>/dev/null; then
                SIZE=$(stat -c%s "$filter" 2>/dev/null)
                if [ "$SIZE" -gt 0 ] 2>/dev/null; then
                    reportar "Filtro BPF encontrado en $filter (tamaño $SIZE bytes)"
                fi
            fi
        done
    fi
fi

# -------------------------------------------------------------------
# 4. Archivos en /dev/shm (memoria RAM) - típico de BPFdoor
# -------------------------------------------------------------------
echo "\n${YELLOW}[4] Revisando /dev/shm (archivos en RAM)...${NC}"
if [ -d "/dev/shm" ]; then
    ls -la /dev/shm/ 2>/dev/null | grep -v "^total" | while read archivo; do
        NOMBRE=$(echo "$archivo" | awk '{print $NF}')
        if [ -n "$NOMBRE" ] && [ "$NOMBRE" != "." ] && [ "$NOMBRE" != ".." ]; then
            reportar "Archivo en /dev/shm: $NOMBRE (posible malware en memoria)"
        fi
    done
fi

# -------------------------------------------------------------------
# 5. Módulos de kernel cargados inusuales
# -------------------------------------------------------------------
echo "\n${YELLOW}[5] Módulos del kernel cargados...${NC}"
lsmod 2>/dev/null | awk '{print $1}' | grep -v "^Module" | while read modulo; do
    # Verificar módulos sospechosos
    case $modulo in
        bpf*|ebpf*|rootkit*|hidden*|hide*|invisible*)
            reportar "Módulo kernel sospechoso: $modulo"
            ;;
        *)
            # Verificar módulos sin firma (si está disponible)
            if command -v modinfo >/dev/null 2>&1; then
                if modinfo "$modulo" 2>/dev/null | grep -q "signature"; then
                    if ! modinfo "$modulo" 2>/dev/null | grep -q "signature:.*OK"; then
                        reportar "Módulo $modulo sin firma válida o no firmado"
                    fi
                fi
            fi
            ;;
    esac
done

# -------------------------------------------------------------------
# 6. Verificar enlaces simbólicos sospechosos en /proc
# -------------------------------------------------------------------
echo "\n${YELLOW}[6] Verificando procesos ocultos...${NC}"
KNOWN_PIDS=$(ps aux 2>/dev/null | awk '{print $2}' | grep -v "^PID$" | grep -E "^[0-9]+$")
for pid in /proc/[0-9]*; do
    if [ -d "$pid" ]; then
        PID_NUM=$(basename "$pid")
        # Verificar si el PID está en la lista de ps
        if ! echo "$KNOWN_PIDS" | grep -q "^$PID_NUM$"; then
            reportar "Proceso oculto detectado: PID $PID_NUM (no aparece en ps)"
        fi
    fi
done

# -------------------------------------------------------------------
# 7. Verificar conexiones de red ICMP anómalas (raw sockets)
# -------------------------------------------------------------------
echo "\n${YELLOW}[7] Verificando sockets ICMP y RAW...${NC}"
if command -v netstat >/dev/null 2>&1; then
    netstat -lpn 2>/dev/null | grep -E "raw|icmp" | while read linea; do
        PID=$(echo "$linea" | awk '{print $NF}' | cut -d'/' -f1)
        if [ -n "$PID" ] && [ "$PID" != "-" ]; then
            reportar "Socket RAW/ICMP detectado: $linea"
        fi
    done
fi

# -------------------------------------------------------------------
# 8. Verificar archivos temporales en /tmp y /var/tmp
# -------------------------------------------------------------------
echo "\n${YELLOW}[8] Buscando archivos temporales sospechosos...${NC}"
for tmpdir in /tmp /var/tmp; do
    if [ -d "$tmpdir" ]; then
        find "$tmpdir" -type f -name ".*" -o -name "*.tmp" -o -name "*.sh" -o -name "*.elf" 2>/dev/null | while read archivo; do
            if [ -f "$archivo" ]; then
                # Verificar si es un binario ELF
                if file "$archivo" 2>/dev/null | grep -q "ELF"; then
                    reportar "Binario ELF en $tmpdir: $archivo (posible malware)"
                fi
                # Verificar tamaño sospechoso
                SIZE=$(stat -c%s "$archivo" 2>/dev/null)
                if [ -n "$SIZE" ] && [ "$SIZE" -gt 10000 ] 2>/dev/null && [ "$SIZE" -lt 500000 ] 2>/dev/null; then
                    reportar "Archivo sospechoso en $tmpdir: $archivo ($SIZE bytes)"
                fi
            fi
        done
    fi
done

# -------------------------------------------------------------------
# 9. Verificar /etc/ld.so.preload (rootkit)
# -------------------------------------------------------------------
echo "\n${YELLOW}[9] Verificando precarga de bibliotecas...${NC}"
if [ -f "/etc/ld.so.preload" ]; then
    CONTENIDO=$(cat /etc/ld.so.preload 2>/dev/null)
    if [ -n "$CONTENIDO" ]; then
        reportar "Archivo /etc/ld.so.preload presente con contenido: $CONTENIDO"
    fi
fi

# -------------------------------------------------------------------
# 10. Verificar variables de entorno sospechosas
# -------------------------------------------------------------------
echo "\n${YELLOW}[10] Verificando variables de entorno...${NC}"
env | grep -E "LD_PRELOAD|LD_LIBRARY_PATH|BPF|EBPF" | while read var; do
    reportar "Variable de entorno sospechosa: $var"
done

# -------------------------------------------------------------------
# 11. Verificar cron jobs inusuales
# -------------------------------------------------------------------
echo "\n${YELLOW}[11] Verificando cron jobs...${NC}"
for cronfile in /etc/crontab /var/spool/cron/crontabs/* /etc/cron.d/*; do
    if [ -f "$cronfile" ]; then
        grep -v "^#" "$cronfile" 2>/dev/null | grep -E "hpasmlited|bpf|icmp|raw|socket|backdoor|shell" | while read linea; do
            reportar "Cron job sospechoso en $cronfile: $linea"
        done
    fi
done

# -------------------------------------------------------------------
# 12. Verificar syscalls hooking (avanzado)
# -------------------------------------------------------------------
echo "\n${YELLOW}[12] Verificando posibles hooks en syscalls...${NC}"
if [ -d "/proc/kallsyms" ] 2>/dev/null || [ -f "/proc/kallsyms" ]; then
    grep -E "sys_call_table|sys_open|sys_read|sys_write|sys_bpf" /proc/kallsyms 2>/dev/null | head -20
fi

# -------------------------------------------------------------------
# 13. Verificar tráfico ICMP en logs (si hay tcpdump)
# -------------------------------------------------------------------
echo "\n${YELLOW}[13] Verificando logs de red (últimas líneas)...${NC}"
if command -v tcpdump >/dev/null 2>&1; then
    TIMEOUT_CMD=""
    if command -v timeout >/dev/null 2>&1; then
        TIMEOUT_CMD="timeout 3"
    fi
    $TIMEOUT_CMD tcpdump -i any -c 50 'icmp' -n 2>/dev/null | grep -E "length [5-9][0-9]|length 1[0-9][0-9]|FFFFFFFF|ffffffff" | while read paquete; do
        reportar "Paquete ICMP anómalo: $paquete"
    done
else
    echo "    tcpdump no disponible para captura"
fi

# -------------------------------------------------------------------
# 14. Verificar procesos con nombres extraños (desde /proc)
# -------------------------------------------------------------------
echo "\n${YELLOW}[14] Verificando nombres de procesos inusuales...${NC}"
for pid in /proc/[0-9]*; do
    if [ -d "$pid" ]; then
        CMDLINE=$(cat "$pid/cmdline" 2>/dev/null | tr '\0' ' ')
        if [ -n "$CMDLINE" ]; then
            # Procesos con nombres cortos o raros
            NOMBRE=$(echo "$CMDLINE" | awk '{print $1}')
            if [ ${#NOMBRE} -lt 3 ] 2>/dev/null && [ -n "$NOMBRE" ]; then
                reportar "Proceso con nombre muy corto: PID $(basename $pid) -> $CMDLINE"
            fi
            # Procesos con caracteres no imprimibles
            if echo "$CMDLINE" | grep -q "[^a-zA-Z0-9./_-]"; then
                reportar "Proceso con caracteres extraños: PID $(basename $pid) -> $CMDLINE"
            fi
        fi
    fi
done

# -------------------------------------------------------------------
# 15. Verificar montajes sospechosos
# -------------------------------------------------------------------
echo "\n${YELLOW}[15] Verificando sistemas de archivos montados...${NC}"
mount 2>/dev/null | grep -E "noexec|nosuid|tmpfs" | while read linea; do
    if echo "$linea" | grep -q "/dev/shm"; then
        echo "    $linea (normal)"
    elif echo "$linea" | grep -q "tmpfs"; then
        echo "    $linea (verificar)"
    fi
done

# -------------------------------------------------------------------
# 16. Verificar archivos .so inyectables en /lib
# -------------------------------------------------------------------
echo "\n${YELLOW}[16] Buscando bibliotecas sospechosas...${NC}"
find /lib /lib64 /usr/lib -name "lib*.so" -type f 2>/dev/null | while read lib; do
    # Verificar bibliotecas con nombres extraños
    BASENAME=$(basename "$lib")
    case $BASENAME in
        libhook*|libhide*|libbpf*|librootkit*)
            reportar "Biblioteca sospechosa: $lib"
            ;;
        *)
            # Verificar si es un binario ELF sin símbolos
            if file "$lib" 2>/dev/null | grep -q "ELF" && ! nm "$lib" 2>/dev/null | grep -q "T "; then
                reportar "Biblioteca sin símbolos (posible rootkit): $lib"
            fi
            ;;
    esac
done

# -------------------------------------------------------------------
# 17. Verificar interfaces de red en modo promiscuo
# -------------------------------------------------------------------
echo "\n${YELLOW}[17] Verificando interfaces en modo promiscuo...${NC}"
if command -v ip >/dev/null 2>&1; then
    ip link 2>/dev/null | grep PROMISC | while read linea; do
        reportar "Interfaz en modo promiscuo: $linea"
    done
fi

# -------------------------------------------------------------------
# 18. Verificar reglas de iptables anómalas
# -------------------------------------------------------------------
echo "\n${YELLOW}[18] Verificando reglas iptables...${NC}"
if command -v iptables >/dev/null 2>&1; then
    iptables -L -n 2>/dev/null | grep -E "ACCEPT.*0.0.0.0/0|DROP.*0.0.0.0/0" | while read regla; do
        echo "    $regla"
    done
fi

# -------------------------------------------------------------------
# 19. Verificar sysctl parameters (bpf_enable_unprivileged)
# -------------------------------------------------------------------
echo "\n${YELLOW}[19] Verificando parámetros de kernel...${NC}"
if [ -f "/proc/sys/kernel/bpf_enable_unprivileged" ]; then
    VALOR=$(cat /proc/sys/kernel/bpf_enable_unprivileged 2>/dev/null)
    if [ "$VALOR" = "1" ]; then
        reportar "Usuarios sin privilegios pueden cargar programas BPF (bpf_enable_unprivileged=1)"
    fi
fi

# -------------------------------------------------------------------
# 20. Verificar puertos abiertos inusuales (aunque BPFdoor no abre puertos)
# -------------------------------------------------------------------
echo "\n${YELLOW}[20] Verificando puertos abiertos...${NC}"
if command -v netstat >/dev/null 2>&1; then
    netstat -tuln 2>/dev/null | grep -E "LISTEN" | while read puerto; do
        PUERTO_NUM=$(echo "$puerto" | awk '{print $4}' | cut -d':' -f2)
        if [ -n "$PUERTO_NUM" ]; then
            case $PUERTO_NUM in
                53|80|443|22|25|21|110|143|993|995|3306|5432|8080|8443)
                    # Puertos comunes, ignorar
                    ;;
                *)
                    echo "    Puerto abierto: $puerto (verificar si es legítimo)"
                    ;;
            esac
        fi
    done
fi

# -------------------------------------------------------------------
# RESUMEN FINAL
# -------------------------------------------------------------------
echo "\n${BLUE}========================================${NC}"
if [ $TOTAL_HALLADOS -gt 0 ]; then
    echo "${RED}[RESUMEN] Se encontraron $TOTAL_HALLADOS indicios de posible infección.${NC}"
    echo "${YELLOW}Recomendaciones:${NC}"
    echo "  1. Analizar manualmente los procesos listados con 'strace -p <PID>'"
    echo "  2. Revisar programas BPF: 'bpftool prog list' y 'bpftool map list'"
    echo "  3. Deshabilitar BPF no privilegiado: 'sysctl kernel.bpf_enable_unprivileged=0'"
    echo "  4. Considerar reinstalar el sistema si se confirma infección"
    exit 1
else
    echo "${GREEN}[RESUMEN] No se encontraron indicios claros de BPFdoor.${NC}"
    echo "${YELLOW}Nota: BPFdoor está diseñado para ser invisible.${NC}"
    echo "  Monitoreo adicional recomendado:"
    echo "  - Usar Falco para detección de comportamiento"
    echo "  - Auditar syscalls con auditd"
    echo "  - Revisar periódicamente los filtros BPF"
    exit 0
fi
