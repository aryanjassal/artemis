#include "tty.h"

typedef struct {
  uint8_t character;
  uint8_t colour;
} Char;

static Char *vidmem = (Char *) 0xb8000;

void test_print() {
  Char space = (Char) {
    character: ' ',
    colour: VGA_COLOR_WHITE | VGA_COLOR_BLUE << 4
  };

  for (size_t col = 0; col < 80; col++) {
    vidmem[col + 80] = space;
  }    
}
