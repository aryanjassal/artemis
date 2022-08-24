; TODO: FIX THIS SHIT CODE

[org 0x7c00]        ; Set the origin of the bootloader

; Initialise the stack at 0x7c00
mov bp, 0x7c00    ; Move the stack base pointer at the memory address 0x7c00
mov sp, bp        ; Move the current stack pointer to the base (stack is empty)

; Print a simple greeting to the user
mov si, INFO_WELCOME
call bios_print

jmp $

; ---------------------------------------------
; Code after this point will not get executed
; Use it to make useful functions or variables
; ---------------------------------------------

; The BIOS print routine
bios_print:
  pusha     ; Push the <a> registers because they will be used.

  ; This method loops over all characters in a null-terminated string to print them.
  .__bios_print_loop:
    mov al, [si]            ; Move the next character into the <al> register.
    cmp al, 0               ; Check if <al> is 0 (null).
    jnz .__bios_print_char  ; If it is, then we have reached the end of the string. Prepare to exit the method.
    popa                    ; Pop the pushed values for the <a> registers back, essentially restoring their value.
    ret                     ; Safely return back to the memory address from where this function was called.
 
  ; This method prints a single character on the screen
  .__bios_print_char:
    mov ah, 0x0e            ; Tell the BIOS we will be printing a character onto the screen
    int 0x10                ; Call the interrupt to print the character (which should be in the <al> register)
    add si, 1               ; Add 1 to <si> to print the next character in the buffer
    jmp .__bios_print_loop  ; Jump back to the print loop to print the next character

; Declaring strings that may or may not be used by the code later
INFO_WELCOME db "Welcome to AprilOS!", 13, 10, 0


; BOOT_DISK db 0      ; Declare the BOOT_DISK variable

; ; mov [BOOT_DISK], dl       ; Store the boot disk for later use
; ; SECOND_STAGE equ 0x8000   ; This is where the second stage will be loaded to


; ; call read_disk        ; Call the function to read the disk to load the next stage

; ; Prepare to enter 32-bit protected mode
; call fast_a20         ; Fast-enable the A20 line
; cli                   ; Clear BIOS interrupts

; ; We need to first initialise the <ds> register before loading the GDT
; xor ax, ax            ; Basically the same as <mov ax, 0> but preferred for some reason
; mov ds, ax            ; Initialise <ds> register with a null value
; lgdt [gdt_desc]       ; Load the GDT descriptor table

; ; Set PE (Protection Enable) bit in <cr0> (Control Register 0)
; mov eax, cr0          ; We cannot directly modify the value of <cr0>, so first load it in the <eax> register
; or eax, 1             ; Then, set the first bit in the <eax> register
; mov cr0, eax          ; Finally, move the <eax> with the PE bit set back into <cr0>

; jmp CODESEG:clear_pipe    ; Perform a far-jump to clear the garbage 16-bit instructions and ready code for 32-bit architecture
; ; The code here will not be executed, but include statements will still work

; [bits 32]
; clear_pipe:
;   ; Store the correct address in the segment registers
;   ; Refer here for the tutorial: http://www.osdever.net/tutorials/view/the-world-of-protected-mode
;   mov ax, DATASEG   ; Store the proper segment value in the <ax> register
;   mov ds, ax        ; Store proper value in the <ds> register (<ds> register stores variables)
;   mov ss, ax        ; Store proper value in the <ss> regsiter (<ss> register is the stack segment)
;   mov esp, 0x90000  ; Start the stack at memory address 0x90000 (refer to the memory address table in the aforementioned site)

;   jmp $
  ; jmp SECOND_STAGE      ; Perform a jump to the second stage of the bootloader

; This method reads a given number of sectors from the boot disk
; read_disk:
;   mov ah, 0x02            ; Tell the BIOS we'll be reading the disk
;   mov cl, 0x02            ; Start reading from sector 2 (because sector 1 is where we are now)
;   mov al, 16              ; Read n number of sectors from disk
;   mov ch, 0x00            ; Cylinder 0
;   mov dh, 0x00            ; Head 0
;   xor bx, bx              ; Clear the value in <bx>
;   mov es, bx              ; Set the value of <es> to zero
;   mov dl, [BOOT_DISK]     ; Read from the disk [boot drive]
;   mov bx, SECOND_STAGE    ; Put the new data we read from the disk starting from the specifed location

;   int 0x13                ; Read disk interrupt
;   jc read_disk_failed     ; Jump to error handler (kinda?) if diskread fails
;   ret                     ; Return the control flow

; ; Print an error message that the disk was not able to be read properly then hang indefinitely.
; read_disk_failed:
;   mov si, ERROR_DISKREADERROR
;   call bios_print
;   jmp $

; Create strings for future use
; ERROR_DISKREADERROR db "Failure in reading drive!", 13, 10, 0



; ; This is a method to quickly enable the A20 line required for protected mode
; fast_a20:
;   in al, 0x92
;   or al, 2
;   out 0x92, al
;   ret

; ; Set up the GDT table
; gdt:
;   ; The first entry in the GDT should always be null
;   gdt_null:
;     dq 0
;     dq 0
  
;   ; The GDT Segment Descriptor is quite poorly defined
;   ; Refer to the Segment Descriptor Table found at https://wiki.osdev.org/Global_Descriptor_Table 

;   ; This defines the code segment of the GDT
;   gdt_code:
;     dw 0xffff       ; The limit of the code segment (4GiB)
;     dw 0            ; The base of the code segment (starts at 0)
;     db 0            ; The base address extends further
;     db 10011010b    ; Setting the access bits (refer to the Access Byte table using the link above)
;     db 11001111b    ; First 4 bits (1111b) is another part of the limit. The rest 4 bits are flags. Go to the osdev wiki and look at the Flags table.
;     db 0            ; This is the final part of the base
  
;   ; This defines the data segment of the GDT
;   ; Basically the same as the code segment except some minor differences
;   ; Refer to http://www.osdever.net/tutorials/view/the-world-of-protected-mode for more information
;   gdt_data:
;     dw 0xffff       ; The limit of the code segment (4GiB)
;     dw 0            ; The base of the code segment (starts at 0)
;     db 0            ; The base address extends further
;     db 10010010b    ; Setting the access bits (refer to the Access Byte table using the link above)
;     db 11001111b    ; First 4 bits (1111b) is another part of the limit. The rest 4 bits are flags. Go to the osdev wiki and look at the Flags table.
;     db 0            ; This is the final part of the base
  
; ; This is where the GDT table description ends. Useful for size calculation during compile time.
; gdt_end:

; ; The actual GDT descriptor table
; ; For some reason, this does not coincide with the table given on both osdever and osdev wiki site but is the code from osdever site
; gdt_desc:
;   dw gdt_end - gdt - 1    ; This is the total size of the GDT table minus 1 as per the requirements
;   dd gdt

; CODESEG equ gdt_code - gdt_null
; DATASEG equ gdt_data - gdt_null

; Pad the entire bootloader with zeroes because the bootloader must be exactly 512 bytes in size
times 510-($-$$) db 0

; The magic signature which tells the computer that this file is bootable
dw 0xaa55
