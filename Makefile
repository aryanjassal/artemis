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
#FLOPPY_IMG2 := $(BUILD_DIR)/floppy2.img

Q := @

ASMC := $(Q)nasm
QEMU := $(Q)qemu-system-x86_64
ECHO := $(Q)echo
MKDIR := $(Q)mkdir -p
CAT := $(Q)cat
CLEAR := $(Q)clear
GCC := $(Q)gcc
RM := $(Q)rm -rf --
NO_OUT := >/dev/null 2>&1

ASMFLAGS := -f bin
GCCFLAGS := -g 
QEMUFLAGS := -drive file=$(FLOPPY_IMG),if=floppy,index=0,media=disk,format=raw -no-reboot -d in_asm >qemu.log 2>&1

.PHONY: all bootloader kernel tools floppy exec clean

all: tools floppy exec

debug: tools floppy
	@bochs -f bochs_config

floppy: bootloader kernel
	$(Q)dd if=/dev/zero of=$(FLOPPY_IMG) bs=512 count=2880 $(NO_OUT)
	$(Q)mkfs.fat -F12 -n "DOS2B" $(FLOPPY_IMG) $(NO_OUT)
	@# Uncomment this and $(FLOPPY_IMG2) to build a FAT16 combatible 18 MiB floppy 
	@# disk image for testing
	@#$(Q)dd if=/dev/zero of=$(FLOPPY_IMG2) bs=512 count=36000 $(NO_OUT)
	@#$(Q)mkfs.fat -F16 -n "DOS2B" $(FLOPPY_IMG2) $(NO_OUT)
	@#$(Q)mcopy -i $(FLOPPY_IMG2) tools/fat/test.txt "::test.txt" $(NO_OUT)
	@#$(Q)mcopy -i $(FLOPPY_IMG2) tools/fat/another.txt "::another.txt" $(NO_OUT)
	@# FAT16 floppy section end
	$(Q)dd if=$(BOOTLOADER_BIN) of=$(FLOPPY_IMG) conv=notrunc $(NO_OUT)
	$(Q)mcopy -i $(FLOPPY_IMG) build/kernel.bin "::kernel.bin" $(NO_OUT)
	$(Q)mcopy -i $(FLOPPY_IMG) tools/fat/test.txt "::test.txt" $(NO_OUT)
	$(Q)mcopy -i $(FLOPPY_IMG) tools/fat/another.txt "::another.txt" $(NO_OUT)
	$(ECHO) "Floppy image built."

bootloader:
	$(MKDIR) $(BUILD_DIR)
	$(ASMC) $(ASMFLAGS) $(BOOTLOADER_SRC) -o $(BOOTLOADER_BIN)
	$(ECHO) "Bootloader compiled"

kernel: $(OBJ_FILES)
	$(ECHO) "Kernel compiled"

tools: $(TOOLS_OBJ_FILES)

exec:
	$(ECHO) "Running..."
	$(QEMU) $(QEMUFLAGS)

$(OBJ_FILES): $(BUILD_DIR)/%.bin : $(SRC_DIR)/%.asm
	$(MKDIR) $(BUILD_DIR)
	$(ASMC) $(ASMFLAGS) $(patsubst $(BUILD_DIR)/%.bin, $(SRC_DIR)/%.asm, $@) -o $@

$(TOOLS_OBJ_FILES): $(BUILD_DIR)/% : $(TOOLS_DIR)/%.c
	$(MKDIR) $(dir $@)
	$(ECHO) "Building tools/$(@F)"
	$(GCC) $(GCCFLAGS) $(patsubst $(BUILD_DIR)/%, $(TOOLS_DIR)/%.c, $@) -o $@

clean:
	$(RM) $(BUILD_DIR)
