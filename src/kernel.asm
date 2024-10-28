org 0x0000
bits 16
cpu 8086

_start:
  ; Reigster interrupts immediately
  call register_interrupts

  ; mov dl, 0x7e
  ; mov ax, 0x02
  ; int 0x42

  ; Clear screen
  ; TEST: temporary
  mov ax, 0x08
  int 0x42

  ; Test int 0x42 service 0x09 (str_out)
  mov cx, MSG_GREET
  mov ax, 0x09
  int 0x42

  ; Test int 0x42 service 0x01 (kb_in)
  mov ax, 0x01
  .loop:
    mov ax, 0x01
    int 0x42
    jmp .loop

  ; Halt here because there is nothing else to do
  cli
  hlt

; Include the interrupts
%include "interrupts.asm"

; Strings (null-terminated)
; 0x0d stands for \n
MSG_GREET db "Welcome to Artemis-16 alphadev", 0x0d, 0x00

; Variable declarations
BOOT_DRIVE db 0
