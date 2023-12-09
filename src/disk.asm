BITS 16

; Reads disk starting with the given LBA to specified number of sectors.
; @param  `ax`    Logical block address (LBA) of sector
; @param  `cl`    Number of sectors to read
; @return `es:di` The address of buffer to put in data to
; TODO: actually implement this
disk_read:
  ret
