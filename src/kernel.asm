org 0x0000
bits 16

_start:
  mov [BOOT_DRIVE], dl
  call disk_read_headers

.loop:
  call clear

  mov di, KBD_BUFFER
  xor al, al
  times 32 stosb

  mov si, MSG_GREET
  call puts
  mov si, TTY_PROMPT
  call puts

  mov bx, 0x0d
  mov cx, 8
  mov di, KBD_BUFFER
  call getstr

  jnc .nerr
  
  mov si, ERR_OVERFLOW
  call puts

  call getch
  jmp .loop

  .nerr:
    mov si, DBG_INPUT
    call puts

    mov si, KBD_BUFFER
    call puts

    call getch
    jmp .loop
  cli
  hlt

; "disk.asm" includes "tty.asm"
%include "disk.asm"

; Strings
MSG_GREET db "Welcome to DOS2B v0.0.5", ENDL, 0
ERR_OVERFLOW db ENDL, "BUFFER OVERFLOW", 0
DBG_INPUT db ENDL, "INPUT OK", ENDL, "YOU ENTERED: ", 0
TTY_PROMPT db "> ", 0

; Buffers
KBD_BUFFER: times 32 db 0

; Variable declarations
BOOT_DRIVE db 0
