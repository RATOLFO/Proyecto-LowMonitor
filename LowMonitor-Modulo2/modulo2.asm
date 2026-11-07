; LowMonitor - Modulo 2: monitor de puertos E/S x86-64
; NASM 3.x / Linux x86-64. Requiere privilegios para ioperm().
; Este codigo utiliza IN/OUT de 8 bits sobre dispositivos virtuales.
; ADVERTENCIA: leer 60h consume un dato de teclado si esta disponible.
; Pruebas de 16/32 bits pendientes: NO aplicar a estos dispositivos.

default rel

%macro PRINT 2
    mov eax, 1
    mov edi, 1
    lea rsi, [%1]
    mov edx, %2
    syscall
%endmacro

section .data
    titulo db 10,"====================================",10,"     LOWMONITOR - MODULO 2",10,"====================================",10
    titulo_len equ $-titulo
    menu db "1. Consultar teclado (60h)",10,"2. Consultar sistema (61h)",10,"3. Consultar COM1 (3F8h)",10,"4. Prueba de escritura COM1",10,"5. Consultar todos los puertos",10,"0. Salir",10,"Seleccione una opcion: "
    menu_len equ $-menu
    txt_teclado db 10,"Puerto 60h (teclado): "
    txt_teclado_len equ $-txt_teclado
    txt_sistema db 10,"Puerto 61h (sistema): "
    txt_sistema_len equ $-txt_sistema
    txt_com1 db 10,"Puerto 3F8h (COM1): "
    txt_com1_len equ $-txt_com1
    txt_out db 10,"Prueba OUT (registro 3FFh): "
    txt_out_len equ $-txt_out
    ok db "[OK] Operacion realizada",10
    ok_len equ $-ok
    sin_datos db "[INFO] Sin datos disponibles en teclado",10
    sin_datos_len equ $-sin_datos
    no_permiso db "[ERROR] ioperm no concedio permiso",10
    no_permiso_len equ $-no_permiso
    fallo db "[ERROR] La lectura de verificacion no coincide",10
    fallo_len equ $-fallo
    invalida db 10,"[ERROR] Opcion no valida",10
    invalida_len equ $-invalida
    fin db 10,"Saliendo de LowMonitor...",10
    fin_len equ $-fin

section .bss
    opcion resb 16
    valor resb 1

section .text
    global _start

_start:
.menu:
    PRINT titulo, titulo_len
    PRINT menu, menu_len
    xor eax, eax                     ; read(STDIN, opcion, 16)
    xor edi, edi
    lea rsi, [opcion]
    mov edx, 16
    syscall
    test rax, rax
    jle salir
    mov al, [opcion]
    cmp al, '1'
    je .uno
    cmp al, '2'
    je .dos
    cmp al, '3'
    je .tres
    cmp al, '4'
    je .cuatro
    cmp al, '5'
    je .cinco
    cmp al, '0'
    je salir
    PRINT invalida, invalida_len
    jmp .menu
.uno:
    call revisar_teclado
    jmp .menu
.dos:
    call revisar_sistema
    jmp .menu
.tres:
    call revisar_com1
    jmp .menu
.cuatro:
    call probar_escritura
    jmp .menu
.cinco:
    call revisar_teclado
    call revisar_sistema
    call revisar_com1
    jmp .menu

; ioperm(unsigned long desde, unsigned long cantidad, int encender)
; syscall 173 Linux x86-64, rdi/rsi ya contienen los argumentos.
activar:
    mov eax, 173
    mov edx, 1
    syscall
    ret

desactivar:
    mov eax, 173
    xor edx, edx
    syscall
    ret

revisar_teclado:
    PRINT txt_teclado, txt_teclado_len
    mov edi, 0x60
    mov esi, 5
    call activar
    test rax, rax
    js .denegado
    mov dx, 0x64                 ; registro de estado del controlador
    in al, dx                   ; IN de 8 bits
    test al, 1
    jz .sin_dato
    mov dx, 0x60                 ; consume dato, si existe
    in al, dx
    mov [valor], al
    PRINT ok, ok_len
    jmp .terminar
.sin_dato:
    PRINT sin_datos, sin_datos_len
.terminar:
    mov edi, 0x60
    mov esi, 5
    call desactivar
    ret
.denegado:
    PRINT no_permiso, no_permiso_len
    ret

revisar_sistema:
    PRINT txt_sistema, txt_sistema_len
    mov edi, 0x61
    mov esi, 1
    call activar
    test rax, rax
    js .denegado
    mov dx, 0x61
    in al, dx
    mov [valor], al
    PRINT ok, ok_len
    mov edi, 0x61
    mov esi, 1
    call desactivar
    ret
.denegado:
    PRINT no_permiso, no_permiso_len
    ret

revisar_com1:
    PRINT txt_com1, txt_com1_len
    mov edi, 0x3F8
    mov esi, 8
    call activar
    test rax, rax
    js .denegado
    mov dx, 0x3FD                 ; LSR, UART 16550A
    in al, dx
    mov [valor], al
    PRINT ok, ok_len
    mov edi, 0x3F8
    mov esi, 8
    call desactivar
    ret
.denegado:
    PRINT no_permiso, no_permiso_len
    ret

probar_escritura:
    PRINT txt_out, txt_out_len
    mov edi, 0x3F8
    mov esi, 8
    call activar
    test rax, rax
    js .denegado
    mov dx, 0x3FF                 ; Scratch Register (UART 16550A)
    in al, dx
    mov r12b, al                  ; guardar valor previo
    mov al, 0x5A
    out dx, al                    ; OUT de 8 bits
    in al, dx
    mov r13b, al                  ; retener lectura
    mov al, r12b
    out dx, al                    ; restaurar valor original
    cmp r13b, 0x5A
    jne .fallida
    PRINT ok, ok_len
    jmp .terminar
.fallida:
    PRINT fallo, fallo_len
.terminar:
    mov edi, 0x3F8
    mov esi, 8
    call desactivar
    ret
.denegado:
    PRINT no_permiso, no_permiso_len
    ret

salir:
    PRINT fin, fin_len
    mov eax, 60
    xor edi, edi
    syscall
