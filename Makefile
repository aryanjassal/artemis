
ASM_KERNEL_FILES := $(shell find src/arch/x86_64/bootloader -type f -name "*.asm" ! -name "loader.asm")
BOOTLOADER_FILES := src/arch/x86_64/bootloader/loader.asm

X86_64_ASM_SRC_FILES := $(BOOTLOADER_FILES) $(ASM_BOOT_FILES)
X86_64_ASM_OBJECT_FILES := $(patsubst src/arch/x86_64/bootloader/%.asm build/arch/x86_64/bootloader/%.o $(X86_64_ASM_SRC_FILES))

X86_64_KERNEL_OBJECT_FILES := $(X86_64_ASM_OBJECT_FILES)

OUTPUT_BIN := targets/x86_64/project-april.bin

ASMC := @nasm
QEMU := @qemu-system-x86_64
ECHO := @echo
MKDIR := @mkdir -p
CAT := @cat

ASMFLAGS := -I src/arch/x86_64/bootloader
QEMUFLAGS = -no-reboot -drive file=targets/x86_64/project-april.bin,if=floppy,index=0,media=disk,format=raw

.PHONY: build-x86_64 exec

all: build-x86_64 exec

build-x86_64: $(X86_64_ASM_FILES)
	$(ECHO) "Compiling..."
	$(MKDIR) dist/x86_64
	$(CAT) $(X86_64_KERNEL_FILES) > $(OUTPUT_BIN)
	$(ECHO) "Compilation done."

exec:
	$(ECHO) "Executing Project April in QEMU..."
	$(QEMU) $(QEMUFLAGS)

$(ASM_KERNEL_FILES): build/arch/x86_64/bootloader/%.o : src/arch/x86_64/bootloader/%.asm
	$(MKDIR) $(dir $@)
	$(ASMC) $(ASMFLAGS) -f elf64 $(patsubst build/arch/x86_64/%.o, src/arch/x86_64/%.c, $@) -o $@

$(BOOTLOADER_FILES): build/arch/x86_64/bootloader/%.o : src/arch/x86_64/bootloader/%.asm
	$(MKDIR) $(dir $@)
	$(ASMC) $(ASMFLAGS) -f bin $(patsubst build/arch/x86_64/%.o, src/arch/x86_64/%.c, $@) -o $@