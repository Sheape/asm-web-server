AS = nasm
ASFLAGS = -felf32 -g -F dwarf

LD = ld
LDFLAGS = -m elf_i386

# LD = gcc
# LDFLAGS = -m32 -no-pie

SOURCES = $(shell find . -name "*.asm")
OBJECTS = $(SOURCES:.asm=.o)
ELFS    = $(SOURCES:.asm=.elf)

all: $(ELFS)

%.o: %.asm
	$(AS) $(ASFLAGS) -o $@ $<

%.elf: %.o
	$(LD) $(LDFLAGS) -o $@ $<

clean:
	find . -type f -perm /111 -exec rm -f {} +
	find . -type f -name '*.o' -exec rm -f {} +
