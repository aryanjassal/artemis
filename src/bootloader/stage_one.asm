[org 0x7c00]      ; Set the origin of the bootloader

; Initialise the stack at 0x7c00
mov bp, 0x7c00    ; Move the stack base pointer at the memory address 0x7c00
mov sp, bp        ; Move the current stack pointer to the base (stack is empty)

; Clear the screen
call clear

; Print a simple greeting to the user
mov si, INFO_WELCOME
call print
mov si, VIDEO_NEWLINE
call print
mov si, CMD_PROMPT
call print

jmp $

; ---------------------------------------------
; Code after this point will not get executed
; Use it to make useful functions or variables
; ---------------------------------------------

; Set the cursor position (<dh> is rows and <dl> is columns)
set_cursor:
  pusha         ; Push the value of all the registers to the stack
  mov ah, 0x02  ; Set <al> to 0x02, which is to set the cursor position
  mov bh, 0     ; Set the video page (needs to be zero for graphical mode)
  int 0x10      ; Call the BIOS video interrupt
  popa          ; Pop all the registers from the stack
  ret           ; Return from this subroutine

; The BIOS clear screen function
clear:
  pusha           ; Push the value of all the registers to the stack
  mov ax, 0x0700  ; function 07, AL=0 means scroll whole window
  mov bh, 0x07    ; character attribute = white on black
  mov cx, 0x0000  ; row = 0, col = 0
  mov dx, 0x184f  ; row = 24 (0x18), col = 79 (0x4f)
  int 0x10        ; call BIOS video interrupt
  mov dx, 0x0000  ; Set <ds> and <dx> to the row and column to set the cursor to
  call set_cursor ; Call the subroutine to actually change the cursor location
  popa            ; Pop all the registers from the stack
  ret             ; Return from this subroutine

; The BIOS print routine
print:
  pusha     ; Push all the registers onto the stack because they will be used.

  ; This method loops over all characters in a null-terminated string to print them.
  .__bios_print_loop:
    mov al, [si]            ; Move the next character into the <al> register.
    cmp al, 0               ; Check if <al> is 0 (null).
    jnz .__bios_print_char  ; If it is, then we have reached the end of the string. Prepare to exit the method.
    popa                    ; Pop the pushed values for all the registers back, essentially restoring their value.
    ret                     ; Safely return back to the memory address from where this function was called.
 
  ; This method prints a single character on the screen
  .__bios_print_char:
    mov ah, 0x0e            ; Tell the BIOS we will be printing a character onto the screen
    int 0x10                ; Call the interrupt to print the character (which should be in the <al> register)
    add si, 1               ; Add 1 to <si> to print the next character in the buffer
    jmp .__bios_print_loop  ; Jump back to the print loop to print the next character

; Declaring strings that may or may not be used by the code later
INFO_WELCOME db "Welcome to Project April", 13, 10, "This version is DOS2B pre-alpha-1", 13, 10, 0
VIDEO_NEWLINE db 13, 10, 0
CMD_PROMPT db "> ", 0

; Pad the entire bootloader with zeroes because the bootloader must be exactly 512 bytes in size
times 510-($-$$) db 0

; The magic signature which tells the computer that this file is bootable
dw 0xaa55
