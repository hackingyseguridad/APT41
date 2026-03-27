Hackers del grupo ATP Chino Red Menshen. instalan puertas traseras BPFdoor sigilosas en redes de telecomunicaciones para obtener y disponer de acceso a largo plazo, con el malware BPFDoor
https://www.youtube.com/shorts/BTQX9oBn3dw
https://cybersecuritynews.com/bpfdoor-backdoors-telecom-networks/  
https://www.trendmicro.com/en_gb/research/23/g/detecting-bpfdoor-backdoor-variants-abusing-bpf-filters.html

estos entornos se basan en protocolos especializados como SS7 , Diameter y SCTP para gestionar la identidad, la movilidad y la conectividad global de los suscriptores, lo que los hace excepcionalmente valiosos para la recopilación de inteligencia, mucho más allá de lo que permite una filtración de datos convencional

BPFdoor: Una puerta trasera a nivel de kernel, imitan procesos legítimos en servidores bare-metal HPE ProLiant, suplantando específicamente a hpasmlited  ..  también emplea un canal de control basado en ICMP, donde los servidores comprometidos se transmiten comandos entre sí utilizando paquetes ICMP manipulados incrustados con el valor 0xFFFFFFFF como una señal terminal de "no reenviar", permitiendo la propagación lateral sin tráfico C2 estándar.

Una investigación de varios meses realizada por Rapid7 Labs ha expuesto una sofisticada campaña de espionaje patrocinada por el estado, llevada a cabo por el actor de amenazas vinculado a China, Red Menshen. Este grupo ha incrustado algunas de las "células durmientes" digitales más encubiertas jamás documentadas dentro de la infraestructura mundial de telecomunicaciones.

Publicados el 26 de marzo de 2026, los hallazgos revelan un cambio deliberado desde el hacking oportunista hacia un posicionamiento a largo plazo dentro de las mismas redes troncales que sostienen las comunicaciones nacionales e internacionales.

Las redes de telecomunicaciones transportan comunicaciones gubernamentales, autentican identidades de suscriptores, coordinan industrias críticas y procesan flujos de señalización a través de las fronteras nacionales.

En su núcleo, estos entornos dependen de protocolos especializados como SS7, Diameter y SCTP para gestionar la identidad, la movilidad y la conectividad global de los suscriptores, lo que los hace excepcionalmente valiosos para la recopilación de inteligencia, mucho más allá de lo que permite una violación de datos convencional.

El acceso persistente dentro del núcleo de una telecomunicación puede exponer identificadores de suscriptores, eventos de movilidad, intercambios de autenticación y metadatos de comunicación, permitiendo el seguimiento a gran escala de objetivos geopolíticos de alto valor.

Red Menshen ha atacado específicamente a proveedores de telecomunicaciones en Corea del Sur, Hong Kong, Myanmar, Malasia, Egipto y Oriente Medio, con un riesgo colateral que se extiende a las redes gubernamentales que dependen de esos operadores.

BPFdoor: Una puerta trampilla a nivel del kernel

En el centro de esta campaña se encuentra BPFdoor, una puerta trasera sigilosa para Linux diseñada para operar dentro del kernel del sistema operativo abusando de la funcionalidad Berkeley Packet Filter (BPF).

A diferencia del malware convencional, BPFdoor no abre puertos de escucha ni genera balizamiento visible de comando y control. En su lugar, instala un filtro BPF personalizado dentro del kernel que inspecciona silenciosamente el tráfico entrante, activándose solo cuando recibe un "paquete mágico" especialmente diseñado que contiene una secuencia de bytes predefinida. Herramientas como netstat, ss o nmap no muestran nada inusual; el sistema parece completamente limpio.

Rapid7 Labs identificó una variante de BPFdoor no documentada anteriormente que mejora significativamente sus capacidades de sigilo. En lugar de depender de un paquete mágico detectable, la variante actualizada ahora oculta los desencadenantes de comandos dentro del tráfico HTTPS legítimo, explotando puntos de terminación SSL como balanceadores de carga y proxies inversos para entregar comandos de activación después del descifrado en la zona de red interna.

