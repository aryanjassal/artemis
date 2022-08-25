; Provide the _start symbol globally so the linker doesn't complain
[global _start]
; Compile this file with the 32-bit instruction set
[bits 32]
; This start label is here just to tell the linker where the executable code startes from
_start:
  ; Move the VGA buffer to ebx
  mov ebx, 0xb8000
  mov dl, 0x0f

  ; Print something to the VGA buffer
  call vclear
  mov si, INFO_PROTECTEDMODE
  call vprint
  mov si, INFO_GREETING
  call vprint


  ; Halt execution of code here for now
  jmp $

; ---------------------------------------------
; Code after this point will not get executed
; Use it to make useful functions or variables
; ---------------------------------------------

; Implement the code to print by moving character information directly into VGA memory
vprint:
  ; Push the values of <eax>, <ecx>, and <edx> as they will be modified throughout the program
  push eax
  push ecx
  push edx

  ; This loop checks if the next character in the string is null. If it is, then return from the function
  .__vga_null_check:
    mov al, [si]              ; Load the next byte into the <al> register
    cmp al, 0                 ; Compare if the byte is <null>
    jnz .__vga_print_char     ; If it is not null, then jump to character printing loop
    pop edx                   ; If the next character is null, then the string has terminated. Pop the value of <edx> from stack.
    pop ecx                   ; Pop the value of <ecx> from stack
    pop eax                   ; Pop the valie of <eax> from the stack
    ret                       ; Then return from this function

  ; This is the main loop that handles printing a character onto the screen
  .__vga_print_char:
    cmp al, 13                ; Check if the character to print is 13 (\r)
    jz .__vga_print_return    ; Jump to the subroutine which prints the carriage return if it is

    cmp al, 10                ; Check if the character to print is 10 (\n)
    jz .__vga_print_newline   ; Jump to the subroutine which prints the next line if it is

    cmp al, 12                ; Check if the character to print is 12 (clear screen)
    jz .__vga_clear_screen    ; Jump to the subroutine which clears the screen

    ; If it is not any of the special cases, then print the character like normal
    mov byte [ebx], al        ; Move the byte to be printed into <ebx>
    inc ebx                   ; Increment the <ebx> register to point to the next memory address
    mov byte [ebx], dl        ; Move the <dl> register (with colour attributes) into the next memory address
    inc ebx                   ; Increment the <ebx> register to point it to the next memory address for the next loop
    inc si                    ; Increment the <si> register to load the next byte into memory
    jmp .__vga_null_check     ; Jump back to the loop to check if the next character in the memory is null

  ; This subroutine prints a return carriage (\r)
  .__vga_print_return:
    mov eax, ebx              ; Move the value of current position in the VGA to <eax>
    push ebx                  ; Push <ebx> to the stack as it needs to be unset

    ; Division works like this: [edx:eax / $(val)]
    ; After the operation, it stores the quotent in <eax> and the remainder in <edx>
    ; So, <edx> needs to be 0, and <eax> needs to have the value that we are dividing
    ; In this case, the value that we are dividing by is being stored in the <ecx> register

    ; To calculate the required offset, first subtract 0xb8000 from the crrent memory address to get the offset from
    ; the start of VGA memory. Then, execute the modulo operator on the result, getting the offset from the start of
    ; the line. Then, just subtract that from the current location in VGA memory to return to the beginning of the line
    mov edx, 0                ; Store 0 in <edx>
    sub eax, 0xb8000          ; Subtract the start of VGA memory from current VGA location
    mov ecx, 160              ; Move 160 to modulo the difference by

    div ecx                   ; Subtract 0xb8000 from the current location on the screen to get the offset from the start of VGA memory
    pop ebx                   ; Restore the original VGA location in the <ebx> register
    sub ebx, edx              ; Subtract the remainder from the value of <ebx>. This moves the cursor to the start of the line
    inc si                    ; Increment the <si> register to load the next byte into memory
    jmp .__vga_null_check     ; Jump back to the loop to check if the next character in the memory is null
    
  ; This subroutine prints a newline (\n)
  .__vga_print_newline:
    add ebx, 160              ; Add 160 to <ebx> essentially pointing it to directly below where the cursor was
    inc si                    ; Increment the <si> register to load the next byte into memory
    jmp .__vga_null_check     ; Jump back to the loop to check if the next character in the memory is null

  ; This subroutine clears the screen by calling the <vclear> function
  .__vga_clear_screen:
    call vclear               ; Actually call the <vclear> function to clear the screen
    inc si                    ; Increment the <si> register to load the next byte into memory
    jmp .__vga_null_check     ; Jump back to the loop to check if the next character in the memory is null

; Function to clear the VGA screen buffer
vclear:
  push ecx            ; Push the value of <ecx> to the stack as it will be modified during the code
  mov ecx, 4000       ; This is how many times to repeat the loop (80 * 25 * 2)
  mov ebx, 0xb8000    ; Move the cursor back to the start of the VGA memory
  
  ; This is the main loop that will fill all the characters on the screen to an empty space
  .__vga_clear_screen_loop:
    mov byte [ebx], " "         ; Move the space to the VGA memory to clear whatever was stored there
    inc ebx                     ; Increment the memory address to store the colour attributes
    mov byte [ebx], 0x0f        ; Store the WHITE_ON_BLACK attribute to the memory address
    inc ebx                     ; Increment <ebx> again to prepare to print the next character

    dec ecx                         ; Decrement the <ecx> register (which keeps track of number of loops remaining)
    cmp ecx, 0                      ; Check if <ecx> is now 0
    jnz .__vga_clear_screen_loop    ; If it is not zero, then jump back to the loop to clear the next character

  ; If the loop has finished, it means that we have converted all characters in VGA memory to space
  mov ebx, 0xb8000    ; Move the beginning of the VGA memory back into <ebx>
  pop ecx             ; Restore the value of the <ecx> register
  ret                 ; Return from the function

; Declaring strings
INFO_PROTECTEDMODE db "(i) successfully entered 32-bit protected mode", 13, 10, 0
INFO_GREETING db "(i) welcome to Project April, aka AprilOS!", 13, 10, 0
VGA_NEWLINE db 13, 10, 0
