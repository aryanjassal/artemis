SRC_DIR := src
TOOLS_DIR := tools
BUILD_DIR := dist

# SRC_FILES := $(shell find $(SRC_DIR) -name "*.asm")
SRC_FILES := $(SRC_DIR)/boot.asm
OBJ_FILES := $(patsubst $(SRC_DIR)/%.asm, $(BUILD_DIR)/%.bin, $(SRC_FILES))
TOOLS_SRC_FILES := $(shell find $(TOOLS_DIR) -name "*.c")
TOOLS_OBJ_FILES := $(patsubst $(TOOLS_DIR)/%.c, $(BUILD_DIR)/%, $(TOOLS_SRC_FILES))

OUTPUT_BIN := dist/dos2b.bin
FLOPPY_IMG := dist/floppy.img

ASMC := @nasm
QEMU := @qemu-system-x86_64
ECHO := @echo
MKDIR := @mkdir -p
CAT := @cat
CLEAR := @clear
GCC := @gcc
RM := @rm -r

ASMFLAGS := -I $(SRC_DIR) -f bin
GCCFLAGS := -g 
# QEMUFLAGS := -drive file=$(OUTPUT_BIN),if=floppy,index=0,media=disk,format=raw -no-reboot -m 256K
QEMUFLAGS := -drive file=$(FLOPPY_IMG),if=floppy,index=0,media=disk -no-reboot -m 256K

.PHONY: all build exec tools clean floppy

all: floppy exec

floppy: tools build
	$(ECHO) "Building the floppy image..."
	dd if=/dev/zero of=$(FLOPPY_IMG) bs=512 count=2880
	mkfs.fat -F12 -n "DOS2B" $(FLOPPY_IMG)
	dd if=$(OUTPUT_BIN) of=$(FLOPPY_IMG) conv=notrunc
	mcopy -i $(FLOPPY_IMG) tools/fat/test.txt "::test.txt"
	mcopy -i $(FLOPPY_IMG) tools/fat/another.txt "::another.txt"
	$(ECHO) "Floppy image built."

build: $(OBJ_FILES)
	$(ECHO) "Compiling..."
	$(CAT) $(OBJ_FILES) > $(OUTPUT_BIN)
	$(ECHO) "Compilation done."

tools: $(TOOLS_OBJ_FILES)
	$(ECHO) "Built tools."

exec:
	$(ECHO) "Executing Project April in QEMU..."
	$(QEMU) $(QEMUFLAGS)
	$(CLEAR)

$(OBJ_FILES): $(BUILD_DIR)/%.bin : $(SRC_DIR)/%.asm
	$(MKDIR) $(BUILD_DIR)
	$(ASMC) $(ASMFLAGS) $(patsubst $(BUILD_DIR)/%.bin, $(SRC_DIR)/%.asm, $@) -o $@

$(TOOLS_OBJ_FILES): $(BUILD_DIR)/% : $(TOOLS_DIR)/%.c
	$(MKDIR) $(dir $@)
	$(ECHO) "Building $@"
	$(GCC) $(GCCFLAGS) $(patsubst $(BUILD_DIR)/%, $(TOOLS_DIR)/%.c, $@) -o $@

clean:
	$(RM) $(BUILD_DIR)
