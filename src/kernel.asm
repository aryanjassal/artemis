org 0x0000
bits 16
cpu 8086

_start:
  ; Reigster interrupts immediately
  call register_interrupts

  ; Test int 0x21 service 0x02
  mov ah, 0x02
  mov dl, "X"
  int 0x21
  mov dl, "Y"
  int 0x21
  mov dl, "Z"
  int 0x21

  ; Test int 0x21 service 0x09
  mov bx, MSG_GREET
  mov ah, 0x09
  int 0x21
  int 0x21

  ; Just halt here because there is nothing else to do
  cli
  hlt

; Include the dos interrupts
%include "dos_int.asm"

; Strings ($-terminated)
MSG_GREET db "Welcome to DOS2B v0.0.5&", KEY_BACK, KEY_CR, 
          db "/n NEWLINE TEST*", KEY_CR, 
          db "&", KEY_BACK, KEY_BACK, "]", KEY_CR, STR_END

; Buffers
KBD_BUFFER: times 32 db 0

; Variable declarations
BOOT_DRIVE db 0
