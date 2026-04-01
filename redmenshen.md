<img style="float:left" alt="0" src="https://github.com/hackingyseguridad/APT41/blob/main/0.png">

### 1. El Objetivo: Inteligencia de Telecomunicaciones
a diferencia de los ciberataques comunes que buscan robo de datos financieros, Red Menshen busca **acceso a largo plazo** para la recolección de inteligencia geopolítica.
**Protocolos Críticos:** Se enfocan en protocolos de señalización como **SS7, Diameter y SCTP**. Estos gestionan la movilidad, identidad y conectividad global de los suscriptores.
**Impacto:** Al controlar estos nodos, pueden rastrear ubicaciones, interceptar metadatos de comunicación y vigilar objetivos gubernamentales o diplomáticos de alto valor.

Hackers del grupo ATP Chino Red Menshen. instalan puertas traseras BPFdoor sigilosas en redes de telecomunicaciones para obtener y disponer de acceso a largo plazo, con el malware BPFDoor subsistema Berkeley Packet Filter (BPF)

<img style="float:left" alt="1" src="https://github.com/hackingyseguridad/APT41/blob/main/1.png">

estos entornos se basan en protocolos especializados como SS7 , Diameter y SCTP para gestionar la identidad, la movilidad y la conectividad global de los suscriptores, lo que los hace excepcionalmente valiosos para la recopilación de inteligencia, mucho más allá de lo que permite una filtración de datos convencional

### 2. El Malware: BPFdoor
El corazón de la operación es **BPFdoor**, una puerta trasera (backdoor) para Linux extremadamente sigilosa que opera a nivel de **kernel**.

**Abuso de BPF (Berkeley Packet Filter):** Utiliza esta tecnología del kernel para inspeccionar el tráfico de red sin abrir puertos de escucha. Esto significa que herramientas como `netstat`, `ss` o `nmap` no detectan nada inusual; el sistema parece "limpio".
**El "Paquete Mágico":** El implante permanece dormido hasta que recibe un paquete especialmente diseñado con una secuencia de bytes específica (un "paquete mágico"). Al detectarlo, el malware activa una terminal de comandos (*shell*) para el atacante.
**Evasión de Firewall:** Como el filtro BPF actúa a un nivel muy bajo en el núcleo, puede ver y procesar el paquete antes de que el firewall local del sistema operativo tenga oportunidad de bloquearlo.


**BPFdoor:** Una puerta trasera a nivel de kernel, imitan procesos legítimos en servidores bare-metal HPE ProLiant, suplantando específicamente a hpasmlited  ..  también emplea un canal de control basado en ICMP, donde los servidores comprometidos se transmiten comandos entre sí utilizando paquetes ICMP manipulados incrustados con el valor 0xFFFFFFFF como una señal terminal de "no reenviar", permitiendo la propagación lateral sin tráfico C2 estándar.

Una investigación de varios meses realizada por Rapid7 Labs ha expuesto una sofisticada campaña de espionaje patrocinada por el estado, llevada a cabo por el actor de amenazas vinculado a China, Red Menshen. Este grupo ha incrustado algunas de las "células durmientes" digitales más encubiertas jamás documentadas dentro de la infraestructura mundial de telecomunicaciones.
https://www.rapid7.com/blog/post/tr-bpfdoor-telecom-networks-sleeper-cells-threat-research-report/ 
Publicados el 26 de marzo de 2026, los hallazgos revelan un cambio deliberado desde el hacking oportunista hacia un posicionamiento a largo plazo dentro de las mismas redes troncales que sostienen las comunicaciones nacionales e internacionales.

Las redes de telecomunicaciones transportan comunicaciones gubernamentales, autentican identidades de suscriptores, coordinan industrias críticas y procesan flujos de señalización a través de las fronteras nacionales.

<img style="float:left" alt="2" src="https://github.com/hackingyseguridad/APT41/blob/main/2.png">

**eBPF significa Filtro de Paquetes Berkeley Extendido.** Es una extensión del diseño original del Filtro de Paquetes Berkeley (BPF).
eBPF permite a los usuarios instalar código de forma dinámica que se ejecuta en el contexto del kernel, pero que se gestiona desde el espacio de usuario. Es una especie de híbrido entre las aplicaciones de espacio de usuario y los módulos del kernel de Linux. BPFDoor utiliza filtros de socket para permitir comunicaciones sigilosas. Puede recibir comandos en cualquier puerto del sistema, ya que el programa eBPF que utiliza ve todo el tráfico entrante. Symbiote también aprovecha los filtros de socket, pero de una manera diferente. Symbiote intercepta la setsockoptllamada a la función y, cuando ve la creación de un filtro de socket, inyecta su propio código para filtrar el tráfico que quiere ocultar. Esto le permite evadir herramientas de análisis de paquetes como tcpdump, wiresark,.

