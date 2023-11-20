SRC_DIR := src
TOOLS_DIR := tools
BUILD_DIR := build

BOOTLOADER_SRC := $(SRC_DIR)/boot.asm
BOOTLOADER_BIN := $(BUILD_DIR)/boot.bin

SRC_FILES := $(shell find $(SRC_DIR) -name "*.asm")
SRC_FILES := $(filter-out $(BOOTLOADER_SRC), $(SRC_FILES)) 
OBJ_FILES := $(patsubst $(SRC_DIR)/%.asm, $(BUILD_DIR)/%.bin, $(SRC_FILES))
TOOLS_SRC_FILES := $(shell find $(TOOLS_DIR) -name "*.c")
TOOLS_OBJ_FILES := $(patsubst $(TOOLS_DIR)/%.c, $(BUILD_DIR)/%, $(TOOLS_SRC_FILES))

OUTPUT_BIN := $(BUILD_DIR)/kernel.bin
FLOPPY_IMG := $(BUILD_DIR)/floppy.img

ASMC := @nasm
QEMU := @qemu-system-x86_64
ECHO := @echo
MKDIR := @mkdir -p
CAT := @cat
CLEAR := @clear
GCC := @gcc
RM := @rm -rf --
NO_OUT := >/dev/null 2>&1

ASMFLAGS := -I $(SRC_DIR) -f bin
GCCFLAGS := -g 
QEMUFLAGS := -fda $(FLOPPY_IMG) -no-reboot

.PHONY: all bootloader kernel tools floppy exec clean

all: tools floppy exec

floppy: bootloader # kernel
	$(ECHO) "Building the floppy image..."
	@dd if=/dev/zero of=$(FLOPPY_IMG) bs=512 count=2880 $(NO_OUT)
	@mkfs.fat -F12 -n "DOS2B" $(FLOPPY_IMG) $(NO_OUT)
	@dd if=$(BOOTLOADER_BIN) of=$(FLOPPY_IMG) conv=notrunc $(NO_OUT)
	@mcopy -i $(FLOPPY_IMG) tools/fat/test.txt "::test.txt" $(NO_OUT)
	@mcopy -i $(FLOPPY_IMG) tools/fat/another.txt "::another.txt" $(NO_OUT)
	$(ECHO) "Floppy image built."

bootloader:
	$(ECHO) "Compiling bootloader..."
	$(MKDIR) $(BUILD_DIR)
	$(ASMC) $(ASMFLAGS) $(BOOTLOADER_SRC) -o $(BOOTLOADER_BIN)
	$(ECHO) "Compilation done."

kernel: $(OBJ_FILES)
	$(ECHO) "Compiling kernel..."
	$(CAT) $(OBJ_FILES) > $(OUTPUT_BIN)
	$(ECHO) "Compilation done."

tools: $(TOOLS_OBJ_FILES)
	$(ECHO) "Built tools."

exec:
	$(ECHO) "Executing in QEMU..."
	$(QEMU) $(QEMUFLAGS)

$(OBJ_FILES): $(BUILD_DIR)/%.bin : $(SRC_DIR)/%.asm
	$(MKDIR) $(BUILD_DIR)
	$(ASMC) $(ASMFLAGS) $(patsubst $(BUILD_DIR)/%.bin, $(SRC_DIR)/%.asm, $@) -o $@

$(TOOLS_OBJ_FILES): $(BUILD_DIR)/% : $(TOOLS_DIR)/%.c
	$(MKDIR) $(dir $@)
	$(ECHO) "Building $(@F)"
	$(GCC) $(GCCFLAGS) $(patsubst $(BUILD_DIR)/%, $(TOOLS_DIR)/%.c, $@) -o $@

clean:
	$(RM) $(BUILD_DIR)
