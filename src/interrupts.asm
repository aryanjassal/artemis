; Provide interrupt services similar to MS-DOS's interrupt API.
; Refer to https://en.wikipedia.org/wiki/DOS_API for a detailed list of the
; available API calls and how they work.
; Note that any specific API calls may or may not be implemented.

BITS 16

; Modifying IVT 0x42, with each entry being 4 bytes long.
DOS_IVT_OFFSET equ 0x42 * 4

; Registers all the interrupt handlers in the Interrupt Vector Table.
; @param  None
; @return None
register_interrupts:
  ; Save registers being modified.
  push ax
  push bx
  push cx
  push ds

  ; Load the address of the interrupt handler before <ds> is changed.
  ; <ds> has the address of the current segment, which can then be used for
  ; calculating the absolute address.
  mov bx, int42h_handler
  mov ax, ds
  mov cl, 4
  shl ax, cl
  add bx, ax
  
  ; Set correct <ds> for proper <mov> operation.
  xor ax, ax
  mov ds, ax

  ; Modifying the IVT shouldn't be interrupted.
  cli
  
  ; The format of an entry in the IVT follows <segment:offset> formatting.
  ; Thus, the first two bytes are used for the offset, and the last two for the
  ; segment. The IVT spans from 0x0000:0x0000 to 0x0000:0x03ff.
  mov word [DOS_IVT_OFFSET], bx
  mov word [DOS_IVT_OFFSET + 2], ds

  ; Re-enable interrupts as the atomic operation has finished.
  sti

  ; Restore the register state and exit.
  pop ds
  pop cx
  pop bx
  pop ax
  ret

; Handles 0x42 interrupts.
; TODO: document this better
; TODO: remake the interrupts list
int42h_handler:
  ; <ah> = 0x01
  ; Character output with echo
  cmp ah, 0x01
  je .h_01h

  ; <ah> = 0x02
  ; Character output
  cmp ah, 0x02
  je .h_02h

  ; <ah> = 0x07
  ; Character output without echo
  cmp ah, 0x07
  je .h_07h

  ; <ah> = 0x09
  ; Character string output
  cmp ah, 0x09
  je .h_09h

  ; If the interrupt is not in the specified format, just exit.
  stc
  jmp .exit

  ; Input a character from the user and output it to the next memory address
  ; TODO: optimise this
  ; @param  None
  ; @return `al` Character read
  .h_01h:
    push ax
    push dx

    xor ax, ax
    int 0x16
    
    ; ------------------------------
    ; NOTE: DEBUG: for testing only
    ; ------------------------------
    cmp al, 0x1b
    jne .ignore
    jmp 0xffff:0x0000
    .ignore:
    ; ------------------------------

    mov dl, al
    call putc
    
    pop dx
    pop ax

    call update_cursorpos
    jmp .exit

  ; Print out a character to the next address in video memory
  ; @param  `dl` Character to output
  ; @return None
  .h_02h:
    ; Split out this function so other interrupts can also call it.
    call putc
    call update_cursorpos
    jmp .exit

  ; Input a character from the keyboard without echoing it.
  ; @param  None
  ; @return `al` Character read
  .h_07h:
    xor ax, ax
    int 0x16
    mov ah, 0x07  ; Hack in the <ah> restore
    je .exit

  ; Print out a string to the next address in video memory terminated by `$`
  ; or null-terminated.
  ; TODO: optimise this
  ; @param  `ds:bx` Pointer to string
  ; @return None
  .h_09h:
    ; Save registers
    push bx
    push dx

    ; Main print loop
    .str_loop:
      ; Check for termination characters.
      mov dl, [ds:bx]
      cmp dl, 0
      je .str_exit

      call putc
      inc bx
      jmp .str_loop

      ; If it is the termination character, then exit
      .str_exit:
        pop dx
        pop bx
        call update_cursorpos
        jmp .exit

  ; Note: Pop all registers prior to exiting
  .exit:
    ; Send End Of Interrupt (EOI) to Master PIC
    push ax
    mov al, 0x20
    out 0x20, al
    pop ax
    
    ; Return from interrupt
    iret

; Reads disk starting with the given LBA to specified number of sectors.
; @param  `ax`    Logical block address (LBA) of sector
; @param  `cl`    Number of sectors to read
; @return `es:di` The address of buffer to put in data to
; TODO: actually implement this
disk_read:
  ret

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

