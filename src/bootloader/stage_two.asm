; Provide the _start symbol globally so the linker doesn't complain
[global _start]
; Compile this file with the 32-bit instruction set
[bits 32]
; This start label is here just to tell the linker where the executable code startes from
_start:
   ; Halt execution of code here for now
   jmp $
