[BITS 16]

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
    ; ------v--- this bit controls the data segment growing up or down. The aforementioned osdever site is giving contradictory information about this.
    db 10010010b    ; Setting the access bits (refer to the Access Byte table using the link above)
    db 11001111b    ; First 4 bits (1111b) is another part of the limit. The rest 4 bits are flags. Go to the osdev wiki and look at the Flags table.
    db 0            ; This is the final part of the base
  
; This is where the GDT table description ends. Useful for size calculation during compile time.
gdt_end:

; The actual GDT descriptor table
; For some reason, this does not coincide with the table given on both osdever and osdev wiki site but is the code from osdever site
gdt_desc:
  dw gdt_end - gdt - 1    ; This is the total size of the GDT table minus 1 as per the requirements
  dq gdt

codeseg equ gdt_code - gdt_null
dataseg equ gdt_data - gdt_null