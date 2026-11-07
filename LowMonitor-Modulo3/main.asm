; ==========================================
; MODULO 3 - DIAGNOSTICO DE MEMORIA RAM
; Proyecto Arquitectura de Computadoras
; Ejecutable
; ==========================================

section .text
    global _start
    extern memoria_info

_start:
    ; Ejecutar directamente el diagnostico
    call memoria_info

    ; Finalizar el programa correctamente
    mov eax, 60
    xor edi, edi
    syscall