**Filtros de paquetes de Berkeley (BPF)**, ejemplo, llamadas tambien expresiones: 
<img style="float:left" alt="3" src="https://github.com/hackingyseguridad/APT41/blob/main/3.png">

**Abuso de Berkeley Packet Filter (BPF)** BPF es una tecnología del kernel que permite ejecutar código de forma segura en respuesta a eventos de red. Tradicionalmente se usa para herramientas como tcpdump.
BPFdoor abusa de esta funcionalidad al inyectar un filtro BPF personalizado directamente en el kernel. Este filtro inspecciona silenciosamente todo el tráfico entrante sin necesidad de:
Abrir puertos de escucha (no aparece en netstat o ss).
Generar tráfico de comando y control (C2) visible.
Dejar procesos en espacio de usuario que puedan ser detectados fácilmente.

<img style="float:left" alt="1" src="https://github.com/hackingyseguridad/APT41/blob/main/4.png">

**cómo actúa el implante malicioso:**
-Victim Linux Host (Host Linux Víctima): El atacante ha instalado un "BPF Implant".
-Magic Packet (Paquete Mágico): El Attacker/Controller (Atacante/Controlador) envía un paquete especial diseñado para activar el malware.
-BPF Filter (Magic Packet Pattern): El malware utiliza un filtro BPF que busca específicamente el patrón de ese "paquete mágico". Como este filtrado ocurre a un nivel muy bajo en el núcleo (Kernel), puede ver el paquete antes de que cualquier firewall local lo bloquee.
-Activate Bind Shell or Reverse Shell: Una vez detectado el paquete, el implante activa una terminal de comandos (Shell) para que el atacante tome el control.

En su núcleo, estos entornos dependen de protocolos especializados como SS7, Diameter y SCTP para gestionar la identidad, la movilidad y la conectividad global de los suscriptores, lo que los hace excepcionalmente valiosos para la recopilación de inteligencia, mucho más allá de lo que permite una violación de datos convencional.

El acceso persistente dentro del núcleo de un operador telecomunicación puede exponer identificadores de suscriptores, eventos de movilidad, intercambios de autenticación y metadatos de comunicación, permitiendo el seguimiento a gran escala de objetivos geopolíticos de alto valor.

Red Menshen ha atacado específicamente a proveedores de telecomunicaciones en Corea del Sur, Hong Kong, Myanmar, Malasia, Egipto y Oriente Medio, con un riesgo colateral que se extiende a las redes gubernamentales que dependen de esos operadores.

**BPFdoor: Una puerta trampilla a nivel del kernel**

En el centro de esta campaña se encuentra BPFdoor, una puerta trasera sigilosa para Linux diseñada para operar dentro del kernel del sistema operativo abusando de la funcionalidad Berkeley Packet Filter (BPF).  BPFdoor usa principalmente BPF clásico (más simple pero efectivo para persistencia), mientras que variantes más modernas como Symbiote usan eBPF para mayor complejidad.

**Paquete maquico,** a diferencia del malware convencional, BPFdoor no abre puertos de escucha ni genera balizamiento visible de comando y control. En su lugar, **instala un filtro BPF personalizado dentro del kernel que inspecciona silenciosamente el tráfico entrante, activándose solo cuando recibe un "paquete mágico"** especialmente diseñado que contiene una secuencia de bytes predefinida. Herramientas como netstat, ss o nmap no muestran nada inusual; el sistema parece completamente limpio.


### 3. Técnicas Avanzadas de Sigilo y Camuflaje
El informe de Rapid7 Labs destaca una evolución en las tácticas del grupo:
**Ocultamiento en HTTPS:** Las versiones más nuevas esconden sus comandos dentro de tráfico HTTPS legítimo. Aprovechan puntos de terminación SSL (como balanceadores de carga) para activarse justo después de que el tráfico es descifrado en la red interna.
**Regla Mágica (Offset Fixo):** Utilizan un marcador ("9999") en desplazamientos fijos de 26 o 40 bytes para asegurar que el comando sobreviva a la reescrita de cabeceras de los proxies.
**Propagación Lateral vía ICMP:** Los servidores ya comprometidos se comunican entre sí mediante paquetes ICMP (pings) manipulados con el valor `0xFFFFFFFF`. Esto permite saltar entre zonas de red (de la DMZ al Core) sin generar tráfico de Comando y Control (C2) detectable.

