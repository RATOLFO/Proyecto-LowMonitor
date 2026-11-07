; Modulo 1: Identificacion del CPU para Windows x64.
; NASM: nasm -f win64 cpu.asm -o cpu.obj
; El codigo de deteccion usa CPUID; la salida usa la API de Windows.
; Variables y etiquetas sencillas en espanol.
bits 64
default rel
extern GetStdHandle
extern WriteFile
extern ExitProcess
section .data
mensaje_titulo: db `MODULO 1: IDENTIFICACION DEL CPU\r\n`, 0
mensaje_nombre: db `Procesador: `, 0
mensaje_fabricante: db `Fabricante: `, 0
mensaje_arquitectura: db `Arquitectura: x86_64\r\n`, 0
mensaje_familia: db `Familia: `, 0
mensaje_modelo: db `Modelo: `, 0
mensaje_extension: db `Extensiones detectadas en el procesador:\r\n`, 0
mensaje_sse: db `  SSE: `, 0
mensaje_sse2: db `  SSE2: `, 0
mensaje_sse42: db `  SSE4.2: `, 0
mensaje_avx: db `  AVX: `, 0
mensaje_avx2: db `  AVX2: `, 0
mensaje_avx512: db `  AVX-512F: `, 0
mensaje_avx_so: db `AVX utilizable (CPU y sistema operativo): `, 0
mensaje_avx2_so: db `AVX2 utilizable: `, 0
mensaje_avx512_so: db `AVX-512F utilizable: `, 0
respuesta_si: db `Si\r\n`, 0
respuesta_no: db `No\r\n`, 0
mensaje_sin_nombre: db `No informado por CPUID`, 0
salto: db `\r\n`, 0
section .bss
nombre_cpu: resb 49
fabricante_cpu: resb 13
familia_cpu: resb 4
modelo_cpu: resb 4
hoja_maxima: resb 4
hoja_extendida: resb 4
caracteristicas_ecx: resb 4
caracteristicas_edx: resb 4
caracteristicas_ebx7: resb 4
estado_sistema: resb 4
numero_decimal: resb 32
salida_consola: resq 1
section .text
global inicio
inicio:
    ; Al entrar RSP es 8 modulo 16. Reservamos 32 bytes de shadow space
    ; mas 8 de ajuste: RSP queda alineado a 16 antes de cada CALL.
    sub rsp, 40
    mov ecx, -11                 ; STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [rel salida_consola], rax
    test rax, rax
    jz error_inicio
    cmp rax, -1
    je error_inicio
    lea rdi, [rel mensaje_titulo]
    call imprimir_texto
    ; Hoja 0: maximo de hojas basicas y fabricante (EBX, EDX, ECX).
    xor eax, eax
    cpuid
    mov [rel hoja_maxima], eax
    mov [rel fabricante_cpu], ebx
    mov [rel fabricante_cpu+4], edx
    mov [rel fabricante_cpu+8], ecx
    mov eax, 0x80000000
    cpuid
    mov [rel hoja_extendida], eax
    lea rdi, [rel mensaje_nombre]
    call imprimir_texto
    cmp dword [rel hoja_extendida], 0x80000004
    jb nombre_no_disponible
    ; Tres hojas entregan 16 bytes cada una: 48 bytes de nombre comercial.
    mov r12d, 0x80000002
    lea r13, [rel nombre_cpu]
leer_nombre:
    mov eax, r12d
    cpuid
    mov [r13], eax
    mov [r13+4], ebx
    mov [r13+8], ecx
    mov [r13+12], edx
    add r13, 16
    inc r12d
    cmp r12d, 0x80000005
    jb leer_nombre
    lea rdi, [rel nombre_cpu]
    call imprimir_texto
    jmp nombre_listo
nombre_no_disponible:
    lea rdi, [rel mensaje_sin_nombre]
    call imprimir_texto
nombre_listo:
    call nueva_linea
    lea rdi, [rel mensaje_fabricante]
    call imprimir_texto
    lea rdi, [rel fabricante_cpu]
    call imprimir_texto
    call nueva_linea
    lea rdi, [rel mensaje_arquitectura]
    call imprimir_texto
    ; Hoja 1 esta presente en los procesadores x86-64.
    mov eax, 1
    cpuid
    mov [rel caracteristicas_ecx], ecx
    mov [rel caracteristicas_edx], edx
    mov esi, eax
    shr eax, 8
    and eax, 15                   ; Familia base.
    mov edi, esi
    shr edi, 4
    and edi, 15                   ; Modelo base.
    cmp eax, 6
    je ampliar_modelo
    cmp eax, 15
    jne guardar_identificadores
ampliar_modelo:
    mov edx, esi
    shr edx, 16
    and edx, 15
    shl edx, 4
    or edi, edx
    cmp eax, 15
    jne guardar_identificadores
    shr esi, 20
    and esi, 255
    add eax, esi                  ; Familia extendida si familia base = 15.
guardar_identificadores:
    mov [rel familia_cpu], eax
    mov [rel modelo_cpu], edi
    lea rdi, [rel mensaje_familia]
    call imprimir_texto
    mov eax, [rel familia_cpu]
    call imprimir_numero
    call nueva_linea
    lea rdi, [rel mensaje_modelo]
    call imprimir_texto
    mov eax, [rel modelo_cpu]
    call imprimir_numero
    call nueva_linea
    ; Hoja 7, subhoja 0: AVX2 y AVX-512F.
    cmp dword [rel hoja_maxima], 7
    jb extensiones_listas
    mov eax, 7
    xor ecx, ecx
    cpuid
    mov [rel caracteristicas_ebx7], ebx
