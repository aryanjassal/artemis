#TODO: Clean up the Makefile so it looks comprehensible and the assembly compilation isn't weird. 

KERNEL_SOURCE_FILES := $(shell find src/kernel -name *.c)
KERNEL_OBJECT_FILES := $(patsubst src/kernel/%.c, build/kernel/%.o, $(KERNEL_SOURCE_FILES))

# x86_64_C_SOURCE_FILES := $(shell find src/arch/x86_64 -name *.c)
# x86_64_C_OBJECT_FILES := $(patsubst src/arch/x86_64/%.c, build/arch/x86_64/%.o, $(x86_64_C_SOURCE_FILES))

x86_64_ASM_SOURCE_FILES := $(shell find src/arch/x86_64 -name *.asm)
x86_64_ASM_OBJECT_FILES := build/arch/x86_64/bootloader/loader.bin build/arch/x86_64/bootloader/bootloader.bin
# x86_64_ASM_OBJECT_FILES := $(patsubst src/arch/x86_64/%.asm, build/arch/x86_64/%.o, $(x86_64_ASM_SOURCE_FILES))

# x86_64_OBJECT_FILES := $(x86_64_C_OBJECT_FILES) $(x86_64_ASM_OBJECT_FILES)

ASMC = nasm
CC = gcc
LINKER = ld
QEMU = qemu-system-x86_64

KERNEL_INCLUDE_DIR = src/include/kernel

GCCFLAGS = -ffreestanding -O2 -c
ASMFLAGS = -I src/arch/x86_64/bootloader
LINKFLAGS = -n
QEMUFLAGS = -no-reboot -drive file=targets/x86_64/project-april.bin,if=floppy,index=0,media=disk,format=raw

.PHONY: run build-x86_64 exec clean compile-asm

run: build-x86_64 exec

build-x86_64: $(KERNEL_OBJECT_FILES) compile-asm
	@echo "Compiling..."
	@mkdir -p dist/x86_64
	@$(LINKER) $(LINKFLAGS) -o dist/x86_64/stage-two-kernel.bin -T targets/x86_64/linker.ld build/arch/x86_64/bootloader/bootloader.bin build/arch/x86_64/bootloader/vga.bin $(KERNEL_OBJECT_FILES)
	@cat build/arch/x86_64/bootloader/loader.bin dist/x86_64/stage-two-kernel.bin > dist/x86_64/kernel.bin
	@cp dist/x86_64/kernel.bin targets/x86_64/project-april.bin
	@echo "Compilation done."
  
exec:
	@echo "Executing Project April in QEMU..."
	@$(QEMU) $(QEMUFLAGS)

clean:
	@rm -rf build/ dist/
	@echo "Cleaned project."

$(KERNEL_OBJECT_FILES): build/kernel/%.o : src/kernel/%.c
	@mkdir -p $(dir $@)
	@$(CC) $(GCCFLAGS) -I $(KERNEL_INCLUDE_DIR) $(patsubst build/kernel/%.o, src/kernel/%.c, $@) -o $@

# Don't have any code that actually uses this yet
# $(x86_64_C_OBJECT_FILES): build/arch/x86_64/%.o : src/arch/x86_64/%.c
# 	@mkdir -p $(dir $@)
# 	@$(CC) $(GCCFLAGS) -I $(KERNEL_INCLUDE_DIR) $(patsubst build/arch/x86_64/%.o, src/arch/x86_64/%.c, $@) -o $@

# $(x86_64_ASM_OBJECT_FILES): build/arch/x86_64/%.o : src/arch/x86_64/%.asm
# 	@mkdir -p $(dir $@)
# 	@$(ASMC) -f elf64 $(patsubst build/arch/x86_64/%.o, src/arch/x86_64/%.asm, $@) -o $@

compile-asm:
	@mkdir -p build/arch/x86_64/bootloader
	@$(ASMC) $(ASMFLAGS) -f bin src/arch/x86_64/bootloader/loader.asm -o build/arch/x86_64/bootloader/loader.bin
	@$(ASMC) $(ASMFLAGS) -f elf64 src/arch/x86_64/bootloader/bootloader.asm -o build/arch/x86_64/bootloader/bootloader.bin
	@$(ASMC) $(ASMFLAGS) -f elf64 src/arch/x86_64/bootloader/vga.asm -o build/arch/x86_64/bootloader/vga.bin
