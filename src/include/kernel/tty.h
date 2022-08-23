#pragma once

#include <stddef.h>
#include <stdint.h>

// Define an enum that stores all the default VGA TTY colours
enum {
  VGA_COLOR_BLACK = 0,
  VGA_COLOR_BLUE = 1,
  VGA_COLOR_GREEN = 2,
  VGA_COLOR_CYAN = 3,
  VGA_COLOR_RED = 4,
  VGA_COLOR_MAGENTA = 5,
  VGA_COLOR_BROWN = 6,
  VGA_COLOR_LIGHT_GRAY = 7,
  VGA_COLOR_DARK_GRAY = 8,
  VGA_COLOR_LIGHT_BLUE = 9,
  VGA_COLOR_LIGHT_GREEN = 10,
  VGA_COLOR_LIGHT_CYAN = 11,
  VGA_COLOR_LIGHT_RED = 12,
  VGA_COLOR_PINK = 13,
  VGA_COLOR_YELLOW = 14,
  VGA_COLOR_WHITE = 15
};

// // Prints the literal 'Hi' on the top left of the screen
// Runs the test code as specified by the code
void test_print();

// // Clear the screen by replacing all the characters by spaces and reset the internal cursor position
// void clear_screen();

// // Print one character onto the screen and increment the internal cursor position
// void print_char(char character);

// // Print a string onto the screen and increment the internal cursor position respectively
// void print_string(char* str);

// // Set the foreground and the background colour of the text
// void print_set_color(uint8_t foreground, uint8_t background);

// // Set the cursor position upon being given an x and a y value
// void set_cursor_position(uint8_t x, uint8_t y);