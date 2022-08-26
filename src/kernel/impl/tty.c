#include "tty.h"
#include <stdint.h>

// Create a struct to store the character information as per VGA console requirements
typedef struct {
  uint8_t character;
  uint8_t colour;
} Char;

// Create a struct to store important information regarding the tty information
typedef struct {
  uint16_t row;
  uint16_t col;
  uint16_t max_rows;
  uint16_t max_cols;
  uint8_t colour;
} Screen;

// Use the character struct to parse the VGA memory to a variable
static Char *vgamem = (Char *) 0xb8000;

// Create a new screen, which stores information about the current tty
Screen tty = (Screen) {
  row: 0,
  col: 0,
  max_rows: 25,
  max_cols: 80,
  colour: VGA_COLOR_WHITE | VGA_COLOR_BLUE << 4
};

// Clear a row as per the provided argument
void tty_clear_row(uint8_t row) {
  // Create the space character using the struct
  Char space;
  space.character = ' ';
  space.colour = tty.colour;

  // For each column in the row, replace it with a space character
  for (size_t col = 0; col < tty.max_cols; col++) {
    vgamem[col + (tty.max_cols * row)] = space;
  }
}

// Clears the screen by filling the VGA buffer up with empty spaces
void tty_clear() {
  // For each row in the terminal, clear the row
  for (size_t row = 0; row < tty.max_rows; row++) {
    tty_clear_row(row);
  }
}

// Print a newline in the terminal. If it is the last line, scroll down.
void tty_print_newline() {
  // Set the column to zero
  tty.col = 0;

  // If the current row is less than the maximum number of rows in the tty, then just clear the row
  // and increment the tty row counter
  if (tty.row < tty.max_rows - 1) {
    tty.row++;
    tty_clear_row(tty.row);
    return;
  }
  
  // Otherwise, shift all lines up by one to clear up the last row
  for (size_t row = 0; row < tty.max_rows; row++) {
    for (size_t col = 0; col < tty.max_cols; col++) {
      Char ch = vgamem[col + (tty.max_cols * row)];
      vgamem[col + (tty.max_cols * (row - 1))] = ch;
    }
  }

  // Then clear the last row
  tty_clear_row(tty.row);
}

// Print a singular character onto the screen
void tty_print_char(char ch) {
  // If the character is newline, the print a newline and return
  if (ch == '\n') {
    tty_print_newline();
    return;
  }
  
  // Otherwise, if the current number of column is greater than the maximum number of columns,
  // then print the char in the nex line
  if (tty.col > tty.max_cols) {
    tty_print_newline();
  }

  // Create the character from the Char struct
  Char character;
  character.character = ch;
  character.colour = tty.colour;

  // Put the character in the memory address pointed to by the internal row and column counter
  vgamem[tty.col + (tty.max_cols * tty.row)] = character;
  tty.col++;
}

// Print a string to the tty output
void tty_print_string(char* str) {
  for (size_t i = 0; ; i++) {
    char ch = str[i];

    // If the next character in the string is a null character (\0), then return 
    if (ch == '\0') {
      return;
    }

    // Print the character onto the screen
    tty_print_char(ch);
  }
}

// Set the foreground and background colour of the tty
void tty_set_colour(uint8_t foreground, uint8_t background) {
  tty.colour = foreground | background << 4;
}