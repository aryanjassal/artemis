#include <ctype.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;
typedef int8_t i8;
typedef int16_t i16;
typedef int32_t i32;
typedef int64_t i64;
typedef u8 bool;
#define true 1
#define false 0

typedef struct {
  u8 BOOT_JUMP_INSTRUCTION[3];  
  u8 OEM_IDENTIFIER[8];
  u16 BYTES_PER_SECTOR;
  u8 SECTORS_PER_CLUSTER;
  u16 RESERVED_SECTORS;
  u8 NUMBER_OF_FAT;
  u16 DIRECTORY_ENTRY_COUNT;
  u16 TOTAL_SECTORS;
  u8 MEDIA_DESCRIPTOR_TYPE;
  u16 SECTORS_PER_FAT;
  u16 SECTORS_PER_TRACK;
  u16 NUMBER_OF_HEADS;
  u32 NUMBER_OF_HIDDEN_SECTORS;
  u32 LARGE_SECTOR_COUNT;

  u8 BOOT_DRIVE_NUMBER;
  u8 _RESERVED;
  u8 SIGNATURE;
  u32 VOLUME_ID;
  u8 VOLUME_LABEL[11];
  u8 SYSTEM_ID[8];
} __attribute__((packed)) bootsector;

typedef struct {
  u8 FILE_NAME[11];
  u8 ATTRIBUTES;
  u8 _RESERVED;
  u8 CREATION_SECONDS;
  u16 CREATION_TIME;
  u16 CREATION_DATE;
  u16 LAST_ACCESSED_DATE;
  u16 ZERO;
  u16 MODIFICATION_TIME;
  u16 MODIFICATION_DATE;
  u16 FIRST_CLUSTER;
  u32 SIZE;
} __attribute__((packed)) dir_entry;

bootsector g_bootsector;

u8 *g_fat = NULL;
dir_entry *g_rootdirectory = NULL;
u32 g_rootdirectory_end;

// Dynamically populates the bootsector
bool read_bootsector(FILE* disk) {
  return fread(&g_bootsector, sizeof(g_bootsector), 1, disk) != sizeof(g_bootsector);
}

// Note that LBA addressing scheme is used here whereas the actual code is using CHS.
// This is to simplify reading and loading sectors.
bool read_sectors(FILE *disk, u32 lba, u32 count, void* buf) {
  bool ok = true;
  ok = ok && (fseek(disk, lba * g_bootsector.BYTES_PER_SECTOR, SEEK_SET) == 0);
  ok = ok && (fread(buf, g_bootsector.BYTES_PER_SECTOR, count, disk) == count);
  return ok;
}

bool read_fat(FILE *disk) {
  g_fat = (u8*) malloc(g_bootsector.SECTORS_PER_FAT * g_bootsector.BYTES_PER_SECTOR);
  return read_sectors(disk, g_bootsector.RESERVED_SECTORS, g_bootsector.SECTORS_PER_FAT, g_fat);
}

bool read_rootdirectory(FILE *disk) {
  u32 lba = g_bootsector.RESERVED_SECTORS + g_bootsector.SECTORS_PER_FAT * g_bootsector.NUMBER_OF_FAT;
  u32 size = sizeof(dir_entry) * g_bootsector.DIRECTORY_ENTRY_COUNT;
  u32 sectors = (size / g_bootsector.BYTES_PER_SECTOR);
  g_rootdirectory_end = lba + sectors;
  if (size % g_bootsector.BYTES_PER_SECTOR > 0) sectors++;

  g_rootdirectory = (dir_entry*) malloc(sectors * g_bootsector.BYTES_PER_SECTOR);
  return read_sectors(disk, lba, sectors, g_rootdirectory);
}

dir_entry* find_file(const char *name) {
  for (u32 i = 0; i < g_bootsector.DIRECTORY_ENTRY_COUNT; i++) {
    if (memcmp(name, g_rootdirectory[i].FILE_NAME, 11) == 0) {
      return &g_rootdirectory[i];
    }
  }
  return NULL;
}

bool read_file(dir_entry *file, FILE* disk, u8 *buf) {
  bool ok = true;
  u16 cluster = file->FIRST_CLUSTER;

  do {
    u32 lba = g_rootdirectory_end + (cluster - 2) * g_bootsector.SECTORS_PER_CLUSTER;
    ok = ok && read_sectors(disk, lba, g_bootsector.SECTORS_PER_CLUSTER, buf);
    buf += g_bootsector.SECTORS_PER_CLUSTER * g_bootsector.BYTES_PER_SECTOR;

    u32 fat_offset = cluster + (cluster / 2);
    cluster = (cluster & 1) ? (*(u16*)(g_fat + fat_offset)) >> 4 : (*(u16*)(g_fat + fat_offset)) & 0xfff;
  } while(ok && cluster < 0x0ff8);
  return ok;
}

int main(int argc, char **argv) {
  i8 retval;

  if (argc != 3) {
    printf("invalid arguments\nusage is: '%s <disk> <filename>'\n", argv[0]);
    return -1;
  }

  if (strlen(argv[2]) != 11) {
    printf("invalid arguments\nfilename size must be exactly 11 characters\n");
    return -1;
  }

  FILE* disk = fopen(argv[1], "rb");
  if (!disk) {
    fprintf(stderr, "failed to open disk image '%s'\n", argv[1]);
    return -1;
  }

  if (!read_bootsector(disk)) {
    fprintf(stderr, "failed to load bootsector\n");
    return -2;
  }

  if (!read_fat(disk)) {
    fprintf(stderr, "failed to load fat\n");
    retval = -3;
    goto free_fat;
  }

  if (!read_rootdirectory(disk)) {
    fprintf(stderr, "failed to read filesystem\n");
    retval = -4;
    goto free_rootdir;
  }

  dir_entry *file = find_file(argv[2]);
  if (!file) {
    fprintf(stderr, "failed to locate file '%s'\n", argv[2]);
    retval = -5;
    goto free_rootdir;
  }

  printf("found file '%s'\n", argv[2]);

  u8 *file_contents = (u8*) malloc(file->SIZE + g_bootsector.BYTES_PER_SECTOR);
  if (!read_file(file, disk, file_contents)) {
    fprintf(stderr, "failed to read file contents\n");
    retval = -5;
    goto free_file;
  }

  // Print any printable characters, otherwise print their hex codes
  printf("\n");
  for (size_t i = 0; i < file->SIZE; i++) {
    if (isprint(file_contents[i])) fputc(file_contents[i], stdout);
    else printf("<%02x>", file_contents[i]);
  }
  printf("\n");
  
  free_file:    free(file_contents);
  free_rootdir: free(g_rootdirectory);
  free_fat:     free(g_fat);
  return retval;
}
