#include "tty.h"
#include "io.h"

// Declare the size of the terminal screen
const static size_t NUM_COLS = 80;
const static size_t NUM_ROWS = 25;

// Declare a struct to store character information being printed on the screen
struct Char {
  uint8_t character;
  uint16_t colour;
};

// Declare a struct to store the screen-related information
struct Screen {
  uint8_t cursor_pos_x;
  uint8_t cursor_pos_y;
  uint16_t colour;
};

//! I don't know how this code works
// Get the screen buffer
struct Char* buffer = (struct Char*) 0xb8000;

// Create a new screen object with its origin being top left of the screen and the text colour being white on black
struct Screen screen = (struct Screen) {
  cursor_pos_x: 0,
  cursor_pos_y: 0,
  colour: VGA_COLOR_WHITE | VGA_COLOR_BLACK << 4
};

// Clear a row on the screen
void clear_row(size_t row) {
  struct Char space = (struct Char) {
    character: ' ',
    colour: screen.colour
  };

  for (size_t col = 0; col < NUM_COLS; col++) {
    buffer[col + (NUM_COLS * row)] = space;
  }
}

// Clear the entire screen
void print_clear() {
  for (size_t row = 0; row < NUM_ROWS; row++) {
    clear_row(row);
  }
}