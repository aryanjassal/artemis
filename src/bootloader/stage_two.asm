[bits 16]

; Prepare to enter 32-bit protected mode
call fast_a20         ; Fast-enable the A20 line
cli                   ; Clear BIOS interrupts

; We need to first initialise the <ds> register before loading the GDT
xor ax, ax            ; Basically the same as <mov ax, 0> but preferred for some reason
mov ds, ax            ; Initialise <ds> register with a null value
lgdt [gdt_desc]       ; Load the GDT descriptor table

; Set PE (Protection Enable) bit in <cr0> (Control Register 0)
mov eax, cr0          ; We cannot directly modify the value of <cr0>, so first load it in the <eax> register
or eax, 1             ; Then, set the first bit in the <eax> register
mov cr0, eax          ; Finally, move the <eax> with the PE bit set back into <cr0>

jmp CODESEG:clear_pipe    ; Perform a far-jump to clear the garbage 16-bit instructions and ready code for 32-bit architecture
; The code here will not be executed, but include statements will still work

[bits 32]
clear_pipe:
  ; Store the correct address in the segment registers
  ; Refer here for the tutorial: http://www.osdever.net/tutorials/view/the-world-of-protected-mode
  mov ax, DATASEG   ; Store the proper segment value in the <ax> register
  mov ds, ax        ; Store proper value in the <ds> register (<ds> register stores variables)
  mov ss, ax        ; Store proper value in the <ss> regsiter (<ss> register is the stack segment)
  mov esp, 0x90000  ; Start the stack at memory address 0x90000 (refer to the memory address table in the aforementioned site)

  ; mov [0xb8000], byte "3"         ; Move '3' into the VGA video memory
  ; mov [0xb8001], byte 00001111b   ; Set the text formatting for the character
  ; mov [0xb8002], byte "2"         ; Move '2' into the VGA video memory
  ; mov [0xb8003], byte 00001111b   ; Set the text formatting for the character
  ; mov [0xb8004], byte "-"         ; Move '-' into the VGA video memory
  ; mov [0xb8005], byte 00001111b   ; Set the text formatting for the character
  ; mov [0xb8006], byte "b"         ; Move 'b' into the VGA video memory
  ; mov [0xb8007], byte 00001111b   ; Set the text formatting for the character
  ; mov [0xb8008], byte "i"         ; Move 'i' into the VGA video memory
  ; mov [0xb8009], byte 00001111b   ; Set the text formatting for the character
  ; mov [0xb800a], byte "t"         ; Move 't' into the VGA video memory
  ; mov [0xb800b], byte 00001111b   ; Set the text formatting for the character
  ; mov [0xb800c], byte " "         ; Move ' ' into the VGA video memory
  ; mov [0xb800d], byte 00001111b   ; Set the text formatting for the character
  
  ; Code here shouldn't ever be executed. The code here is only if the kernel somehow returned.
  jmp $

; Useful methods to enter protected mode
[bits 16]

; This is a method to quickly enable the A20 line required for protected mode
fast_a20:
  in al, 0x92
  or al, 2
  out 0x92, al
  ret

; Set up the GDT table
gdt:
  ; The first entry in the GDT should always be null
  gdt_null:
    dq 0
    dq 0
  
  ; The GDT Segment Descriptor is quite poorly defined
  ; Refer to the Segment Descriptor Table found at https://wiki.osdev.org/Global_Descriptor_Table 

  ; This defines the code segment of the GDT
  gdt_code:
    dw 0xffff       ; The limit of the code segment (4GiB)
    dw 0            ; The base of the code segment (starts at 0)
    db 0            ; The base address extends further
    db 10011010b    ; Setting the access bits (refer to the Access Byte table using the link above)
    db 11001111b    ; First 4 bits (1111b) is another part of the limit. The rest 4 bits are flags. Go to the osdev wiki and look at the Flags table.
    db 0            ; This is the final part of the base
  
  ; This defines the data segment of the GDT
  ; Basically the same as the code segment except some minor differences
  ; Refer to http://www.osdever.net/tutorials/view/the-world-of-protected-mode for more information
  gdt_data:
    dw 0xffff       ; The limit of the code segment (4GiB)
    dw 0            ; The base of the code segment (starts at 0)
    db 0            ; The base address extends further
    db 10010010b    ; Setting the access bits (refer to the Access Byte table using the link above)
    db 11001111b    ; First 4 bits (1111b) is another part of the limit. The rest 4 bits are flags. Go to the osdev wiki and look at the Flags table.
    db 0            ; This is the final part of the base
  
; This is where the GDT table description ends. Useful for size calculation during compile time.
gdt_end:

; The actual GDT descriptor table
; For some reason, this does not coincide with the table given on both osdever and osdev wiki site but is the code from osdever site
gdt_desc:
  dw gdt_end - gdt - 1    ; This is the total size of the GDT table minus 1 as per the requirements
  dd gdt

CODESEG equ gdt_code - gdt_null
DATASEG equ gdt_data - gdt_null