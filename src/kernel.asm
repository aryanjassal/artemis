org 0x0000
bits 16

_start:
  mov si, MSG_BOOT_SUCCESSFUL
  call print
  cli
  hlt

; Prints out a null-terminated string pointed to by the si register
print:
  push ax
  push bx
  push cx
  push dx
  mov ah, 0x0e

  .loop:
    mov al, [si]            ; Move the next character into al
    test al, al             
    jnz .print_char
    pop dx
    pop cx
    pop bx
    pop ax
    ret
 
  .print_char:
    int 0x10
    inc si
    jmp .loop

MSG_BOOT_SUCCESSFUL db "Welcome to DOS2B v0.0.3", 0
