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

  ; If the interrupt is not in the specified format, just exit.
  ; TODO: Actually incorporate an error handler here. (maybe?)
  jmp .exit

  ; Print out a character to the next address in video memory
  ; Parameters:
  ;   - <dl> = char
  ; Returns:
  ;   - NULL (registers preserved)
  .ch_out:
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

    ; Print the character in <dl>
    mov dh, [TTY_ATT]
    mov word [es:di], dx
    add di, 2

    ; Save this updated address so the next write can directly write to this.
    mov [ADR_VIDMEM_OFF], di

    ; Restore registers
    pop di
    pop es
    pop dx
    pop ax
    jmp .exit

  ; Note: Pop all registers before exiting
  .exit:
    ; Send End Of Interrupt (EOI) to Master PIC
    push ax
    mov al, 0x20
    out 0x20, al
    pop ax
    
    ; Return from interrupt
    iret

; Preprocessors

; Memory addresses
ADR_VIDMEM_SEG dw 0xb800
ADR_VIDMEM_OFF dw 0x0000

; Variables
TTY_ROW db 0          ; NOTE: UNUSED
TTY_COL db 0          ; NOTE: UNUSED
TTY_ATT db 0x07       ; 0x07 is the DOS default character format
