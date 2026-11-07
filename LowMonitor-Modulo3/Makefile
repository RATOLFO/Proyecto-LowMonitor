NASM = nasm
LD = ld

OBJETOS = main.o memoria.o
PROGRAMA = modulo3

.PHONY: all clean run

all: $(PROGRAMA)

$(PROGRAMA): $(OBJETOS)
	$(LD) $(OBJETOS) -o $(PROGRAMA)

%.o: %.asm
	$(NASM) -f elf64 $< -o $@

run: $(PROGRAMA)
	./$(PROGRAMA)

clean:
	rm -f $(OBJETOS) $(PROGRAMA)