Nueva variante más sigilosa: Los comandos de activación ya no se envían como **"paquetes mágicos"** fácilmente detectables, sino que se ocultan dentro del tráfico HTTPS legítimo, aprovechando los puntos de terminación SSL (como balanceadores de carga) para activarse tras el descifrado.

Rapid7 Labs identificó una variante de BPFdoor no documentada anteriormente que mejora significativamente sus capacidades de sigilo. En lugar de depender de un paquete mágico detectable, la variante actualizada ahora oculta los desencadenantes de comandos dentro del tráfico HTTPS legítimo, explotando puntos de terminación SSL como balanceadores de carga y proxies inversos para entregar comandos de activación después del descifrado en la zona de red interna.

Un sofisticado mecanismo de relleno de **"regla mágica"** asegura que una cadena marcadora ("9999") siempre caiga en un desplazamiento fijo de 26 o 40 bytes dentro de los datos de solicitud inspeccionados, permitiendo que el implante sobreviva a la reescritura de cabeceras del proxy, creando efectivamente un camuflaje dinámico en la capa 7.

Camuflaje en capa 7: Utiliza un ingenioso mecanismo de "regla mágica" (un marcador como "9999" en un offset fijo de 26 o 40 bytes) para que el comando siga siendo reconocible incluso después de que el tráfico pase por proxies que reescriben las cabeceras HTTP.

La variante también emplea un canal de control basado en ICMP, donde los servidores comprometidos se transmiten comandos entre sí utilizando paquetes ICMP manipulados incrustados con el valor 0xFFFFFFFF como una señal terminal de "no reenviar", permitiendo la propagación lateral sin tráfico C2 estándar.

<img style="float:left" alt="5" src="https://github.com/hackingyseguridad/APT41/blob/main/5.png">

Comunicación lateral con ICMP: **Los servidores comprometidos pueden comunicarse entre sí usando paquetes ICMP** personalizados con un valor específico (0xFFFFFFFF), permitiendo la propagación lateral sin generar tráfico de comando y control tradicional.

protocolo ICMP (Internet Control Message Protocol) generalmente utilizado para diagnósticos simples como ping para transportar datos maliciosos y comandos. El malware abre un "raw socket" que le permite ver todos los paquetes que llegan a la interfaz de red antes de que el firewall local del sistema operativo los procese. Puede responder a paquetes ICMP manipulados incluso si el firewall está configurado para bloquear todo el tráfico entrante, ya que el filtro BPF "secuestra" el paquete antes de que el kernel lo descarte

Flujo de Ataque: Del L1 al Núcleo Aislado (L3)El ataque se divide en capas para alcanzar el HSS (Home Subscriber Server) en el núcleo aislado, un componente crítico en redes de telecomunicaciones.PasoAcciónDescripción Técnica1 & 2Acceso InicialEl atacante toma control del Nodo B (Servidor Interno) a través de un Proxy inverso (Nodo A). Se prepara un listener (nc -lvnp 9000) para recibir la shell.3 & 4Activación del TúnelEl controlador envía una señal al Nodo B. El implante intercepta esta señal y genera un ICMP Echo Request (Ping) hacia el Nodo C.5Propagación LateralEl Nodo C (también infectado) recibe el paquete ICMP. Al detectar la firma maliciosa en el payload, ejecuta una shell y la "devuelve" al Nodo B, permitiendo al atacante operar en la capa L3.

El valor hexadecimal 0xFFFFFFFF actúa como un carácter de escape o terminación. Indica al implante que el comando ha llegado a su destino final y no debe seguir saltando a otros nodos. Esto evita bucles infinitos y reduce el "ruido" en la red, haciendo que el tráfico parezca una serie de pings normales y no un escaneo de red o una exfiltración masiva. 0xFFFFFFFF. Sería bueno aclarar que esto se inserta en el Payload (datos) del paquete ICMP Echo Request, no en la cabecera estándar, lo que lo hace pasar desapercibido para firewalls que solo miran cabeceras.
ICMP  esta permitido incluso entre redes, para monitoreo de disponibilidad, considerándolo de bajo riesgo; "salta" de la zona desmilitarizada (DMZ) al núcleo de la red (Core) usando los mismos canales que usan las herramientas de red legítimas.

