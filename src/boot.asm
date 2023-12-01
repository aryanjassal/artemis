org 0x7c00
bits 16
;cpu 8086

; Mandatory part of FAT implementation
; <jmp short code> breaks everything for some reason, so <jmp code> is used 
; instead
jmp code
nop

; BIOS Parameter Block
OEM_IDENTIFIER            db "DOS2B V1"
BYTES_PER_SECTOR          dw 512
SECTORS_PER_CLUSTER       db 1
RESERVED_SECTORS          dw 1
NUMBER_OF_FAT             db 2
DIRECTORY_ENTRY_COUNT     dw 224
TOTAL_SECTORS             dw 2880
MEDIA_DESCRIPTOR_TYPE     db 0x0f0
SECTORS_PER_FAT           dw 9
SECTORS_PER_TRACK         dw 18
NUMBER_OF_HEADS           dw 2
NUMBER_OF_HIDDEN_SECTORS  dd 0
LARGE_SECTOR_COUNT        dd 0

; Extended Boot Record
BOOT_DRIVE_NUMBER         db 0
RESERVED                  db 0
SIGNATURE                 db 0x29
VOLUME_ID                 db 0x12, 0x34, 0x56, 0x78
VOLUME_LABEL              db "DOS2B      "
SYSTEM_ID                 db "FAT12   "

; Bootable code starts here
code:
  ; Initialise the data segments
  xor ax, ax
  mov ds, ax
  mov es, ax

  ; Initialise the stack
  mov ss, ax
  mov bp, 0x7c00
  mov sp, bp

  ; Far jump to ensure we are at 0000:7c00
  push es
  push word post_jump
  retf

