NASM = nasm
LD = ld
FLAGS = -f elf64

all: modulo2 prueba_puertos validar_rango

modulo2: modulo2.o
	$(LD) modulo2.o -o modulo2

modulo2.o: modulo2.asm
	$(NASM) $(FLAGS) modulo2.asm -o modulo2.o

prueba_puertos: prueba_puertos.o
	$(LD) prueba_puertos.o -o prueba_puertos

prueba_puertos.o: prueba_puertos.asm
	$(NASM) $(FLAGS) prueba_puertos.asm -o prueba_puertos.o

validar_rango: validar_rango.o
	$(LD) validar_rango.o -o validar_rango

validar_rango.o: validar_rango.asm
	$(NASM) $(FLAGS) validar_rango.asm -o validar_rango.o

clean:
	rm -f *.o modulo2 prueba_puertos validar_rango

.PHONY: all clean
