; Provide interrupt services similar to MS-DOS's interrupt API.
; Refer to https://en.wikipedia.org/wiki/DOS_API for a detailed list of the
; available API calls and how they work.
; Note that any specific API calls may or may not be implemented.

BITS 16

; Modifying IVT 0x21, with each entry being 4 bytes long.
DOS_IVT_OFFSET equ 0x21 * 4

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


  ; Modifying the IVT shouldn't be interrupted.
  cli
  
  ; The format of an entry in the IVT follows <segment:offset> formatting.
  ; Thus, the first two bytes are used for the offset, and the last two for the
  ; segment. Note that the IVT spans 0x0000:0x0000 to 0x0000:0x03ff.
  mov word [DOS_IVT_OFFSET], bx
  mov word [DOS_IVT_OFFSET + 2], ds

  ; Now the atomic operation has ended and interrupts can work again.
  sti

  ; Restore the register state and exit.
  pop ds
  pop cx
  pop bx
  pop ax
  ret

; Handles 0x21 interrupts.
; Refer to https://grandidierite.github.io/dos-interrupts/ for details.
int21h_handler:
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

      ; Null-checked, as we shouldn't be able to print <NULL> normally
      .str_print:
        cmp dl, 0
        jne .p
        mov dl, "?"
        .p:
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
; TODO: handle backspace and return
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
  je .handle_ret

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
    .back_loop:
      sub di, 2
      cmp byte [es:di + 2], 0
      je .back_loop

      mov byte [es:di], 0
      mov [ADR_VIDMEM_OFF], di
      jmp .exit

  ; Handle return
  ; TODO: split it into handling CR/LF
  .handle_ret:
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

; Preprocessors
STR_END         equ "$"     ; The default string terminator in MS-DOS
KEY_BACK        equ 0x08
KEY_CR          equ 0x0d
KEY_LF          equ 0x0a

; Memory addresses
ADR_VIDMEM_SEG dw 0xb800
ADR_VIDMEM_OFF dw 0x0000

; Variables
TTY_ROW db 0          ; NOTE: UNUSED (for now)
TTY_COL db 0          ; NOTE: UNUSED (for now)
TTY_ATT db 0x07       ; 0x07 is the MS-DOS default character format
TTY_NUM_MAXCOL db 80
TTY_MAXCOL db 80 * 2  ; 2 bytes per character
TTY_MAXROW db 25

