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
.loop:
  mov si, CMD_PROMPT
  call print

  mov di, VIDEO_CMD_BUFFER
  call get_string

  mov si, VIDEO_CMD_BUFFER
  mov di, CMD_CLEAR
  call strcmp
  jc ._clear_screen

  mov si, VIDEO_CMD_BUFFER
  cmp byte [si], 0
  je .loop

  mov si, VIDEO_NEWLINE
  call print
  jmp .loop

._clear_screen:
  call clear
  jmp .loop

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

; Get a string from the user and store it in the <di> buffer
; The size of the <di> buffer is the maximum size of the command
get_string:
  pusha
  xor cl, cl

  .__get_string_loop:
    xor ah, ah
    int 0x16

    cmp al, 0x08
    je .__get_string_handle_backspace
    
    cmp al, 0x0d
    je .__get_string_handle_return

    ; IMPLEMENT DYNAMIC BUFFER SIZE
    cmp cl, 0x3f
    je .__get_string_loop

    mov ah, 0x0e
    int 0x10

    stosb
    inc cl
    jmp .__get_string_loop

    ret

  .__get_string_handle_backspace:
    cmp cl, 0
    je .__get_string_loop
    
    dec di
    dec cl
    mov byte [di], 0

    mov ah, 0x0e
    mov al, 0x08
    int 0x10

    mov al, " "
    int 0x10

    mov al, 0x08
    int 0x10

    jmp .__get_string_loop

  .__get_string_handle_return:
    mov al, 0
    stosb

    mov ah, 0x0e
    mov al, 0x0d
    int 0x10

    mov al, 0x0a
    int 0x10
    popa

    ret

; Compare if the two strings in <si> and <di> are the same
; If they are, then set the carry flag, otherwise the carry flag will not be set
strcmp:
  pusha
  
  .__strcmp_cmp_byte:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .__strcmp_bytes_not_equal

    cmp al, 0
    je .__strcmp_end_of_string

    inc di
    inc si
    jmp .__strcmp_cmp_byte

    .__strcmp_bytes_not_equal:
      clc
      popa
      ret

    .__strcmp_end_of_string:
      stc
      popa
      ret

; Declaring strings that may or may not be used by the code later
INFO_WELCOME db "Welcome to DOS2B", 13, 10, "This version is DOS2B pre-alpha-1", 13, 10, 0
VIDEO_NEWLINE db 13, 10, 0
VIDEO_CMD_BUFFER times 64 db 0
CMD_PROMPT db "> ", 0
CMD_CLEAR db "clear"

; Pad the entire bootloader with zeroes because the bootloader must be exactly 512 bytes in size
times 510-($-$$) db 0

; The magic signature which tells the computer that this file is bootable
dw 0xaa55