Un sofisticado mecanismo de relleno de "regla mágica" asegura que una cadena marcadora ("9999") siempre caiga en un desplazamiento fijo de 26 o 40 bytes dentro de los datos de solicitud inspeccionados, permitiendo que el implante sobreviva a la reescritura de cabeceras del proxy, creando efectivamente un camuflaje dinámico en la capa 7.

La variante también emplea un canal de control basado en ICMP, donde los servidores comprometidos se transmiten comandos entre sí utilizando paquetes ICMP manipulados incrustados con el valor 0xFFFFFFFF como una señal terminal de "no reenviar", permitiendo la propagación lateral sin tráfico C2 estándar.

Suplantación a nivel de infraestructura

Algunas muestras de BPFdoor imitan procesos legítimos en servidores HPE ProLiant de metal desnudo, específicamente suplantando a hpasmlited, un demonio perteneciente al Servicio de Gestión sin Agente de HPE, para mezclarse en entornos de hardware de telecomunicaciones que ejecutan cargas de trabajo de núcleo 4G/5G.

Otras muestras suplantan a componentes de Docker y containerd, apuntando a funciones de núcleo 5G alojadas en Kubernetes como AMF, SMF y UDM.

El acceso inicial apunta consistentemente a infraestructura perimetral: VPNs Ivanti Connect Secure, dispositivos de red Cisco y Juniper, firewalls Fortinet y hosts VMware ESXi. Las herramientas posteriores a la explotación incluyen CrossC2, TinyShell, escáneres de fuerza bruta SSH y registradores de teclas ELF personalizados con listas de credenciales conscientes de telecomunicaciones que hacen referencia a términos como "imsi".

Rapid7 ha coordinado con los CERT nacionales y socios gubernamentales para notificar a las organizaciones afectadas. La firma lanzó un script de escaneo gratuito y de código abierto capaz de detectar variantes tanto antiguas como nuevas de BPFdoor para ayudar a las organizaciones en la validación rápida de exposición.

Se recomienda encarecidamente a los defensores ampliar la visibilidad de las operaciones a nivel del kernel, la actividad de filtros BPF sin procesar y el comportamiento anómalo en puertos altos en sistemas Linux, áreas donde la mayoría de las organizaciones carecen actualmente de una profundidad de monitoreo adecuada.

https://www.rapid7.com/blog/post/tr-bpfdoor-telecom-networks-sleeper-cells-threat-research-report/ 

Nueva variante más sigilosa: Los comandos de activación ya no se envían como "paquetes mágicos" fácilmente detectables, sino que se ocultan dentro del tráfico HTTPS legítimo, aprovechando los puntos de terminación SSL (como balanceadores de carga) para activarse tras el descifrado.

Camuflaje en capa 7: Utiliza un ingenioso mecanismo de "regla mágica" (un marcador como "9999" en un offset fijo de 26 o 40 bytes) para que el comando siga siendo reconocible incluso después de que el tráfico pase por proxies que reescriben las cabeceras HTTP.

Comunicación lateral con ICMP: Los servidores comprometidos pueden comunicarse entre sí usando paquetes ICMP personalizados con un valor específico (0xFFFFFFFF), permitiendo la propagación lateral sin generar tráfico de comando y control tradicional.

Suplantación de procesos legítimos: Los binarios maliciosos se hacen pasar por procesos típicos en entornos de telecomunicaciones, como el demonio de gestión de servidores HPE ProLiant (hpasmlited) o por componentes de Docker/containerd, mezclándose con las cargas de trabajo de núcleos 4G/5G.

Impacto y recomendaciones:
El acceso a estas redes permite a los atacantes espiar metadatos de suscriptores, flujos de señalización (SS7, Diameter, SCTP) y potencialmente rastrear la ubicación de dispositivos a nivel poblacional. Rapid7 ha publicado un script de detección gratuito y recomienda a los defensores ampliar la visibilidad hacia operaciones a nivel del kernel y el monitoreo de tráfico SCTP, áreas donde la mayoría de las organizaciones carecen de cobertura.

https://medium.com/s2wblog/detailed-analysis-of-bpfdoor-targeting-south-korean-company-328171880a98
https://www.fortinet.com/blog/threat-research/new-ebpf-filters-for-symbiote-and-bpfdoor-malware
https://www.youtube.com/watch?v=5kOQg-eCPu4