tshark -i eth0 -Y "icmp.type == 8" -T fields -e data | grep "ffffffff"

**Suplantación a nivel de infraestructura**
Algunas muestras de BPFdoor imitan procesos legítimos en servidores HPE ProLiant (software de HPÊ para monitorizar procesos), específicamente suplantando a **hpasmlited**, un proceso perteneciente al Servicio de Gestión sin Agente de HPE, para meterse en entornos de hardware de telecomunicaciones que ejecutan cargas de trabajo de núcleo 4G/5G.

Otras muestras suplantan a componentes de **Docker y containerd**, apuntando a funciones de núcleo 5G alojadas en Kubernetes como AMF, SMF y UDM.

<img style="float:left" alt="6" src="https://github.com/hackingyseguridad/APT41/blob/main/6.png">

### 4. Suplantación de Infraestructura
Para evitar ser detectados por administradores de sistemas, el malware imita procesos legítimos:
* En servidores **HPE ProLiant**, se hace pasar por el proceso `hpasmlited` (un servicio de gestión de hardware).
* En entornos de nube, suplanta componentes de **Docker, containerd y Kubernetes** (AMF, SMF, UDM), apuntando específicamente a las funciones del núcleo de las redes 5G.

### 5. Acceso inicial
**Acceso Inicial:** Suelen entrar explotando vulnerabilidades en dispositivos perimetrales como VPNs Ivanti, firewalls Fortinet, routers Cisco/Juniper y servidores VMware ESXi.
**Defensa:** Se recomienda a los administradores de red ampliar la visibilidad hacia operaciones a nivel de kernel y monitorear el tráfico anómalo en protocolos SCTP e ICMP, donde el malware suele ocultar sus movimientos.

El acceso a estas redes permite a los atacantes espiar metadatos de suscriptores, flujos de señalización (SS7, Diameter, SCTP) y potencialmente rastrear la ubicación de dispositivos a nivel poblacional. Rapid7 ha publicado un script de detección gratuito y recomienda a los defensores ampliar la visibilidad hacia operaciones a nivel del kernel y el monitoreo de tráfico SCTP, áreas donde la mayoría de las organizaciones carecen de cobertura.

**El acceso inicial** apunta consistentemente a infraestructura perimetral: VPNs Ivanti Connect Secure, dispositivos de red Cisco y Juniper, firewalls Fortinet y hosts VMware ESXi. Las herramientas posteriores a la explotación incluyen CrossC2, TinyShell, escáneres de fuerza bruta SSH y registradores de teclas ELF personalizados con listas de credenciales conscientes de telecomunicaciones que hacen referencia a términos como "imsi".


Rapid7 ha coordinado con los CERT nacionales y socios gubernamentales para notificar a las organizaciones afectadas. La firma lanzó un script de escaneo gratuito y de código abierto capaz de detectar variantes tanto antiguas como nuevas de BPFdoor para ayudar a las organizaciones en la validación rápida de exposición.

<img style="float:left" alt="7" src="https://github.com/hackingyseguridad/APT41/blob/main/7.png">


Referencias:

https://www.rapid7.com/blog/post/tr-bpfdoor-telecom-networks-sleeper-cells-threat-research-report/ 
https://medium.com/s2wblog/detailed-analysis-of-bpfdoor-targeting-south-korean-company-328171880a98
https://hackers-arise.com/compromising-telecom-systems-deploying-and-detecting-the-bpfdoor-backdoor/
https://www.fortinet.com/blog/threat-research/new-ebpf-filters-for-symbiote-and-bpfdoor-malware
https://www.youtube.com/watch?v=5kOQg-eCPu4
https://www.youtube.com/shorts/BTQX9oBn3dw
https://cybersecuritynews.com/bpfdoor-backdoors-telecom-networks/  
https://www.trendmicro.com/en_gb/research/23/g/detecting-bpfdoor-backdoor-variants-abusing-bpf-filters.html
https://suzulabs.com/suzu-labs-blog/bpfdoor-in-telecom-networks-the-fcc-is-securing-the-edge-but-chinas-hackers-are-already-past-it





