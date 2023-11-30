org 0x0000
bits 16

_start:
  call clear
  mov si, MSG_GREET
  call puts
  mov si, TTY_PROMPT
  call puts
  
  .kb_loop:
    mov di, [KBD_BUFFER]
    call getch
    mov si, [KBD_BUFFER]
    call putc
    jmp .kb_loop

  cli
  hlt

; Prints out a single printable character, otherwise prints '?'
; TODO: backspace doesn't backspace to the previous line
; TODO: is <push bx> <pop bx> even required here?
; Parameters:
;   - ds:si = character to print
putc:
  push ax
  push bx
  mov ah, 0x0e
  lodsb

  ; Do we even need to check for special characters?
  cmp al, 0x20
  jl .special_handler
  
  ; If not, then just print the character and return
  int 0x10
  jmp .exit

  ; Othewise, invoke special handlers for the keys
  .special_handler:
    ; Handle backspace
    cmp al, K_BS
    je .bs

    ; Handle return key
    cmp al, K_RET
    je .ret
    
    ; Handle unknown keys
    mov al, "?"
    int 0x10
    jmp .exit

  ; Backspace handler
  .bs:
    int 0x10
    mov al, " "
    int 0x10
    mov al, K_BS
    int 0x10
    jmp .exit

  ; Return handler
  .ret:
    int 0x10
    mov al, 0x0a  ; Line feed
    int 0x10
    jmp .exit

  .exit:
    pop bx
    pop ax
    ret

; Prints out a null-terminated string to the teletype output
; Not relying on putc actually makes this faster and more efficient
; TODO: is <push bx> <pop bx> even required here?
; Parameters:
;   - ds:si = first character of string
puts:
  push ax
  push bx
  mov ah, 0x0e

  .loop:
    lodsb
    or al, al
    jz .exit
    int 0x10
    jmp .loop

  .exit:
    pop bx
    pop ax
    ret

; Clears the screen and resets the cursor position
clear:
  push ax
  push bx
  push cx
  push dx

  ; Clear the screen
  mov ah, 0x06
  xor al, al
  xor cx, cx
  mov dh, 25
  mov dl, 80
  int 0x10

  ; Reset the cursor position
  mov ax, 0x02
  xor bx, bx
  xor dx, dx
  int 0x10

  pop dx
  pop cx
  pop bx
  pop ax
  ret

; Get a character and store it at the specified memory address.
; This function also adds a null value to terminate the input
; Parameters:
;   - es:di = buffer in memory to write characters to
getch:
  push ax
  xor ah, ah
  int 0x16
  stosb
  pop ax
  ret

; Preprocessor macros
%define ENDL 0x0d, 0x0a

K_BS  equ 0x08
K_RET equ 0x0d
K_NL  equ 0x0a
K_ESC equ 0x1b
K_DEL equ 0x7f

; Strings
MSG_GREET db "Welcome to DOS2B v0.0.4", ENDL, 0
TTY_PROMPT db "> "

; Declare a 2-byte buffer for keystrokes
KBD_BUFFER dw 0
