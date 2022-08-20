# ASMFILES := src/kernel/boot.asm
# CFILES := src/kernel/kernel.c

ASMFLAGS = -f bin
QEMUFLAGS = -drive
GCCFLAGS = -Ttext 0x8000 -ffreestanding -mno-red-zone -m64 -c

.PHONY: run compile exec clean todo

run: compile exec

compile:
	@echo "Compiling..."
	@mkdir -p bin
	@nasm $(ASMFLAGS) src/kernel/boot.asm -o bin/project_april.bin
# @nasm $(ASMFLAGS) src/kernel/boot.asm -o bin/boot.bin
# @gcc $(GCCFLAGS) src/kernel/kernel.c -o bin/kernel.o
# @ld -T src/kernel/linker.ld
# @cat bin/kernel.bin bin/boot.bin bin/loader.bin > bin/project_april.bin
	@echo "Compilation done."
	
exec:
	@echo "Executing Project April in QEMU..."
	@qemu-system-x86_64 $(QEMUFLAGS) file=bin/project_april.bin,format=raw

clean:
	@rm -rf ./bin
	@echo "Cleaned project."

todo:
	-@for file in $(ALLFILES:Makefile=); do fgrep -H -e TODO -e FIXME $$file; done; true