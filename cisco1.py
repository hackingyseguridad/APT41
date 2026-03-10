#!/usr/bin/env python3
"""
Script unificado de detección para vulnerabilidades Cisco.
Propósito: Identificar dispositivos potencialmente vulnerables mediante
checks no intrusivos (banners, respuestas HTTP).
Uso: python3 cisco_vuln_scanner.py <target_ip> [target_ip ...]
"""

import requests
import sys
import socket
import argparse
from requests.packages.urllib3.exceptions import InsecureRequestWarning

# Suprimir warnings de certificados SSL no verificados
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

# Colores para output
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
RESET = "\033[0m"

def print_result(vuln_id, target, status, details=""):
    """Formatea la salida de los resultados."""
    if status == "VULNERABLE":
        print(f"{GREEN}[+]{RESET} {vuln_id} - {target} - {YELLOW}{status}{RESET} - {details}")
    elif status == "POTENCIAL":
        print(f"{YELLOW}[?]{RESET} {vuln_id} - {target} - {status} - {details}")
    else:
        print(f"{RED}[-]{RESET} {vuln_id} - {target} - {status} - {details}")

def check_cve_2023_20198(target, port, ssl):
    """Detecta CVE-2023-20198 y CVE-2023-20273 (Web UI)."""
    protocol = "https" if ssl else "http"
    url = f"{protocol}://{target}:{port}"
    check_path = "/webui/logout.html"  # Un endpoint conocido del Web UI

    try:
        response = requests.get(f"{url}{check_path}", verify=False, timeout=5)
        # Si el web UI respide, es potencialmente vulnerable si está en versiones afectadas.
        # Una comprobación más profunda (pero más intrusiva) sería intentar crear un usuario.
        if response.status_code == 200:
            # Intentar obtener la versión del header 'Server'
            server_header = response.headers.get('Server', '')
            if 'IOS-XE' in server_header:
                print_result("CVE-2023-20198/273", f"{url}", "POTENCIAL",
                             f"Web UI accesible. Versión: {server_header}. Requiere verificación manual de versión.")
            else:
                print_result("CVE-2023-20198/273", f"{url}", "POTENCIAL",
                             "Web UI accesible. Versión no identificada.")
        else:
            print_result("CVE-2023-20198/273", f"{url}", "NO DETECTADO",
                         f"Web UI no responde (código {response.status_code}) o no accesible.")

    except requests.exceptions.ConnectionError:
        print_result("CVE-2023-20198/273", f"{url}", "NO DETECTADO", "Conexión rechazada.")
    except Exception as e:
        print_result("CVE-2023-20198/273", f"{url}", "ERROR", str(e))

def check_cve_2019_1653(target, port, ssl):
    """Detecta CVE-2019-1653 (RV320/RV325 - Config dump)."""
    protocol = "https" if ssl else "http"
    url = f"{protocol}://{target}:{port}"
    config_path = "/cgi-bin/config.exp"  # Endpoint que expone la configuración

    try:
        response = requests.get(f"{url}{config_path}", verify=False, timeout=5)
        if response.status_code == 200 and "valid configuration" in response.text.lower():
            print_result("CVE-2019-1653", f"{url}", "VULNERABLE",
                         "El endpoint /cgi-bin/config.exp expone la configuración.")
        else:
            print_result("CVE-2019-1653", f"{url}", "NO DETECTADO",
                         "Endpoint no disponible o no vulnerable.")
    except Exception as e:
        print_result("CVE-2019-1653", f"{url}", "ERROR", str(e))

def check_cve_2025_20352(target):
    """Detecta CVE-2025-20352 mediante un banner grab de SNMP."""
    port = 161
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.settimeout(3)
        # Paquete SNMP GetRequest para la comunidad 'public' (la más común)
        packet = bytes.fromhex("302902010104067075626c6963a01c0204567c12340201000201003010300e06082b060102010101000500")
        sock.sendto(packet, (target, port))
        data, addr = sock.recvfrom(1024)
        sock.close()

        # Si recibimos respuesta, SNMP está abierto y podría ser vulnerable.
        print_result("CVE-2025-20352", f"{target}", "POTENCIAL",
                     "SNMP (161/udp) responde. Requiere verificar version y comunidad para explotación.")
    except socket.timeout:
        print_result("CVE-2025-20352", f"{target}", "NO DETECTADO", "SNMP no responde.")
    except Exception as e:
        print_result("CVE-2025-20352", f"{target}", "ERROR", str(e))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Escáner de detección para múltiples CVEs de Cisco.")
    parser.add_argument("targets", nargs="+", help="Direcciones IP de los objetivos.")
    parser.add_argument("--port", type=int, default=443, help="Puerto para pruebas HTTP/HTTPS (default: 443).")
    parser.add_argument("--no-ssl", action="store_false", dest="ssl", help="Usar HTTP en lugar de HTTPS.")
    args = parser.parse_args()

    for target in args.targets:
        print(f"\n{YELLOW}--- Escaneando objetivo: {target} ---{RESET}")
        check_cve_2023_20198(target, args.port, args.ssl)
        check_cve_2019_1653(target, args.port, args.ssl)
        check_cve_2025_20352(target)
        # Nota: CVE-2019-1652 requiere autenticación, por lo que no se puede detectar pasivamente.
