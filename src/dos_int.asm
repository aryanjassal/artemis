; Provide interrupt services similar to MS-DOS"s interrupt API.
; Refer to https://en.wikipedia.org/wiki/DOS_API for a detailed list of the
; available API calls and how they work.
; Note that any specific API calls may or may not be implemented.

BITS 16

; Modifying IVT 0x21, with each entry being 4 bytes long.
DOS_IVT_OFFSET equ 0x21 * 4
; KBD_IVT_OFFSET equ 0x09 * 4

; Registers all the interrupt handlers in the Interrupt Vector Table.
; Parameters:
;   - NULL
; Returns:
;   - NULL (registers preserved)
register_interrupts:
  ; Save registers being modified.
  push ax
  push bx
  push cx
  push ds

  ; Load the address of the interrupt handler before <ds> is changed.
  ; <ds> has the address of the current segment, which can then be used for
  ; calculating the absolute address.
  mov bx, int21h_handler
  mov ax, ds
  mov cl, 4
  shl ax, cl
  add bx, ax
  
  ; Set correct <ds> for proper <mov> operation.
  xor ax, ax
  mov ds, ax

  ; Modifying the IVT shouldn"t be interrupted.
  cli
  
  ; The format of an entry in the IVT follows <segment:offset> formatting.
  ; Thus, the first two bytes are used for the offset, and the last two for the
  ; segment. Note that the IVT spans 0x0000:0x0000 to 0x0000:0x03ff.
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

; Handles 0x21 interrupts.
; TODO: use <dec> to possibly optimise this?
; TODO: optimise this as so many branches negatively affect the cpu's look-ahead
; Refer to https://grandidierite.github.io/dos-interrupts/ for details.
int21h_handler:
  ; <ah> = 0x01
  ; Character output with echo
  cmp ah, 0x01
  je .echo_ch_in

  ; <ah> = 0x02
  ; Character output
  cmp ah, 0x02
  je .ch_out

  ; <ah> = 0x09
  ; Character string output (terminated by `$`)
  cmp ah, 0x09
  je .str_out

  ; If the interrupt is not in the specified format, just exit.
  ; TODO: Actually incorporate an error handler here. (maybe?)
  jmp .exit

  ; Print out a character to the next address in video memory
  ; TODO: <ctrl-c> and <ctrl-break> handler
  ; TODO: clean up, document, and optimise this
  ; Parameters:
  ;   - NULL
  ; Returns:
  ;   - <al> = character read
  .echo_ch_in:
    push ax
    push dx

    xor ax, ax
    int 0x16
    mov dl, al
    call putc
    
    pop dx
    pop ax

    jmp .exit

  ; Print out a character to the next address in video memory
  ; TODO: <ctrl-c> and <ctrl-break> handler
  ; Parameters:
  ;   - <dl> = char
  ; Returns:
  ;   - NULL (registers preserved)
  .ch_out:
    ; Split out this function so other interrupts can also call it.
    call putc
    jmp .exit

  ; Print out a string to the next address in video memory terminated by `$`
  ; TODO: <ctrl-c> and <ctrl-break> handler
  ; TODO: optimise this
  ; Parameters:
  ;   - <ds:bx> = pointer to string
  ; Returns:
  ;   - NULL (registers preserved)
  .str_out:
    ; Save registers
    push bx
    push dx

    ; Main print loop
    .str_loop:
      ; Check for termination character.
      mov dl, [ds:bx]
      cmp dl, STR_END
      jne .str_print

      ; If it is the termination character, then exit
      pop dx
      pop bx
      jmp .exit

      ; Null-checked, as we shouldn"t be able to print <NULL> normally
      .str_print:
        cmp dl, 0
        jne .print
        mov dl, "?"
        .print:
          call putc
          inc bx
          jmp .str_loop

  ; Note: Pop all registers before exiting
  .exit:
    ; Send End Of Interrupt (EOI) to Master PIC
    push ax
    mov al, 0x20
    out 0x20, al
    pop ax
    
    ; Return from interrupt
    iret

