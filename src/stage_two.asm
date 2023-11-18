[org 0x7e00]

; Clear the screen
call clear

; Print a simple welcome message to the user
mov si, INFO_WELCOME
call print

; Print a newline before handing control over to the command parser
mov si, VIDEO_NEWLINE
call print

.command_loop:
  ; Print the command prompt to the screen
  mov si, CMD_PROMPT
  call print

  ; Reference the keyboard input buffer to <di>, then get the string
  mov di, VIDEO_CMD_BUFFER
  mov ch, 64
  call get_string

  ; Check if the command entered is the command to clear the screen
  mov si, VIDEO_CMD_BUFFER
  mov di, CMD_CLEAR
  call strcmp
  jc .__cmdloop_clear_screen

  ; Check if the user wishes to be greeted
  mov si, VIDEO_CMD_BUFFER
  mov di, CMD_GREET
  call strcmp
  jc .__cmdloop_greet

  ; Check if the user wishes to poweroff the computer
  mov si, VIDEO_CMD_BUFFER
  mov di, CMD_POWEROFF
  call strcmp
  jc .__cmdloop_poweroff

  ; Do the same with the FUCK command
  mov si, VIDEO_CMD_BUFFER
  mov di, CMD_FUCK
  call strcmp
  jc .__cmdloop_poweroff

  ; Check if the user wants to see the help text
  mov si, VIDEO_CMD_BUFFER
  mov di, CMD_HELP
  call strcmp
  jc .__cmdloop_help

  ; Check if it is a blank line 
  mov si, VIDEO_CMD_BUFFER
  cmp byte [si], 0
  je .command_loop

  ; If it is an invalid command, tell the user that
  mov si, CMD_INVALID_COMMAND
  call print
  jmp .command_loop

.__cmdloop_clear_screen:
  call clear
  jmp .command_loop

.__cmdloop_greet:
  mov si, CMD_PROMPT_NAME
  call print
  mov di, VIDEO_CMD_BUFFER
  call get_string
  mov si, CMD_GREET_GREETING
  call print
  mov si, VIDEO_CMD_BUFFER
  call print
  mov si, VIDEO_NEWLINE
  call print
  jmp .command_loop

.__cmdloop_poweroff:
  jmp 0xffff:0x0000

.__cmdloop_help:
  mov si, CMD_HELP_TEXT
  call print
  jmp .command_loop

