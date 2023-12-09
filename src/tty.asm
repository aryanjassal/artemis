BITS 16

; Updates the cursor position on the screen.
; TODO: allow for using custom values too
; @param  None
; @return None
update_cursorpos:
  ; Change adress from byte-based to character-based. In other words, instead
  ; of calculating based on 2 bytes per character (which is what is stored
  ; in <di>), we divide that by two to get the index of each character within
  ; the video memory.
  mov bx, [ADR_VIDMEM_OFF]
  mov cl, 1
  shr bx, cl

  ; Prepare to send the row number of cursor position
  mov dx, 0x03d4
  mov al, 0x0f
  out dx, al

  ; Send the row number of cursor position
  inc dl
  mov al, bl
  out dx, al

  ; Prepare to send the column number of cursor position
  dec dl
  mov al, 0x0e 
  out dx, al

  ; Send the column number of cursor position
  inc dl
  mov al, bh
  out dx, al

  ; This is a function, so return from this
  ret

; Print out a character to the next address in video memory
; TODO: optimise it
; @param  `dl` Character to output
; @return None
putc:
  ; Save registers
  push ax
  push bx
  push cx
  push dx
  push es
  push di

  ; Set the correct location to the video memory
  mov ax, [ADR_VIDMEM_SEG]
  mov es, ax
  mov ax, [ADR_VIDMEM_OFF]
  mov di, ax

  ; Handle special characters should the need arise
  cmp dl, KEY_BACK
  je .handle_back
  cmp dl, KEY_CR
  je .handle_cr

  ; Otherwise print the current character
  .print_ch:
    mov dh, [TTY_ATT]
    mov word [es:di], dx
    add di, 2

    ; Save the new memory address back into the video memory offset
    mov [ADR_VIDMEM_OFF], di

  ; Restore the register state and exit
  .exit:
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

  ; Handle backspace
  ; TODO: optimise this (i dont like the sub first then adding 2 to check value)
  .handle_back:
    ; If the previous character was <NULL>, then go back until it isn't
    .back_loop:
      sub di, 2
      cmp byte [es:di], 0
      je .back_loop

    ; Save the new video address to memory and exit
    mov [ADR_VIDMEM_OFF], di
    jmp .exit

  ; Handle carriage return
  ; TODO: split it into handling CR/LF. this needs custom keyboard handler
  .handle_cr:
    ; Save registers for calculation
    push ax
    push cx

    ; Change adress from byte-based to character-based. In other words, instead
    ; of calculating based on 2 bytes per character (which is what is stored
    ; in <di>), we divide that by two to get the index of each character within
    ; the video memory.
    mov ax, di
    mov cl, 1
    shr ax, cl

    ; Calculate the offset to the next line
    xor ch, ch
    mov cl, [TTY_MAXCOL]

    div cl
    sub cl, ah

    ; Append a <space> character before going to a newline, as this is what will allow
    ; backspace to return to the previous line instead of removing the last character
    ; from it.
    dec cl
    mov ah, [TTY_ATT]
    mov al, " "
    stosw

    ; Fill all the byes with null value
    xor al, al
    rep stosw
    mov [ADR_VIDMEM_OFF], di

    ; Restore the state of the registers
    pop cx
    pop ax
    jmp .exit

  ; TODO: handle line feed

; Preprocessors
KEY_BACK        equ 0x08
KEY_CR          equ 0x0d
KEY_LF          equ 0x0a

; Memory addresses
ADR_VIDMEM_SEG  dw 0xb800
ADR_VIDMEM_OFF  dw 0x0000

; Variables
TTY_ATT         db 0x1f     ; 0x07 is the BIOS default terminal attribute format
TTY_MAXCOL      db 80
TTY_MAXROW      db 25

