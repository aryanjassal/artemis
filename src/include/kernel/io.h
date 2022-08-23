#pragma once
#include <stdint.h>

// The assembly function outb
void outb(uint16_t port, uint8_t val);

// The assembly function inb
uint8_t inb(uint16_t port);
