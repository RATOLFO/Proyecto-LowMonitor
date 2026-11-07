; LowMonitor - Modulo 3: Diagnostico de memoria
; NASM x86-64 / Linux. Prueba un buffer propio de 4096 bytes.
; 0 = prueba normal; 1 = inyecta 3 bits de error por patron (demostracion).
%define INYECTAR_ERRORES 0
%define TAM_BUFFER 4096

section .data
    titulo db 10, '====================================', 10
           db '       DIAGNOSTICO DE MEMORIA       ', 10
           db '====================================', 10
    titulo_len equ $-titulo
    inicio db 'Bloque reservado: 4096 bytes', 10
    inicio_len equ $-inicio
    etiqueta_aa db 'Patron 0xAA: '
    etiqueta_aa_len equ $-etiqueta_aa
    etiqueta_55 db 'Patron 0x55: '
    etiqueta_55_len equ $-etiqueta_55
    etiqueta_inc db 'Patron incremental: '
    etiqueta_inc_len equ $-etiqueta_inc
    aprobada db 'PASADA ('
    aprobada_len equ $-aprobada
    fallida db 'FALLIDA ('
    fallida_len equ $-fallida
    sufijo db ' bits incorrectos)', 10
    sufijo_len equ $-sufijo
    ram_total db 'RAM total (MiB): '
    ram_total_len equ $-ram_total
    ram_libre db 10, 'RAM libre (MiB): '
    ram_libre_len equ $-ram_libre
    salto db 10
    aviso_ram db 'Nota: RAM libre no equivale a MemAvailable.', 10
    aviso_ram_len equ $-aviso_ram
    error_ram db 'No se pudo consultar la memoria del sistema.', 10
    error_ram_len equ $-error_ram
    fin db 'Diagnostico de memoria finalizado.', 10
    fin_len equ $-fin

section .bss
    buffer_memoria resb TAM_BUFFER
    num_texto resb 24
    info_sistema resb 128  ; struct sysinfo de Linux x86-64

section .text
    global memoria_info

memoria_info:
    push rbx                   ; RBX se preserva entre llamadas
    mov eax, 1
    mov edi, 1
    mov rsi, titulo
    mov edx, titulo_len
    syscall
    mov eax, 1
    mov edi, 1
    mov rsi, inicio
    mov edx, inicio_len
    syscall

    call mostrar_memoria_sistema

    ; BL = tipo: 0 = AA, 1 = 55, 2 = incremental
    mov ebx, 0
    mov rsi, etiqueta_aa
    mov edx, etiqueta_aa_len
    call imprimir_cadena
    call probar_patron

    mov ebx, 1
    mov rsi, etiqueta_55
    mov edx, etiqueta_55_len
    call imprimir_cadena
    call probar_patron

    mov ebx, 2
    mov rsi, etiqueta_inc
    mov edx, etiqueta_inc_len
    call imprimir_cadena
    call probar_patron

    mov rsi, fin
    mov edx, fin_len
    call imprimir_cadena
    pop rbx
    ret

; imprimir_cadena: RSI = texto, RDX = longitud
imprimir_cadena:
    mov eax, 1
    mov edi, 1
    syscall
    ret

; probar_patron: BL = tipo; llena, opcionalmente altera, verifica,
; cuenta TODOS los bits diferentes y muestra el resultado.
probar_patron:
    lea rdi, [rel buffer_memoria]
    xor ecx, ecx
.llenar:
    cmp bl, 0
    je .valor_aa
    cmp bl, 1
    je .valor_55
    mov al, cl                 ; secuencia incremental 00..FF
    jmp .guardar
.valor_aa:
    mov al, 0xAA
    jmp .guardar
.valor_55:
    mov al, 0x55
.guardar:
    mov [rdi + rcx], al
    inc ecx
    cmp ecx, TAM_BUFFER
    jb .llenar

%if INYECTAR_ERRORES
    ; Modificacion deliberada SOLO sobre el buffer del programa:
    ; primer byte: 1 bit, segundo byte: 2 bits. Total esperado: 3.
    xor byte [rel buffer_memoria], 0x01
    xor byte [rel buffer_memoria + 1], 0x03
%endif

    xor ecx, ecx              ; indice
    xor r9d, r9d              ; contador de bits incorrectos
.verificar:
    cmp bl, 0
    je .esperado_aa
    cmp bl, 1
    je .esperado_55
    mov dl, cl
    jmp .comparar
.esperado_aa:
    mov dl, 0xAA
    jmp .comparar
.esperado_55:
    mov dl, 0x55
.comparar:
    mov al, [rdi + rcx]
    xor al, dl                 ; 1 en cada bit que es diferente
    mov edx, 8
.contar_bits:
    shr al, 1
    adc r9, 0                 ; acumular el bit expulsado por SHR
    dec edx
    jnz .contar_bits
    inc ecx
    cmp ecx, TAM_BUFFER
    jb .verificar

    test r9, r9
    jnz .fallo
    mov rsi, aprobada
    mov edx, aprobada_len
    jmp .estado
.fallo:
    mov rsi, fallida
    mov edx, fallida_len
.estado:
    call imprimir_cadena
    mov rax, r9
    call imprimir_decimal
    mov rsi, sufijo
    mov edx, sufijo_len
    call imprimir_cadena
    ret

; imprimir_decimal: RAX = entero sin signo
imprimir_decimal:
    lea rsi, [rel num_texto + 24]
    mov r10d, 10
.convertir:
    xor edx, edx
    div r10
    dec rsi
    add dl, '0'
    mov [rsi], dl
    test rax, rax
    jnz .convertir
    lea rdx, [rel num_texto + 24]
    sub rdx, rsi
    call imprimir_cadena
    ret

; Consulta real de RAM virtual mediante sysinfo (syscall 99).
; En Linux x86-64: totalram +32, freeram +40, mem_unit +104.
; Muestra MiB enteros. Libre NO es igual que MemAvailable.
mostrar_memoria_sistema:
    mov eax, 99
    lea rdi, [rel info_sistema]
    syscall
    test rax, rax
    js .fallo

    mov rsi, ram_total
    mov edx, ram_total_len
    call imprimir_cadena
    mov rax, [rel info_sistema + 32]
    mov r8d, [rel info_sistema + 104]
    mul r8
    shr rax, 20
    call imprimir_decimal

    mov rsi, ram_libre
    mov edx, ram_libre_len
    call imprimir_cadena
    mov rax, [rel info_sistema + 40]
    mov r8d, [rel info_sistema + 104]
    mul r8
    shr rax, 20
    call imprimir_decimal

    mov rsi, salto
    mov edx, 1
    call imprimir_cadena
    mov rsi, aviso_ram
    mov edx, aviso_ram_len
    call imprimir_cadena
    ret
.fallo:
    mov rsi, error_ram
    mov edx, error_ram_len
    call imprimir_cadena
    ret