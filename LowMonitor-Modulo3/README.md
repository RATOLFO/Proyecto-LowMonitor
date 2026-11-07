# Módulo 3 — Diagnóstico de Memoria RAM

## Descripción

Módulo independiente desarrollado en lenguaje ensamblador x86-64 utilizando NASM sobre Ubuntu Linux, como parte del proyecto final de Arquitectura de Computadoras.

Su objetivo es comprobar la integridad de un bloque de memoria reservado por el programa, mediante la escritura y lectura de diferentes patrones de datos.

## Funcionalidades

- Reserva de un bloque de memoria de 4096 bytes.
- Verificación mediante el patrón hexadecimal `0xAA`.
- Verificación mediante el patrón hexadecimal `0x55`.
- Verificación de una secuencia incremental.
- Conteo de bits incorrectos.
- Identificación de pruebas aprobadas o fallidas.
- Inyección controlada de errores para demostrar su detección.
- Consulta de memoria RAM total y libre del sistema.
- Ejecución independiente, sin utilizar un menú principal.

## Requisitos

- Sistema operativo Linux x86-64 (probado en Ubuntu).
- NASM.
- GNU Make.
- GNU LD (binutils).

## Estructura del proyecto

```text
modulo3-independiente/
├── main.asm
├── memoria.asm
├── Makefile
├── README.md
└── evidencias/
```

## Compilación

Abrir una terminal dentro de la carpeta del módulo y ejecutar:

```bash
make clean
make
```

## Ejecución

Ejecutar:

```bash
make run
```

El programa realizará automáticamente las tres pruebas y terminará sin solicitar opciones al usuario.

## Pruebas normales

En `memoria.asm`, mantener la siguiente configuración:

```asm
%define INYECTAR_ERRORES 0
```

El resultado esperado es que los tres patrones indiquen `PASADA (0 bits incorrectos)` cuando no se detecten diferencias.

## Prueba con errores intencionales

Para comprobar el contador de errores, modificar temporalmente:

```asm
%define INYECTAR_ERRORES 1
```

Guardar el archivo, volver a compilar y ejecutar.

Esta modalidad introduce alteraciones controladas en el bloque reservado por el programa. En las pruebas realizadas se detectaron tres bits incorrectos por patrón.

Después de la demostración, restaurar `INYECTAR_ERRORES 0` y recompilar.

## Consideraciones

- El programa trabaja sobre un bloque de memoria reservado, no examina toda la RAM física.
- La memoria total y libre corresponde a la información proporcionada por Linux.
- La memoria libre no equivale necesariamente a la memoria disponible.
- Las pruebas con errores provocados permiten verificar la lógica de detección, pero no representan fallos reales del hardware.
- El módulo puede compilarse y ejecutarse sin los demás componentes de LowMonitor.

## Evidencias

La carpeta `evidencias` contiene capturas de compilación, ejecución normal, configuración de errores y detección de errores intencionales.