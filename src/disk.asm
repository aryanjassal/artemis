bits 16

; Reads the headers from the disk
; Parameters:
;   - dl = boot drive number
disk_read_headers:
  push ax
  push bx
  push cx
  push dx

  mov ah, 0x02
  mov al, 1
  mov bx, DISK_HEADERS
  mov cl, 1
  xor ch, ch
  xor dh, dh
  ; dl should already contain the boot drive number
  int 0x13

  pop dx
  pop cx
  pop bx
  pop ax
  ret

; Converts LBA addressing scheme to CHS
; Parameters:
;   - ax              = LBA
; Returns:
;   - cx [bits 0-5]   = sector number
;   - cx [bits 6-15]  = cylinder number
;   - dh              = head number
lba_to_chs:
  ; sector    = (lba % SECTORS_PER_TRACK) + 1
  ; cylinder  = (lba / SECTORS_PER_TRACK) / NUMBER_OF_HEADS
  ; head      = (lba / SECTORS_PER_TRACK) % NUMBER_OF_HEADS

  push ax
  push dx

  ; Calculate sector number
  xor dx, dx
  div word [SECTORS_PER_TRACK]
  inc dx
  mov cx, dx
  
  ; Calculate cylinder and head number
  xor dx, dx
  div word [NUMBER_OF_HEADS]

  ; Right now, cx is populated with the 5-bit-wide sector address
  ; from the previous calculation.
  mov ch, al
  shl ah, 6
  or cl, ah

  ; Store the head number in its output register
  mov dh, dl

  ; Restore the state of the registers
  pop ax
  mov dl, al  ; Restore dl as the drive number
  pop ax
  ret

; Read a number of sectors from the disk
; Parameters:
;   - ax    = LBA
;   - cl    = number of sectors to read (0 < n < 128)
;   - dl    = drive number
;   - es:bx = memory address to write the data to
disk_read:
  ; Save the state of all the registers that will be modified
  push ax
  push di           ; For counting as all other registers are being used

  ; Perform the disk read operation
  push cx           ; cx contains the number of sectors to read
  call lba_to_chs
  pop ax            ; ax = sectors to read, as required by interrupt 0x10

  ; Prepare for reading disk
  mov ah, 0x02      ; Required for the interrupt
  mov di, 3         ; 3 retries

  .try_read:
    push ax
    stc             ; Some BIOSes fail to set this properly
    int 0x13
    pop ax
    jnc .exit

    ; Failed to read disk on this attempt
    dec di
    test di, di
    jz .floppy_err

    ; Reset the disk controller
    push ax
    mov ah, 0
    stc
    int 0x13
    jc .floppy_err
    pop ax

    ; Try reading again
    jmp .try_read

  .floppy_err:
    mov si, ERR_FLOPPY
    call puts
    cli
    hlt

  .exit:
    pop di
    pop ax
    ret

; To enable IO with the console
%include "tty.asm"

; Disk information
; Ignore the first three bits as they are for jumping to code segment
DISK_HEADERS:             times 3 db 0
OEM_IDENTIFIER:           times 8 db 0
BYTES_PER_SECTOR          dw 0
SECTORS_PER_CLUSTER       db 0
RESERVED_SECTORS          dw 0
NUMBER_OF_FAT             db 0
DIRECTORY_ENTRY_COUNT     dw 0
TOTAL_SECTORS             dw 0
MEDIA_DESCRIPTOR_TYPE     db 0
SECTORS_PER_FAT           dw 0
SECTORS_PER_TRACK         dw 0
NUMBER_OF_HEADS           dw 0
NUMBER_OF_HIDDEN_SECTORS  dd 0
LARGE_SECTOR_COUNT        dd 0

BOOT_DRIVE_NUMBER         db 0
RESERVED                  db 0
SIGNATURE                 db 0
VOLUME_ID                 dd 0
VOLUME_LABEL:             times 11 db 0
SYSTEM_ID:                times 8 db 0

; Ensure the buffer has enough space to store four sector from the disk
times 2048 db 0

; Variable definitions
ERR_FLOPPY db "floppy read error", 0
