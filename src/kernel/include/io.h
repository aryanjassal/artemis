#pragma once

#include <stdint.h>

// Output a byte to a port number
void outb(uint16_t port, uint8_t val);

// Read a byte from a port number
uint8_t inb(uint16_t port);