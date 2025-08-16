AS = nasm
ASFLAGS = -felf32 -g -F dwarf

LD = ld
LDFLAGS = -m elf_i386

.PHONY: all
all: main

main: main.o int_to_str.o
	$(LD) $(LDFLAGS) $^ -o $@

%.o: %.asm
	$(AS) $(ASFLAGS) -o $@ $<


.PHONY: clean
clean:
	find . -type f -perm /111 -exec rm -f {} +
	find . -type f -name '*.o' -exec rm -f {} +
