[org 0x7c00]        ; Set the origin of the bootloader

BOOT_DISK db 0      ; Declare the BOOT_DISK variable

mov bp, 0x7c00            ; Move the stack base pointer at the memory address 0x7c00
mov sp, bp                ; Move the current stack pointer at the base (stack is empty)
mov [BOOT_DISK], dl       ; Store the boot disk for later use
SECOND_STAGE equ 0x8000   ; This is where the second stage will be loaded to

mov si, INFO_WELCOME
call bios_print

call read_disk        ; Call the function to read the disk to load the next stage
jmp SECOND_STAGE      ; Perform a jump to the second stage of the bootloader
; No code will be executed this point onwards
; All the function definitions will go after here

; This method reads a given number of sectors from the boot disk
read_disk:
  mov ah, 0x02            ; Tell the BIOS we'll be reading the disk
  mov cl, 0x02            ; Start reading from sector 2 (because sector 1 is where we are now)
  mov al, 16              ; Read n number of sectors from disk
  mov ch, 0x00            ; Cylinder 0
  mov dh, 0x00            ; Head 0
  xor bx, bx              ; Clear the value in <bx>
  mov es, bx              ; Set the value of <es> to zero
  mov dl, [BOOT_DISK]     ; Read from the disk [boot drive]
  mov bx, SECOND_STAGE    ; Put the new data we read from the disk starting from the specifed location

  int 0x13                ; Read disk interrupt
  jc read_disk_failed     ; Jump to error handler (kinda?) if diskread fails
  ret                     ; Return the control flow

; Print an error message that the disk was not able to be read properly then hang indefinitely.
read_disk_failed:
  mov si, ERROR_DISKREADERROR
  call bios_print
  jmp $

; Create strings for future use
INFO_WELCOME db "Welcome to AprilOS!", 13, 10, 0
ERROR_DISKREADERROR db "Failure in reading drive!", 13, 10, 0

; The BIOS print routine
bios_print:
  pusha     ; Push the <a> registers because they will be used

  ; This method loops over all characters in a string to print them (null-terminated).
  .__bios_print_loop:
    mov al, [si]            ; Move the next character into the <al> register, which is supposed to contain the character to print
    cmp al, 0               ; Check if the next character to print is 0 (null)
    jnz .__bios_print_char  ; If it really is 0 (null), then we have reached the end of the string. Prepare to exit the method.
    popa                    ; Pop the pushed values for the <a> registers back
    ret                     ; Safely return back to the memory address where this jump statement was called
  
  ; This method prints a single character on the screen
  .__bios_print_char:
    mov ah, 0x0e            ; Tell the BIOS we are meant to print a character to the screen
    int 0x10                ; Call the intterupt to print the character (which should be in <al> register)
    add si, 1               ; Add 1 to the counter of current character to print the next character
    jmp .__bios_print_loop  ; Jump back to the print loop to print the next character

; Pad the entire bootloader with zeroes because the bootloader must be exactly 512 bytes in size
times 510-($-$$) db 0

; The magic signature which tells the computer that this file is bootable
dw 0xaa55