; Just in case the code somehow reaches this place (it shouldn't)
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
  push ax     ; Push the <ax> register onto the stack because it will be used.
  xor cl, cl  ; Clear the <cl> register because this will be used to keep track of the characters entered

  ; The main loop that reads a character until the buffer is full
  .__get_string_loop:
    xor ah, ah    ; Clear the value of the <ah> register
    int 0x16      ; Call the BIOS interrupt to read a character from the keyboard

    cmp al, 0x08                        ; Check if the entered key is <0x08> or <backspace>
    je .__get_string_handle_backspace   ; If it is, then jump to the subroutine to handle backspaces
    
    cmp al, 0x0d                        ; Check if the entered key is <0x0d> or <return>
    je .__get_string_handle_return      ; If it is, then jump to the subroutine to handle returns

    cmp cl, ch                  ; Check if the value of <cl> counter is the same as the maximum length <ch>
    je .__get_string_loop       ; If yes, then jump back to the character reading loop, only allowing enter and return characters

    mov ah, 0x0e  ; Tell the BIOS that we want to print a character onto the screen
    int 0x10      ; Call the BIOS video interrupt

    stosb                     ; Store the value of the <al> register to the <si> register
    inc cl                    ; Increment the <cl> counter register
    jmp .__get_string_loop    ; Loop back to fetch another character from the user

  ; This subroutine handles backspaces entered into the program
  .__get_string_handle_backspace:
    cmp cl, 0               ; Check if the <cl> counter is 0 (at the start of the string)
    je .__get_string_loop   ; In that case, ignore it
    
    dec di              ; Otherwise, decrement the memory address where <di> points (the buffer)
    dec cl              ; Decrement the <cl> counter
    mov byte [di], 0    ; Move null (0) to the current address pointed by the <di> register

    mov ah, 0x0e        ; Tell the BIOS that we will be printing a character to the screen
    mov al, 0x08        ; Move the <backspace> character to the <al> register to print
    int 0x10            ; Call the BIOS video interrupt

    mov al, " "         ; Store an empty space in the <al> register to erase the character
    int 0x10            ; Call the BIOS video interrupt

    mov al, 0x08        ; Move another <backspace> character to the <al> register
    int 0x10            ; Call the BIOS video interrupt

    jmp .__get_string_loop    ; Jump to the main characters loop

  ; This subroutine handles returns or enter keys entered into the program
  .__get_string_handle_return:
    xor al, al      ; Clear the value of the <al> register
    stosb           ; Store the value of the <al> register into the <si> register

    mov ah, 0x0e    ; Tell the BIOS that we want to print a character to the screen
    mov al, 0x0d    ; Move the return feed character into the <al> register
    int 0x10        ; Call the BIOS video interrupt

    mov al, 0x0a    ; Move the newline character to the <al> buffer
    int 0x10        ; Call the BIOS video interrupt
    pop ax          ; Pop the <ax> register back from the stack
    ret             ; Return from this function

; Compare if the two strings in <si> and <di> are the same
; If they are, then set the carry flag, otherwise the carry flag will not be set
strcmp:
  pusha     ; Push all the registers onto the stack because they will be used.
  
  ; This subroutine compares one byte of the strings in <al> and <bl>
  .__strcmp_cmp_byte:
    mov al, [si]                    ; Move the current value of <si> register to the <al> register
    mov bl, [di]                    ; Move the current value of <di> register to the <bl> register
    cmp al, bl                      ; Compare if both the bytes are equal
    jne .__strcmp_bytes_not_equal   ; If not, then execute the corresponding code

    cmp al, 0                       ; Now that we know that the bytes are equal, check if they are null (end of string)
    je .__strcmp_end_of_string      ; If yes, then jump to the correspondig code to handle the end of a sttring

    inc di                          ; Otherwise, increment the memory address pointed to by the <di> register
    inc si                          ; Obviously, do the same for the <si> register
    jmp .__strcmp_cmp_byte          ; Then jump back to the loop

    ; This subroutine executes when any two bytes are not equal
    .__strcmp_bytes_not_equal:
      clc     ; Clear the carry flag
      popa    ; Pop all the registers
      ret     ; Return from this function

    ; This subroutine executes when the end of the string has reached with the same bytes till now
    .__strcmp_end_of_string:
      stc     ; Set the carry flag
      popa    ; Pop all the registers
      ret     ; Return from this function

; Declaring strings that may or may not be used by the code later
VIDEO_CMD_BUFFER times 64 db 0
VIDEO_ENDLINE db 13, 10
VIDEO_NEWLINE db 13, 10, 0

INFO_WELCOME db "Welcome to DOS2B (ver. pre-alpha-3)", 13, 10, "Type `help` to view a list of all commands", 13, 10, 0
CMD_PROMPT db "> ", 0
CMD_CLEAR db "clear", 0
CMD_GREET db "greet", 0
CMD_PROMPT_NAME db "Enter your name: ", 0
CMD_GREET_GREETING db "Hello, ", 0
CMD_HELP db "help", 0
CMD_POWEROFF db "poweroff", 0
CMD_FUCK db "fuck", 0
CMD_INVALID_COMMAND db "The entered command is invalid.", 13, 10, "Type `help` to see the list of all the commands.", 13, 10, 0
CMD_HELP_TEXT db 13, 10, "`clear`     clears the screen", 13, 10, "`greet`     greets the user by prompting for their name first", 13, 10, "`poweroff`  powers the system down", 13, 10, "`fuck`      to use when you are angry", 13, 10, "`help`      shows this help menu", 13, 10, 13, 10, 0