post_jump:
  ; Just in case our drive number gets corrupted, the BIOS knows the right one
  mov [BOOT_DRIVE_NUMBER], dl

  ; Read disk data provided by disk
  push es
  mov ah, 0x08
  int 0x13
  jnc .no_err

  .no_err:
    pop es

    ; Sector count
    and cl, 0x3f
    xor ch, ch
    mov [SECTORS_PER_TRACK], cx

    ; Head count
    inc dh
    mov [NUMBER_OF_HEADS], dh

  ; Confirm that the bootloader is working
  mov si, DBG_BOOTING
  call print

  ; Get LBA of FAT root directory
  ; lba = RESERVED_SECTORS + (SECTORS_PER_FAT * NUMBER_OF_FAT)
  mov ax, [SECTORS_PER_FAT]
  mov bl, [NUMBER_OF_FAT]
  xor bh, bh
  mul bx
  add ax, [RESERVED_SECTORS]
  push ax

  ; Get size of each directory entry (in sectors)
  ; size = (32 * DIRECTORY_ENTRY_COUNT) / BYTES_PER_SECTOR
  mov ax, [DIRECTORY_ENTRY_COUNT]
  push cx
  mov cl, 5
  shl ax, cl   ; Fancy and fast way to multiply ax by 32 (2^5)
  pop cx
  xor dx, dx
  div word [BYTES_PER_SECTOR]
  test dx, dx
  jz .read_dir
  inc ax

  ; Read root directory from the LBA we just calculated
  ; The sector count to read must be in al
  .read_dir:
    mov cl, al                    ; cl    = number of sectors to read
    pop ax
    mov dl, [BOOT_DRIVE_NUMBER]   ; dl    = boot drive number
    mov bx, DISK_BUFFER           ; es:bx = buffer to read to
    call disk_read

    ; Prepare for finding <kernel.bin>
    xor bx, bx

    ; The first 11 bytes point to the name of the file
    ; This is important for using <repe cmpsb> later on
    mov di, DISK_BUFFER

  ; Now look for the <kernel.bin> file
  .find_kernel:
    mov si, F_KERN
    mov cx, 11            ; Compare upto 11 characters
    push di
    repe cmpsb
    pop di
    je .found_kernel

    ; If the kernel is not found in this directory entry
    add di, 32
    inc bx
    cmp bx, [DIRECTORY_ENTRY_COUNT]
    jl .find_kernel

    ; Kernel was not found
    mov si, ERR_NO_KERN
    call print
    cli
    hlt

  .found_kernel:
    ; Load the first cluster in the entry
    mov ax, [di + 26]
    mov [KERN_CLUSTER], ax

    ; Load FAT from disk into memory
    mov ax, [RESERVED_SECTORS]
    mov bx, DISK_BUFFER
    mov cl, [SECTORS_PER_FAT]
    mov dl, [BOOT_DRIVE_NUMBER]
    call disk_read

    ; Set es:bx to the address to load the kernel to
    mov bx, KERN_SEGMENT
    mov es, bx
    mov bx, KERN_OFFSET

  ; Process the FAT chain
  .load_kernel_loop:
    ; Read next cluster
    mov ax, [KERN_CLUSTER]

    ; ; Calculate the cluster offset
    ; sub ax, 2
    ; mul SECTORS_PER_CLUSTER
    ; ; Root directory in FAT12 has a size of 33 sectors
    ; add ax, 33

    ; For this disk, the offset can be hardcoded
    ; TODO: add dynamic offset based on actual values
    add ax, 31

    mov cl, 1
    mov dl, [BOOT_DRIVE_NUMBER]
    call disk_read

    ; Push back the buffer by the bytes read
    ; Redundant in this case, but might be required for other disks
    ; TODO: If file is > 30KiB (as per osdev wiki), then there will be an overflow.
    ; TODO: This 29.75KiB is shared with the stack, so the kernel cannot be too large
    ; This needs to be accounted and the segment register must be incrememnted.
    ; buf += SECTORS_PER_CLUSTER * BYTES_PER_SECTOR
    
    ; push ax
    ; mov ax, [BYTES_PER_SECTOR]
    ; mul word [SECTORS_PER_CLUSTER]
    ; add bx, ax
    ; pop ax

    add bx, [BYTES_PER_SECTOR]

    ; Compute location of the next cluster
    mov ax, [KERN_CLUSTER]
    mov cx, 3
    mul cx
    mov cx, 2
    div cx

    ; ax = index of next entry in FAT
    ; dx = cluster % 2

    ; Read entry at current cluster
    mov si, DISK_BUFFER
    add si, ax
    mov ax, [ds:si]

    or dx, dx
    jz .even

  .odd:
    push cx
    mov cl, 4
    shr ax, cl
    pop cx
    jmp .test_eof

  .even:
    and ax, 0x0fff

  .test_eof:
    cmp ax, 0x0ff8

    ; If we have reached 0x0ff8, then we have reached EOF
    jae .finish
    
    ; Otherwise, more clusters are yet to be read
    mov [KERN_CLUSTER], ax
    jmp .load_kernel_loop

  ; Now transfer control to the kernel
  .finish:
    ; Provide the boot drive number to the kernel 
    mov dl, [BOOT_DRIVE_NUMBER]

    ; Set segment registers for the kernel
    mov ax, KERN_SEGMENT
    mov ds, ax
    mov es, ax

    ; Far jump to the kernel
    jmp KERN_SEGMENT:KERN_OFFSET

    ; Should never happen
    cli
    hlt

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
  push cx
  mov cl, 6
  shl ah, cl
  pop cx
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
    call print
    cli
    hlt

  .exit:
    pop di
    pop ax
    ret

; Prints out a null-terminated string to the teletype output
; Parameters:
;   - ds:si = first character of string
print:
  push ax
  push bx
  mov ah, 0x0e

  .loop:
    lodsb
    or al, al
    jz .exit
    int 0x10
    jmp .loop

  .exit:
    pop bx
    pop ax
    ret

; Preprocessor macros so they don't take up any valuable disk space
%define ENDL 0x0d, 0x0a

; This offset means that the kernel will be loaded at address 0x0050:0x0000
; or address 0x0500, which is start of 29.75 KiB conventional memory (according
; to https://wiki.osdev.org/Memory_Map_(x86))
KERN_SEGMENT equ 0x0050
KERN_OFFSET equ 0x0000

; Variables
F_KERN db "KERNEL  BIN"
ERR_FLOPPY db "[ERR] read fail", ENDL, 0
ERR_NO_KERN db "[ERR] kernel not found", ENDL, 0

DBG_BOOTING db "[INFO] booting...", ENDL, 0

; The current kernel cluster being pointed to
KERN_CLUSTER dw 0

; Pad the entire bootloader with zeroes because the bootloader must be exactly 
; 512 bytes in size
times 510-($-$$) db 0

; The magic signature which tells the computer that this file is bootable
dw 0xaa55

; Space after the bootsector can be used as a buffer to store stuff
DISK_BUFFER:
