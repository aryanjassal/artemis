[org 0x7c00]

mov bp, 0x7c00            ; Move the stack base pointer at the memory address 0x7c00
mov sp, bp                ; Move the current stack pointer at the baes (stack is empty)
mov [BOOT_DISK], dl       ; Store the boot disk for later use
SECOND_STAGE equ 0x8000   ; This is where the second stage will be loaded to

call readdisk
jmp SECOND_STAGE

; This method reads a given number of sectors from the boot disk
readdisk:
  mov ah, 0x02            ; Tell the BIOS we'll be reading the disk
  mov bx, SECOND_STAGE    ; Put the new data we read from the disk starting from the specifed location
  mov al, 15              ; Read n number of sectors from disk
  mov dl, [BOOT_DISK]     ; Read from the disk [boot drive]
  mov ch, 0x00            ; Cylinder 0
  mov dh, 0x00            ; Head 0
  mov cl, 0x02            ; Sector 2

  int 0x13                ; Read disk interrupt
  jc diskreadfailed       ; Jump to error handler (kinda?) if diskread fails
  ret                     ; Return the control flow

; Print an error message that the disk was not able to be read properly then hang indefinitely.
diskreadfailed:
  mov si, error_diskreaderror
  call bios_print
  jmp $

; Create variables for when the reading fails and store the boot disk
error_diskreaderror db "Disk read failed!", 13, 10, 0
BOOT_DISK db 0

; Include the BIOS print routine
%include "print.asm"

; Pad the entire bootloader with zeroes because the bootloader must be exactly 512 bytes in size
times 510-($-$$) db 0

; The magic signature which tells the computer that this file is bootable
dw 0xaa55