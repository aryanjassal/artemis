bits 16

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
    je .cr
    
    ; Handle unknown keys
    mov al, "?"
    int 0x10
    jmp .exit

  ; Backspace handler
  .bs:
    int 0x10
    xor al, al
    int 0x10
    mov al, K_BS
    int 0x10
    jmp .exit

  ; Carriage return handler
  .cr:
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

; Get a string from the user and store it at the specified address.
; Termination characters can be custom-defined.
; Parameters:
;   - bl    = termination character
;   - cx    = size of buffer
;   - es:di = buffer in memory to write characters to
getstr:
  push dx
  mov dx, cx
  .loop:
    ; If the buffer is full, then exit
    or cx, cx
    jz .err

    ; Otherwise, load and handle the next character
    xor ah, ah
    int 0x16

    cmp al, K_BS
    jne .cont
    cmp cx, dx
    je .loop

    .cont:
      ; Print the input character onto the screen
      mov [K_BUF], al
      mov si, K_BUF
      call putc

      ; Decrement the counter for free space
      dec cx

      ; If this character is our termination character, then exit
      cmp bl, al
      jz .exit

      ; Otherwise, check for special characters
      cmp al, 0x20
      jl .special_handler
      
      ; If not, then just fetch the next character
      stosb
      jmp .loop

  ; Othewise, invoke special handlers for the keys
  .special_handler:
    ; Handle backspace
    cmp al, K_BS
    je .bs

    ; Handle carriage return key
    cmp al, K_RET
    je .cr
    
    ; Ignore unknown keys

  ; Backspace handler
  .bs:
    ; If we are at the start of the buffer, do nothing
    add cx, 2
    cmp cx, dx
    je .loop

    ; Otherwise, nullify the previous byte in the buffer
    dec di
    xor al, al
    stosb
    dec di
    jmp .loop

  ; Carriage return handler
  .cr:
    stosb
    mov al, 0x0a
    stosb
    jmp .loop

  .err:
    stc

  .exit:
    pop dx
    ret

; Preprocessor macros
%define ENDL 0x0d, 0x0a

K_BS  equ 0x08
K_RET equ 0x0d
K_NL  equ 0x0a
K_ESC equ 0x1b
K_DEL equ 0x7f

; Variable definitions
CR db ENDL, 0
K_BUF db 0
