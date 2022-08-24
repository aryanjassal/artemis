BOOTLOADER_SRC_DIR = src/bootloader
BOOTLOADER_BUILD_DIR = dist

BOOTLOADER_SRC_FILES := $(BOOTLOADER_SRC_DIR)/stage_one.asm $(BOOTLOADER_SRC_DIR)/stage_two.asm
BOOTLOADER_OBJECT_FILES := $(BOOTLOADER_BUILD_DIR)/stage_one.o $(BOOTLOADER_BUILD_DIR)/stage_two.o

OUTPUT_BIN := dist/project_april.bin

ASMC := @nasm
QEMU := @qemu-system-x86_64
ECHO := @echo
MKDIR := @mkdir -p
CAT := @cat

ASMFLAGS := -I $(BOOTLOADER_SRC_DIR)
QEMUFLAGS = -drive file=$(OUTPUT_BIN),if=floppy,index=0,media=disk,format=raw -no-reboot

.PHONY: all build exec

all: build exec

build: $(BOOTLOADER_SRC_FILES)
	$(ECHO) "Compiling..."
	$(MKDIR) dist
	$(ASMC) $(ASMFLAGS) -f bin $(BOOTLOADER_SRC_DIR)/stage_one.asm -o $(BOOTLOADER_BUILD_DIR)/stage_one.o
	$(ASMC) $(ASMFLAGS) -f elf64 $(BOOTLOADER_SRC_DIR)/stage_two.asm -o $(BOOTLOADER_BUILD_DIR)/stage_two.o
	$(CAT) $(BOOTLOADER_OBJECT_FILES) > $(OUTPUT_BIN)
	$(ECHO) "Compilation done."

exec:
	$(ECHO) "Executing Project April in QEMU..."
	$(QEMU) $(QEMUFLAGS)