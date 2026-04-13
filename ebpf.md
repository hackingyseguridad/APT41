eBPF: (Extended Berkeley Packet Filter) es una tecnología en el kernel de Linux que permite ejecutar programas personalizados dentro del núcleo del sistema operativo sin necesidad de cambiar el código fuente ni reiniciar. Es como añadir "sensores" inteligentes que pueden observar y actuar sobre todo lo que ocurre en el motor del ordenador de forma segura y extremadamente rápida.?El malware avanzado utiliza eBPF para una técnica llamada manipulación de visibilidad, actuando como un filtro invisible entre el sistema y el usuario:Intercepción (Hooking): El malware se "engancha" a las funciones del kernel que gestionan la red o el sistema de archivos.Filtrado Selectivo: Cuando una herramienta de seguridad (como un antivirus o un monitor de red) pide datos, el programa eBPF intercepta esa información antes de que salga del núcleo.Alteración de Datos: El programa busca cualquier rastro de su propia actividad (una dirección IP específica, un archivo o un proceso) y lo elimina de los resultados en tiempo real.
3. Ejemplo de funcionamiento:AcciónIntervención del Malware eBPFResultado para el UsuarioTráfico de RedIdentifica paquetes de la IP del atacante y los oculta.Los logs de red parecen limpios.Listar ArchivosBorra el nombre del archivo malicioso de la lista.La carpeta parece no tener nada sospechoso.Monitor de ProcesosOculta el ID del proceso del malware. El malware no aparece en el "Administrador de Tareas".
4. ¿Por qué es tan peligroso?Dado que estos programas corren dentro del núcleo (kernel), tienen una autoridad superior a la mayoría de las herramientas de seguridad tradicionales. Si el malware consigue cargar un programa eBPF con privilegios de administrador, se vuelve virtualmente invisible, ya que "engaña" a las herramientas de observación desde la raíz del sistema.
Los atacantes suelen explotar vulnerabilidades de escalada de privilegios para obtener acceso de nivel root, ya que el kernel está protegido contra usuarios comunes. Una vez dentro, utilizan las siguientes técnicas para manipular el MPF (Multi-Processor Floating pointer) o filtrar rutas:

Técnicas de Infiltración y Modificación:
Rootkits de Kernel (LKM): Cargan "Linux Kernel Modules" maliciosos que interceptan llamadas al sistema (syscall hooking). Esto les permite alterar lo que el sistema operativo "ve", ocultando archivos o procesos antes de que lleguen al espacio de usuario.
Manipulación de /proc y /sys: Si tienen permisos de escritura, modifican estos sistemas de archivos virtuales para cambiar parámetros de red y memoria en tiempo real sin reiniciar.
Direct Kernel Object Manipulation (DKOM): Acceden directamente a la memoria /dev/mem para modificar estructuras de datos del kernel, permitiendo saltarse filtros de seguridad o esconder rutas de red.
eBPF Malicioso: Utilizan herramientas modernas del kernel para inyectar programas que filtran o modifican el tráfico de red y los datos del sistema de manera casi invisible.

1. El "Secuestro" en la Capa de Enlace (BPF clásico)
Este es el método original de BPFDoor. No usa eBPF, sino el BPF clásico, pero el principio es el mismo .

Cómo funciona: El malware crea un socket AF_PACKET y adjunta un filtro BPF personalizado. Este filtro actúa como un portero: inspecciona cada paquete que llega a la interfaz de red en busca de una "palabra mágica" (magic packet) en el payload (por ejemplo, los bytes 0x7255 en UDP o 0x5293 en TCP) .

La Evasión: El filtro está programado para descartar (dropear) silenciosamente los paquetes que no le interesan. Como tcpdump y Wireshark también capturan paquetes en este mismo nivel (AF_PACKET), el filtro malicioso puede ejecutarse antes y ocultar el tráfico que no quiere que sea visto. Es como si el malware le quitara los paquetes de la bandeja de entrada a las herramientas de monitoreo .

2. La Intercepción Ultra-Temprana (eBPF con XDP)
Esta es una técnica más nueva y potente, utilizada por rootkits como LinkPro y mencionada en investigaciones sobre BPFDoor avanzado .

Cómo funciona: Utiliza eBPF en el modo XDP (eXpress Data Path). El programa XDP se ejecuta dentro del driver de la tarjeta de red, incluso antes de que el paquete entre al kernel de Linux .

