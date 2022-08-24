BOOTLOADER_SRC_DIR = src/bootloader
BOOTLOADER_BUILD_DIR = dist

BOOTLOADER_SRC_FILES := $(BOOTLOADER_SRC_DIR)/stage_one.asm $(BOOTLOADER_SRC_DIR)/stage_two.asm
BOOTLOADER_OBJECT_FILES := $(BOOTLOADER_BUILD_DIR)/stage_one.bin $(BOOTLOADER_BUILD_DIR)/stage_two.bin

OUTPUT_BIN := dist/project_april.bin

ASMC := @nasm
QEMU := @qemu-system-x86_64
ECHO := @echo
MKDIR := @mkdir -p
CAT := @cat
LD := @ld

ASMFLAGS := -I $(BOOTLOADER_SRC_DIR)
QEMUFLAGS := -drive file=$(OUTPUT_BIN),if=floppy,index=0,media=disk,format=raw
BOOTLOADER_LDFLAGS := -Ttext=0x8000 --oformat binary

.PHONY: all build exec

all: build exec

build: $(BOOTLOADER_SRC_FILES)
	$(ECHO) "Compiling..."
	$(MKDIR) dist
	$(ASMC) $(ASMFLAGS) -f bin $(BOOTLOADER_SRC_DIR)/stage_one.asm -o $(BOOTLOADER_BUILD_DIR)/stage_one.bin
	$(ASMC) $(ASMFLAGS) -f elf64 $(BOOTLOADER_SRC_DIR)/stage_two.asm -o $(BOOTLOADER_BUILD_DIR)/stage_two.o
	$(LD) $(BOOTLOADER_LDFLAGS) $(BOOTLOADER_BUILD_DIR)/stage_two.o -o $(BOOTLOADER_BUILD_DIR)/stage_two.bin
	$(CAT) $(BOOTLOADER_OBJECT_FILES) > $(OUTPUT_BIN)
# $(ASMC) $(ASMFLAGS) -f bin $(BOOTLOADER_SRC_DIR)/stage_one.asm -o $(OUTPUT_BIN)
	$(ECHO) "Compilation done."

exec:
	$(ECHO) "Executing Project April in QEMU..."
	$(QEMU) $(QEMUFLAGS)
