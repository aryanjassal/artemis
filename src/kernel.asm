org 0x0000
bits 16
cpu 8086

_start:
  ; Reigster interrupts immediately
  call register_interrupts

  ; Test int 0x21 service 0x09 (str_out)
  mov bx, MSG_GREET
  mov ah, 0x09
  int 0x21

  ; Test int 0x21 service 0x01 (kb_in)
  mov ah, 0x01
  .loop:
    int 0x21
    jmp .loop

  ; Halt here because there is nothing else to do
  cli
  hlt

; Include the dos interrupts
%include "interrupts.asm"

; Strings (null-terminated)
MSG_GREET db "Welcome to DOS2B v0.0.5 (eventually Artemis)", 0x0d, 0

; Variable declarations
BOOT_DRIVE db 0
