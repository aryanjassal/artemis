;! This entire file is basically redundant now.
;! This is still here just in case.
bios_print:
  pusha     ; Push the <a> registers because they will be used

  ; This method loops over all characters in a string to print them (null-terminated).
  .print_loop:
    mov al, [si]      ; Move the next character into the <al> register, which is supposed to contain the character to print
    cmp al, 0         ; Check if the next character to print is 0 (null)
    jnz .print_char   ; If it really is 0 (null), then we have reached the end of the string. Prepare to exit the method.
    popa              ; Pop the pushed values for the <a> registers back
    ret               ; Safely return back to the memory address where this jump statement was called
  
  ; This method prints a single character on the screen
  .print_char:
    mov ah, 0x0e      ; Tell the BIOS we are meant to print a character to the screen
    int 0x10          ; Call the intterupt to print the character (which should be in <al> register)
    add si, 1         ; Add 1 to the counter of current character to print the next character
    jmp .print_loop   ; Jump back to the print loop to print the next character

;! Maybe redundant and not required
; Define newline constant which can be really useful
newline db 13, 10, 0