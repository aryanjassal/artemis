; Provide the _start symbol globally so the linker doesn't complain
[global _start]
; Compile this file with the 32-bit instruction set
[bits 32]
; This start label is here just to tell the linker where the executable code startes from
_start:
  ; Move the VGA buffer to ebx
  mov ebx, 0xb8000

  ; Print something to the VGA buffer
  mov si, INFO_PROTECTEDMODE
  call vprint

  ; Halt execution of code here for now
  jmp $

; ---------------------------------------------
; Code after this point will not get executed
; Use it to make useful functions or variables
; ---------------------------------------------

; TODO: Implement proper VGA printing by coding newline support among others
; Implement the code to print by moving character information directly into VGA memory
vprint:
  pusha

  .__vga_print_loop:
    mov al, [si]
    ; cmp al, 13
    ; jnz .__vga_print_newline
    cmp al, 0
    jnz .__vga_print_char
    popa
    ret

  .__vga_print_char:
    mov byte [ebx], al
    add si, 1
    add ebx, 1
    mov byte [ebx], 0x0f
    add ebx, 1
    jmp .__vga_print_loop
  
; Declaring strings
INFO_PROTECTEDMODE db "(i) successfully entered 32-bit protected mode", 0
INFO_GREETING db "(i) welcome to Project April, aka AprilOS!", 0
; VGA_NEWLINE db 13