#include "io.h"

#include <stdint.h>

// Output a byte to the given port using inline assembly
void outb(uint16_t port, uint8_t val) {
    asm volatile ("outb %0, %1" : : "a"(val), "Nd"(port));
}

// Read a byte from the given port using inline assembly
uint8_t inb(unsigned short port) {
    uint8_t return_val;
    asm volatile ("inb %1, %0" 
    : "=a"(return_val) 
    : "Nd"(port));
    return return_val;
}