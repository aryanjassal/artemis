vprint:
  pusha
  
  .__vga_print_loop:
    mov al, [si]
    cmp al, 0
    jnz .__vga_print_char
    popa
    ret

  .__vga_print_char:
    mov [0xb8000], ah
    add si, 1
    jmp .__vga_print_loop