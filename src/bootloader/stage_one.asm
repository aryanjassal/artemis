[org 0x7c00]      ; Set the origin of the bootloader

; Move the boot disk into a variable which will be used when reading from disk
mov [BOOT_DISK], dl       ; Store the boot disk for later use

; Initialise the stack at 0x7c00
mov bp, 0x7c00    ; Move the stack base pointer at the memory address 0x7c00
mov sp, bp        ; Move the current stack pointer to the base (stack is empty)

mov dl, 4
call read_disk
jmp SECOND_STAGE

; ---------------------------------------------
; Code after this point will not get executed
; Use it to make useful functions or variables
; ---------------------------------------------

; This method reads a given number of sectors from the boot disk
read_disk:
  pusha
  mov ah, 0x02            ; Tell the BIOS we'll be reading the disk
  mov cl, 0x02            ; Start reading from sector 2 (because sector 1 is where we are now)
  mov al, dl              ; Read n number of sectors from disk
  mov ch, 0x00            ; Cylinder 0
  mov dh, 0x00            ; Head 0
  xor bx, bx              ; Clear the value in <bx>
  mov es, bx              ; Set the value of <es> to zero
  mov dl, [BOOT_DISK]     ; Read from the disk [boot drive]
  mov bx, SECOND_STAGE    ; Put the new data we read from the disk starting from the specifed location

  int 0x13                ; Read disk interrupt
  popa
  jc read_disk_failed     ; Jump to error handler (kinda?) if diskread fails
  ret                     ; Return the control flow

; Print an error message that the disk was not able to be read properly then hang indefinitely.
read_disk_failed:
  mov si, ERROR_DISKREADERROR
  call print
  jmp $

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

ERROR_DISKREADERROR db "[ERROR] COULD NOT READ DISK", 13, 10, 0

; Declaring disk-reading-related variables
BOOT_DISK db 0            ; Declare the BOOT_DISK variable
SECOND_STAGE equ 0x7e00   ; This is where the second stage will be loaded to

; Pad the entire bootloader with zeroes because the bootloader must be exactly 512 bytes in size
times 510-($-$$) db 0

; The magic signature which tells the computer that this file is bootable
dw 0xaa55
