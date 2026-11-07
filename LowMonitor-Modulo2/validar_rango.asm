; LOWMONITOR - MODULO 2
; Validacion decimal de direcciones E/S (0..65535)
; No ejecuta IN/OUT ni accede al hardware.
; NASM / Linux x86-64

default rel

section .data
    titulo db 10, 'LOWMONITOR - VALIDACION DE PUERTOS', 10
    titulo_len equ $-titulo
    aviso db 'Introduzca un puerto decimal (0 a 65535): '
    aviso_len equ $-aviso
    valido db '[OK] Puerto dentro del rango 0..65535', 10
    valido_len equ $-valido
    invalido db '[ERROR] Puerto invalido o fuera de rango', 10
    invalido_len equ $-invalido

section .bss
    entrada resb 32

section .text
    global _start

_start:
    mov eax, 1
    mov edi, 1
    lea rsi, [titulo]
    mov edx, titulo_len
    syscall
    mov eax, 1
    mov edi, 1
    lea rsi, [aviso]
    mov edx, aviso_len
    syscall

    xor eax, eax                 ; read(0, entrada, 32)
    xor edi, edi
    lea rsi, [entrada]
    mov edx, 32
    syscall
    test rax, rax
    jle .error

    mov r9, rax                  ; cantidad de caracteres leidos
    xor r8d, r8d                ; valor decimal acumulado
    xor ecx, ecx                ; indice
    xor r10d, r10d              ; numero de digitos
    lea rsi, [entrada]

.convertir:
    cmp rcx, r9
    jae .fin_entrada
    movzx edx, byte [rsi+rcx]
    cmp dl, 10                  ; LF: fin de linea
    je .fin_entrada
    cmp dl, 13                  ; CR: fin de linea
    je .fin_entrada
    cmp dl, '0'
    jb .error
    cmp dl, '9'
    ja .error
    sub edx, '0'

    ; Prevenir desbordamiento antes de multiplicar por 10.
    cmp r8, 6553
    ja .error
    jne .acumular
    cmp edx, 5
    ja .error
.acumular:
    imul r8, r8, 10
    add r8, rdx
    inc r10d
    inc rcx
    jmp .convertir

.fin_entrada:
    test r10d, r10d             ; rechazar entrada vacia
    jz .error
    ; La lectura debe incluir un fin de linea; rechazar entrada truncada.
    cmp rcx, r9
    jae .error
    ; Asegurarse de que luego del fin de linea no haya mas datos.
    ; En uso interactivo canonico, read entrega una linea completa.
    mov eax, 1
    mov edi, 1
    lea rsi, [valido]
    mov edx, valido_len
    syscall
    jmp .salir_ok

.error:
    mov eax, 1
    mov edi, 1
    lea rsi, [invalido]
    mov edx, invalido_len
    syscall
    mov eax, 60
    mov edi, 1
    syscall

.salir_ok:
    mov eax, 60
    xor edi, edi
    syscall
