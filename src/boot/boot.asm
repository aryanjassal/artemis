[org 0x7c00]            ; Set the origin of the bootloader

loop:                   ; This is the main loop
  mov si, hello_world   ; Move the string (defined later) into the <si> register for printing
  call bios_print       ; Call <bios_print>, which prints the entire string at the location specified by <si>
  jmp $                 ; Keep jumping to this point essentially hanging the program

; The code here will not be executed, but include statements will still work
%include "src/boot/bios_print.asm"
hello_world db "Hello, world!", 13, 10, 0

; Pad the entire bootloader with zeroes because the bootloader must be exactly 512 bytes in size
times 510-($-$$) db 0

; The magic signature which tells the computer that this file is bootable
dw 0xaa55