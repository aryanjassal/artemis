.PHONY: compile run exec clean

compile:
	@echo "Compiling..."
	@mkdir -p bin
	@nasm -f bin src/boot/boot.asm -o bin/project-april.bin
	@echo "Compilation done."
	
run: compile exec clean

exec:
	@echo "Executing Project April in QEMU..."
	@qemu-system-x86_64 -drive file=bin/project-april.bin,format=raw

clean:
	@rm -rf ./bin
	@echo "Cleaned project."