extensiones_listas:
    lea rdi, [rel mensaje_extension]
    call imprimir_texto
    lea rdi, [rel mensaje_sse]
    call imprimir_texto
    mov eax, [rel caracteristicas_edx]
    and eax, 1<<25
    call imprimir_booleano
    lea rdi, [rel mensaje_sse2]
    call imprimir_texto
    mov eax, [rel caracteristicas_edx]
    and eax, 1<<26
    call imprimir_booleano
    lea rdi, [rel mensaje_sse42]
    call imprimir_texto
    mov eax, [rel caracteristicas_ecx]
    and eax, 1<<20
    call imprimir_booleano
    lea rdi, [rel mensaje_avx]
    call imprimir_texto
    mov eax, [rel caracteristicas_ecx]
    and eax, 1<<28
    call imprimir_booleano
    lea rdi, [rel mensaje_avx2]
    call imprimir_texto
    mov eax, [rel caracteristicas_ebx7]
    and eax, 1<<5
    call imprimir_booleano
    lea rdi, [rel mensaje_avx512]
    call imprimir_texto
    mov eax, [rel caracteristicas_ebx7]
    and eax, 1<<16
    call imprimir_booleano
    ; Para ejecutar AVX no basta con el soporte de hardware.
    ; Comprobar XSAVE, OSXSAVE y AVX antes de usar XGETBV.
    mov eax, [rel caracteristicas_ecx]
    and eax, 0x1c000000
    cmp eax, 0x1c000000
    jne comprobar_uso
    xor ecx, ecx
    xgetbv                       ; XCR0: estado que el SO permite conservar.
    mov [rel estado_sistema], eax
comprobar_uso:
    lea rdi, [rel mensaje_avx_so]
    call imprimir_texto
    mov eax, [rel estado_sistema]
    and eax, 6                   ; XMM y YMM habilitados.
    cmp eax, 6
    sete al
    movzx eax, al
    mov r12d, eax
    call imprimir_booleano
    lea rdi, [rel mensaje_avx2_so]
    call imprimir_texto
    mov eax, [rel caracteristicas_ebx7]
    shr eax, 5
    and eax, r12d
    call imprimir_booleano
    lea rdi, [rel mensaje_avx512_so]
    call imprimir_texto
    mov eax, [rel estado_sistema]
    and eax, 0xe6                ; XMM, YMM, opmask, ZMM alto y registros ZMM.
    cmp eax, 0xe6
    sete al
    movzx eax, al
    mov edx, [rel caracteristicas_ebx7]
    shr edx, 16
    and eax, edx
    call imprimir_booleano
    xor ecx, ecx
    call ExitProcess             ; Terminar Windows con codigo 0.
error_inicio:
    mov ecx, 1
    call ExitProcess


; Convencion interna: RDI = cadena ASCII terminada en cero.
; Preserva RDI, RSI, RDX y RBX. RAX/RCX/R8-R11 son temporales.
; WriteFile funciona tanto en consola como con salida redirigida.
imprimir_texto:
    push rdi
    push rsi
    push rdx
    push rbx
    sub rsp, 56                  ; Shadow space, 5.o argumento y variable local.
    mov rsi, rdi
    xor ebx, ebx
contar_caracteres:
    cmp byte [rsi+rbx], 0
    je escribir_texto
    inc ebx
    jmp contar_caracteres
escribir_texto:
    test ebx, ebx
    jz terminar_texto
    mov rcx, [rel salida_consola]
    mov rdx, rsi
    mov r8d, ebx
    lea r9, [rsp+40]             ; DWORD bytes_escritos local.
    mov dword [rsp+40], 0
    mov qword [rsp+32], 0        ; lpOverlapped = NULL.
    call WriteFile
    test eax, eax
    jz error_escritura
    mov eax, [rsp+40]
    test eax, eax
    jz error_escritura
    add rsi, rax
    sub ebx, eax                ; Repetir si hubo escritura parcial.
    jmp escribir_texto
terminar_texto:
    add rsp, 56
    pop rbx
    pop rdx
    pop rsi
    pop rdi
    ret
error_escritura:
    mov ecx, 1
    call ExitProcess

; RAX = numero entero sin signo. Convertir a texto con divisiones entre 10.
imprimir_numero:
    push rbx
    push rdi
    push rdx
    sub rsp, 32                  ; Shadow space para imprimir_texto.
    lea rdi, [rel numero_decimal+31]
    mov byte [rdi], 0
    mov ebx, 10
convertir_decimal:
    xor edx, edx
    div rbx
    add dl, '0'
    dec rdi
    mov [rdi], dl
    test rax, rax
    jne convertir_decimal
    call imprimir_texto
    add rsp, 32
    pop rdx
    pop rdi
    pop rbx
    ret

; EAX = cero (No), cualquier otro valor (Si).
imprimir_booleano:
    lea rdi, [rel respuesta_no]
    test eax, eax
    jz imprimir_respuesta
    lea rdi, [rel respuesta_si]
imprimir_respuesta:
    jmp imprimir_texto
nueva_linea:
    lea rdi, [rel salto]
    jmp imprimir_texto
