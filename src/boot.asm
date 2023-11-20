org 0x7c00
bits 16

; Mandatory part of FAT implementation
jmp code
nop

; BIOS Parameter Block
OEM_IDENTIFIER            db "DOS2B V1"
BYTES_PER_SECTOR          dw 512
SECTORS_PER_CLUSTER       db 1
RESERVED_SECTORS          dw 1
NUMBER_OF_FAT             db 2
DIRECTORY_ENTRY_COUNT     dw 224
TOTAL_SECTORS             dw 2880
MEDIA_DESCRIPTOR_TYPE     db 0xf0
SECTORS_PER_FAT           dw 9
SECTORS_PER_TRACK         dw 18
NUMBER_OF_HEADS           dw 2
NUMBER_OF_HIDDEN_SECTORS  dd 0
LARGE_SECTOR_COUNT        dd 0

; Extended Boot Record
BOOT_DRIVE_NUMBER         db 0
RESERVED                  db 0
SIGNATURE                 db 0x28
VOLUME_ID                 db 0x12, 0x34, 0x56, 0x78
VOLUME_LABEL              db "DOS2B      "
SYSTEM_ID                 db "FAT12   "

; Bootable code starts here
code:
  ; Initialise the stack
  mov bp, 0x7c00
  mov sp, bp

  mov si, MSG_BOOT_SUCCESSFUL
  call print
  cli
  hlt

; The BIOS print routine
print:
  pusha     ; Push all the registers onto the stack because they will be used.

  ; This method loops over all characters in a null-terminated string to print them.
  .__print_loop:
    mov al, [si]            ; Move the next character into the <al> register.
    cmp al, 0               ; Check if <al> is 0 (null).
    jnz .__print_char       ; If it is, then we have reached the end of the string. Prepare to exit the method.
    popa                    ; Pop the pushed values for all the registers back, essentially restoring their value.
    ret                     ; Safely return back to the memory address from where this function was called.
 
  ; This method prints a single character on the screen
  .__print_char:
    mov ah, 0x0e            ; Tell the BIOS we will be printing a character onto the screen
    int 0x10                ; Call the interrupt to print the character (which should be in the <al> register)
    add si, 1               ; Add 1 to <si> to print the next character in the buffer
    jmp .__print_loop       ; Jump back to the print loop to print the next character

MSG_BOOT_SUCCESSFUL db "Welcome to DOS2B v0.0.3"

; Pad the entire bootloader with zeroes because the bootloader must be exactly 512 bytes in size
times 510-($-$$) db 0

; The magic signature which tells the computer that this file is bootable
dw 0xaa55
