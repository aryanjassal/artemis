BOOTLOADER_SRC_DIR := src/bootloader
BOOTLOADER_BUILD_DIR := dist/bootloader

KERNEL_SRC_DIR := src/kernel
KERNEL_BUILD_DIR := dist/kernel
KERNEL_INCLUDE_DIR := $(KERNEL_SRC_DIR)/include

BOOTLOADER_SRC_FILES := $(shell find $(BOOTLOADER_SRC_DIR) -name "*.asm")
BOOTLOADER_OBJECT_FILES := $(patsubst $(BOOTLOADER_SRC_DIR)/%.asm, $(BOOTLOADER_BUILD_DIR)/%.bin, $(BOOTLOADER_SRC_FILES))

KERNEL_SRC_FILES := $(shell find $(KERNEL_SRC_DIR) -name "*.c")
KERNEL_OBJECT_FILES := $(patsubst $(KERNEL_SRC_DIR)/%.c, $(KERNEL_BUILD_DIR)/%.o, $(KERNEL_SRC_FILES))

BOOTLOADER_OUTPUT_BIN := dist/bootloader.bin
KERNEL_OUTPUT_BIN := dist/kernel.bin
OUTPUT_BIN := dist/project_april.bin
LINKERFILE := src/linker.ld

ASMC := @nasm
QEMU := @qemu-system-x86_64
ECHO := @echo
MKDIR := @mkdir -p
CAT := @cat
LD := @ld
GCC := @gcc

ASMFLAGS := -I $(BOOTLOADER_SRC_DIR)
QEMUFLAGS := -drive file=$(OUTPUT_BIN),if=floppy,index=0,media=disk,format=raw
GCCFLAGS := -m32 -ffreestanding -I $(KERNEL_INCLUDE_DIR) -fno-pie -O2 -c
LDFLAGS := -n -m elf_i386 -Ttext 0x8000 -T $(LINKERFILE) -o $(KERNEL_OUTPUT_BIN)

.PHONY: all build exec compile_bootloader

all: compile_bootloader build exec

build: $(KERNEL_OBJECT_FILES) compile_bootloader
	$(ECHO) "Compiling..."
	$(LD) $(LDFLAGS) $(BOOTLOADER_BUILD_DIR)/stage_two.o $(KERNEL_OBJECT_FILES)
	$(CAT) $(BOOTLOADER_BUILD_DIR)/stage_one.bin $(KERNEL_OUTPUT_BIN) > $(OUTPUT_BIN)
	$(ECHO) "Compilation done."

exec:
	$(ECHO) "Executing Project April in QEMU..."
	$(QEMU) $(QEMUFLAGS)

compile_bootloader:
	$(MKDIR) $(BOOTLOADER_BUILD_DIR)
	$(ASMC) $(ASMFLAGS) -f bin $(BOOTLOADER_SRC_DIR)/stage_one.asm -o $(BOOTLOADER_BUILD_DIR)/stage_one.bin
	$(ASMC) $(ASMFLAGS) -f elf32 $(BOOTLOADER_SRC_DIR)/stage_two.asm -o $(BOOTLOADER_BUILD_DIR)/stage_two.o

$(KERNEL_OBJECT_FILES): $(KERNEL_BUILD_DIR)/%.o : $(KERNEL_SRC_DIR)/%.c
	$(MKDIR) $(dir $@)
	$(GCC) $(GCCFLAGS) $(patsubst $(KERNEL_BUILD_DIR)/%.o, $(KERNEL_SRC_DIR)/%.c, $@) -o $@