La Evasión: En este punto, tcpdump y Wireshark (que dependen de la pila de red del kernel) ni siquiera han visto el paquete. El rootkit XDP puede analizar, redirigir o dropear el paquete sin dejar absolutamente ningún rastro para las herramientas de monitoreo convencionales. Es la máxima expresión de invisibilidad .

Más Allá de la Red: Ocultando su Propia Existencia
La capacidad de evasión de estos malware va más allá de ocultar el tráfico. También se ocultan a sí mismos para que no puedas encontrar el origen del problema:

Ocultación de Procesos y Archivos: Rootkits como LinkPro y Singularity utilizan hooks eBPF (en sistemas de archivos como getdents) para interceptar llamadas al sistema. Cuando ejecutas ps o ls para buscar el malware, el rootkit filtra los resultados y elimina su propio nombre y PID de la lista, haciéndose invisible .

Auto-ocultamiento de los Programas eBPF: Lo más sofisticado es que pueden ocultarse a sí mismos de herramientas de diagnóstico. Por ejemplo, LinkPro hookea la llamada al sistema sys_bpf. Esto significa que si ejecutas bpftool prog list (la herramienta estándar para ver programas eBPF), el rootkit intercepta la solicitud y elimina su propio programa de la lista .

Detección: Cómo Identificarlo
Dado que estas amenazas operan a nivel de kernel, la defensa debe ser igualmente rigurosa. Aquí tienes un plan de acción basado en las investigaciones:

Monitoreo de Comportamiento, no de Paquetes: Depende de herramientas de Detección y Respuesta de Endpoint (EDR) que analicen el comportamiento del sistema, como Falco. Falco puede detectar eventos sospechosos, como el uso del syscall setsockopt con la opción SO_ATTACH_FILTER, que es una forma común de cargar estos filtros .

Auditoría de Programas eBPF: Revisa periódicamente los programas eBPF cargados con bpftool prog list y compáralos con una línea base de tu sistema. Presta especial atención a programas con nombres aleatorios o inesperados .

Restricción de Capacidades: Limita el uso de eBPF. Asegúrate de que el parámetro del kernel kernel.bpf_enable_unprivileged esté desactivado (=0). Esto evita que usuarios sin privilegios carguen programas eBPF . Para procesos legítimos, usa capacidades de Linux de forma restrictiva.

Monitoreo de Modificaciones del Sistema: Utiliza sistemas de integridad de archivos (FIM) como AIDE o Tripwire para detectar cambios no autorizados en archivos críticos del sistema, ya que algunos rootkits modifican /etc/ld.so.preload para inyectarse .

Mantén el Kernel Actualizado: Las nuevas versiones del kernel incluyen mejoras en el verificador (verifier) de eBPF y parches de seguridad que dificultan la explotación de estas técnicas.

Medidas Defensivas:
Firmado de Módulos: Impedir que el kernel cargue módulos que no tengan una firma digital legítima.
Kernel Lockdown: Activar el modo lockdown para restringir el acceso a /dev/mem y otras interfaces críticas incluso para el usuario root.
Auditoría constante: Usar herramientas como auditd para monitorear cambios inesperados en los parámetros del sistema.

Monitoreo de Comportamiento, no de Paquetes: Depende de herramientas de Detección y Respuesta de Endpoint (EDR) que analicen el comportamiento del sistema, como Falco. Falco puede detectar eventos sospechosos, como el uso del syscall setsockopt con la opción SO_ATTACH_FILTER, que es una forma común de cargar estos filtros .

Auditoría de Programas eBPF: Revisa periódicamente los programas eBPF cargados con bpftool prog list y compáralos con una línea base de tu sistema. Presta especial atención a programas con nombres aleatorios o inesperados .

Restricción de Capacidades: Limita el uso de eBPF. Asegúrate de que el parámetro del kernel kernel.bpf_enable_unprivileged esté desactivado (=0). Esto evita que usuarios sin privilegios carguen programas eBPF . Para procesos legítimos, usa capacidades de Linux de forma restrictiva.

Monitoreo de Modificaciones del Sistema: Utiliza sistemas de integridad de archivos (FIM) como AIDE o Tripwire para detectar cambios no autorizados en archivos críticos del sistema, ya que algunos rootkits modifican /etc/ld.so.preload para inyectarse .

Mantén el Kernel Actualizado: Las nuevas versiones del kernel incluyen mejoras en el verificador (verifier) de eBPF y parches de seguridad que dificultan la explotación de estas técnicas.

