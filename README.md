# DOS2B

When did we ever really need more than 16 bits?

## Overview

DOS2B is an operating system inspired by the popular MS-DOS. DOS2B is completely written in 8086 assembly from scratch. What would happen if MS-DOS was programmed with modern programming practices? How much better could we make it now? Well, you don't have to wonder, because DOS2B aims to do precisely that. Moreover, eventually, you will be able to run native DOS applications on this too. How exciting is that? Basically like any DOS emulator, but acutally DOS. As a matter of fact, DOS2B should work on live 8086 hardware too, so feel free to try!

## Running it

To run DOS2B, ensure `qemu`, `nasm`, and `gcc` are installed. And, yes, I prefer Intel syntax over AT&T. To run DOS2B, type the following in the terminal to compile and run the operating system on QEMU. The default target compiles all the files, included tools, and then creates a `.img` file with the whole filesystem written to it.

```bash
$ make
```
## Usage

So far, the only things present in DOS2B is code testing out the new code. So, if you were expecting some fancy functionality right off the start, sorry to disappoint. Well, at least you can revel in the knowledge that great things are planned for DOS2B, and you will likely get to be a part of it!

## Notes

As DOS2B is inspired by MS-DOS, it also uses DOS's interrupt 0x21 exactly the same way as MS-DOS uses. Thus, you will be able to run basically any DOS-era application using DOS2B.
