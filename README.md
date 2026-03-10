# APT41

**Salt Typhoon**, es parte de los multiples grupos de amenazas persistentes APT41 de China, tambien denoninado por otros analistas como: GhostEmperor, FamousSparrow, Earth Estrie, UNC2286, OPERATOR PANDA, RedMike, UNC5807, ..

se centra para el acceso inicial en Firewall VPN y otros equipos expuestos en el perimetro, como:  routers, switch, con vulnerabilidades CVE conocidas, de fácil explotación que permitan tomar acceso para luego moverse dentro de la red escalado de privilegios e ir consiguiendo persistencia. - El objetivo final es pasar desapercibido y exfiltrar información;  

1 - **Cisco: Routers, switches y firewall Cisco ASA con IOS XE y NX-OS**
    Vulnerabilidades: CVE-2023-20198, CVE-2023-20273, CVE-2025-20352, CVE-2019-1652, CVE-2019-1653
    Puertos: 80,161,443,500,1194,1500,1701,1723,4500,4786,51820

2 - **FW Fortinet VPN**
    Vulnerabilidad: CVE-2023-48788.
    Puertos: 80,161,443,8443,8013,10443

3 - **Sophos Firewall**
    Vulnerabilidad: CVE-2022-3236, CVE-2020-12271 (Asnarök), CVE-2020-15069, CVE-2020-29574
    Puertos: 80,443,4444

4 - **Citrix NetScaler Gateway**
    Vulnerabilidad: CVE-2025-5777 CitrixBleed 2, CVE-2019-19781 
    Puertos: 80,443,

5 - Ivanti VPN, Pulse VPN, Juniper VPN, routers Juniper SRX
    Vulnerabilidad: CVE-2025-5777, CVE-2023-46805, CVE-2024-21887, CVE-2025-22457
    Puertos: 80,443,

6 - Microsoft Exchange Server
    Vulnerabilidad: CVE-2021-26855, CVE-2021-26857, CVE-2021-26858, CVE-2021-27065
    Puertos: 80,443,

7 - WatchGuard Firewall
    Vulnerabilidad: CVE-2026-1498
    Puertos: 80,443,8080,4117

otras técnicas empleadas, son ataques de autenticación fuerza bruta; algunos de estos activos tienen a su vez expuestos servicios vulnerables, como telnet, ssh, rdp ..

en IKEv1, buscan credenciales que puedan exfiltrar, para acceso.

Linux sin soporte (CentOS 6.4)