; Print out a character to the next address in video memory
; TODO: <ctrl-c> and <ctrl-break> handler
; TODO: in newline, backspace shouldnt remove previous word but move to previous line
; TODO: newline before and after clear
; TODO: update cursor position
; TODO: optimise it
; Parameters:
;   - <dl> = char
; Returns:
;   - NULL (registers preserved)
putc:
  ; Save registers
  push ax
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
    pop ax
    ret

  ; Handle backspace
  ; TODO: optimise this (i dont like the sub first then adding 2 to check value)
  .handle_back:
    ; If the previous character was <NULL>, then go back until it isn"t
    .back_loop:
      sub di, 2
      cmp byte [es:di], 0
      je .back_loop

    ; If the previous character was not <NULL>, then erase it
    mov byte [es:di], 0
    mov [ADR_VIDMEM_OFF], di
    jmp .exit

  ; Handle carriage return
  ; TODO: split it into handling CR/LF
  .handle_cr:
    ; Save registers for calculation
    push ax
    push cx

    ; Calculate the offset to the next line
    mov ax, di
    div byte [TTY_MAXCOL]
    xor cx, cx
    mov cl, [TTY_MAXCOL]
    sub cl, ah

    ; Fill all the byes with null value
    xor ax, ax
    rep stosb
    mov [ADR_VIDMEM_OFF], di

    ; Restore the state of the registers
    pop cx
    pop ax
    jmp .exit

  ; ; Handle line feed
  ; ; TODO: split it into handling CR/LF
  ; ; TODO: IMPLEMENT THIS
  ; .handle_lf:
  ;   ; Save registers for calculation
  ;   push ax
  ;   push cx
  ;
  ;   ; Calculate the offset to the next line
  ;   mov ax, di
  ;   div byte [TTY_MAXCOL]
  ;   xor cx, cx
  ;   mov cl, [TTY_MAXCOL]
  ;   sub cl, ah
  ;
  ;   ; Fill all the byes with null value
  ;   xor ax, ax
  ;   rep stosb
  ;   mov [ADR_VIDMEM_OFF], di
  ;
  ;   ; Restore the state of the registers
  ;   pop cx
  ;   pop ax
  ;   jmp .exit





; this is a keyboard isr i should install instead of treating it as a driver unique to dos" int 0x21. with the dos method, im liable to miss keyboard inputs when im not listening for them. if i make my own keyboard buffer, then i will be able to store and retrieve keys on demand, basically, like how linuxtty works. the keyboard will always be working without relying on whether the program wants input or not.


; Print out a character to the next address in video memory
; TODO: <ctrl-c> and <ctrl-break> handler
; Parameters:
;   - NULL
; Returns:
;   - <al> = character read
getch:
  push ax
  push bx

  mov word di, BUF_KEYBOARD
  add di, [PTR_KEYBOARD]

  mov bx, SCANCODE_MAP

  in al, 0x60
  xlatb
  mov byte [es:di], al
  inc byte [PTR_KEYBOARD]

  mov al, 0x20
  out 0x20, al

  pop bx
  pop ax
  iret

; Preprocessors
STR_END         equ "$"     ; The default string terminator in MS-DOS
KEY_BACK        equ 0x08
KEY_CR          equ 0x0d
KEY_LF          equ 0x0a

; Memory addresses
ADR_VIDMEM_SEG dw 0xb800
ADR_VIDMEM_OFF dw 0x0000

; Variables
TTY_ATT     db 0x07    ; 0x07 is the MS-DOS default character format
TTY_MAXCOL  db 80 * 2  ; 2 bytes per character
TTY_MAXROW  db 25

; Keyboard buffer
SIZE_KEYBOARD equ 128
BUF_KEYBOARD: times SIZE_KEYBOARD db 0
PTR_KEYBOARD dw BUF_KEYBOARD

SCANCODE_MAP:
  db  0,  27, "1", "2", "3", "4", "5", "6", "7", "8"    ; 9
  db "9", "0", "-", "=", 0x08                           ; Backspace
  db 0x09                                               ; Tab
  db "q", "w", "e", "r"                                 ; 19
  db "t", "y", "u", "i", "o", "p", "[", "]", 0x0a       ; Enter key
  db 0                                                  ; 29   - Control
  db "a", "s", "d", "f", "g", "h", "j", "k", "l", ";"   ; 39
  db "'", "`", 0                                        ; Left shift
  ; db "\", "z", "x", "c", "v", "b", "n"                  ; 49
  db "0", "z", "x", "c", "v", "b", "n"                  ; 49
  db "m", ",", ".", "/", 0                              ; Right shift
  db "*"
  db 0                                                  ; Alt
  db " "                                                ; Space bar
  db 0                                                  ; Caps lock
  db 0                                                  ; 59 - F1 key ... >
  db 0,   0,   0,   0,   0,   0,   0,   0
  db 0                                                  ; < ... F10
  db 0                                                  ; 69 - Num lock
  db 0                                                  ; Scroll Lock
  db 0                                                  ; Home key
  db 0                                                  ; Up Arrow
  db 0                                                  ; Page Up
  db "-"
  db 0                                                  ; Left Arrow
  db 0
  db 0                                                  ; Right Arrow
  db "+"
  db 0                                                  ; 79 - End key
  db 0                                                  ; Down Arrow
  db 0                                                  ; Page Down
  db 0                                                  ; Insert Key
  db 0                                                  ; Delete Key
  db 0,   0,   0
  db 0                                                  ; F11 Key
  db 0                                                  ; F12 Key
  times 128 - ($-SCANCODE_MAP) db 0                     ; All other keys are undefined

