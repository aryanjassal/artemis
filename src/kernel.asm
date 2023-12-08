org 0x0000
bits 16
cpu 8086

_start:
  ; Reigster interrupts immediately
  call register_interrupts

  ; ; Test int 0x21 service 0x02 (char_out)
  ; mov ah, 0x02
  ; mov dl, "X"
  ; int 0x21
  ; mov dl, "Y"
  ; int 0x21
  ; mov dl, "Z"
  ; int 0x21

  ; Test int 0x21 service 0x09 (str_out)
  mov bx, MSG_GREET
  mov ah, 0x09
  int 0x21
  ; int 0x21

  ; Test int 0x21 service 0x01 (kb_in)
  mov ah, 0x01
  .loop:
    int 0x21
    jmp .loop

  ; Just halt here because there is nothing else to do
  cli
  hlt

; Include the dos interrupts
%include "dos_int.asm"

; Strings ($-terminated or null-terminated)
MSG_GREET db "Welcome to Artemis v0.0.5 (formerly DOS2B)", 0x0d, "$"

; Variable declarations
BOOT_DRIVE db 0
