BOOTLOADER_SRC_DIR := src/bootloader
BOOTLOADER_BUILD_DIR := dist/bootloader

BOOTLOADER_SRC_FILES := $(shell find $(BOOTLOADER_SRC_DIR) -name "*.asm")
BOOTLOADER_OBJECT_FILES := $(patsubst $(BOOTLOADER_SRC_DIR)/%.asm, $(BOOTLOADER_BUILD_DIR)/%.bin, $(BOOTLOADER_SRC_FILES))

BOOTLOADER_OUTPUT_BIN := dist/bootloader.bin
OUTPUT_BIN := dist/dos2b.bin

ASMC := @nasm
QEMU := @qemu-system-x86_64
ECHO := @echo
MKDIR := @mkdir -p
CAT := @cat

ASMFLAGS := -I $(BOOTLOADER_SRC_DIR) -f bin
QEMUFLAGS := -drive file=$(OUTPUT_BIN),if=floppy,index=0,media=disk,format=raw

.PHONY: all build exec

all: build exec

build: $(BOOTLOADER_OBJECT_FILES)
	$(ECHO) "Compiling..."
	$(CAT) $(BOOTLOADER_OBJECT_FILES) > $(OUTPUT_BIN)
	$(ECHO) "Compilation done."

exec:
	$(ECHO) "Executing Project April in QEMU..."
	$(QEMU) $(QEMUFLAGS)

$(BOOTLOADER_OBJECT_FILES): $(BOOTLOADER_BUILD_DIR)/%.bin : $(BOOTLOADER_SRC_DIR)/%.asm
	$(MKDIR) $(BOOTLOADER_BUILD_DIR)
	$(ASMC) $(ASMFLAGS) $(patsubst $(BOOTLOADER_BUILD_DIR)/%.bin, $(BOOTLOADER_SRC_DIR)/%.asm, $@) -o $@
