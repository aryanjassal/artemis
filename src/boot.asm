; org 0x7c00
; bits 16

; Mandatory part of FAT implementation
jmp short code
nop

; BIOS Parameter Block
OEM_IDENTIFIER            db "DOS2B V1"
; OEM_IDENTIFIER            db "MSDOS5.1"
BYTES_PER_SECTOR          dw 512
SECTORS_PER_CLUSTER       db 1
RESERVED_SECTORS          dw 1
NUMBER_OF_FAT             db 2
; DIRECTORY_ENTRY_COUNT     dw 0x0e
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

;
; ; Move the boot disk into a variable which will be used when reading from disk
; mov [BOOT_DISK], dl       ; Store the boot disk for later use
;
; ; Initialise the stack at 0x7c00
; mov bp, 0x7c00    ; Move the stack base pointer at the memory address 0x7c00
; mov sp, bp        ; Move the current stack pointer to the base (stack is empty)
;
; mov byte [si], 4
; call read_disk
; jmp SECOND_STAGE
;
; ;TODO: try at most three times before throwing an error
; read_disk:
;   pusha                   ; Push all the register values to the stack
;   mov ah, 0x02            ; Tell the BIOS we'll be reading the disk
;   mov cl, 0x02            ; Start reading from sector 2 (because sector 1 is where we are now)
;   mov al, [si]            ; Read n number of sectors from disk
;   mov ch, 0x00            ; Cylinder 0
;   mov dh, 0x00            ; Head 0
;   xor bx, bx              ; Clear the value in <bx>
;   mov es, bx              ; Set the value of <es> to zero
;   mov dl, [BOOT_DISK]     ; Read from the disk [boot drive]
;   mov bx, SECOND_STAGE    ; Put the new data we read from the disk starting from the specifed location
;
;   int 0x13                ; Read disk interrupt
;   popa                    ; Pop all the register values from the stack
;   jc read_disk_failed     ; Jump to error handler (kinda?) if diskread fails
;   ret                     ; Return the control flow
;
; ; Print an error message that the disk was not able to be read properly then hang indefinitely.
; read_disk_failed:
;   mov si, ERROR_DISKREADERROR
;   call print
;   jmp $
;
; ; The BIOS print routine
; print:
;   pusha     ; Push all the registers onto the stack because they will be used.
;
;   ; This method loops over all characters in a null-terminated string to print them.
;   .__print_loop:
;     mov al, [si]            ; Move the next character into the <al> register.
;     cmp al, 0               ; Check if <al> is 0 (null).
;     jnz .__print_char       ; If it is, then we have reached the end of the string. Prepare to exit the method.
;     popa                    ; Pop the pushed values for all the registers back, essentially restoring their value.
;     ret                     ; Safely return back to the memory address from where this function was called.
;  
;   ; This method prints a single character on the screen
;   .__print_char:
;     mov ah, 0x0e            ; Tell the BIOS we will be printing a character onto the screen
;     int 0x10                ; Call the interrupt to print the character (which should be in the <al> register)
;     add si, 1               ; Add 1 to <si> to print the next character in the buffer
;     jmp .__print_loop       ; Jump back to the print loop to print the next character
;
; ERROR_DISKREADERROR db "[ERROR] COULD NOT READ DISK", 13, 10, 0
;
; ; Declaring disk-reading-related variables
; BOOT_DISK db 0            ; Declare the BOOT_DISK variable
; SECOND_STAGE equ 0x7e00   ; This is where the second stage will be loaded to

; Pad the entire bootloader with zeroes because the bootloader must be exactly 512 bytes in size
times 510-($-$$) db 0

; The magic signature which tells the computer that this file is bootable
dw 0xaa55
