BITS 16

; Modifying IVT 0x42, with each entry being 4 bytes long.
ARTEMIS_IVT_OFFSET equ 0x42 * 4

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
  mov word [ARTEMIS_IVT_OFFSET], bx
  mov word [ARTEMIS_IVT_OFFSET + 2], ds

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

%include "tty.asm"
%include "disk.asm"
