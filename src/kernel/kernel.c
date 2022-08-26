#include "tty.h"

void kernel_main() {
  tty_set_colour(15, 1);
  tty_clear();
  tty_print_string("Hello, world!\n");
  tty_print_string("Welcome to my C kernel!\n");
  tty_print_string("Welcome to Project April rev.20220826-prealpha\n");

  while(1) {}
}
