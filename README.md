# Artemis

Do we *really* need more than 16 bits?

## Overview

Artemis is an operating system inspired by the popular MS-DOS, completely written in 8086 assembly from scratch. The aim of Artemis is primarily for learning system programming. I have tried to ensure everything is well-documented, so the codebase is easy to follow and maintain. I will keep working on Artemis to see how far can I stretch functionality within the limited performance and hardware capabilities of 8086 processors. Of course, Artemis isn't meant to be run only on emulators. I am trying to make Artemis compatible with live hardware too. As I am using 8086 assembly, Artemis should work perfectly on actual 8086 hardware too. 

Best code is written under the harshest development environments. Wanna code better? Lets bring the harsh environment back.

## Usage

### Building And Running

To run Artemis, ensure `qemu`, `nasm`, and `gcc` are installed. And, yes, I prefer Intel syntax over AT&T. Get over it. To run Artemis, type the following in the terminal to compile and run the operating system on QEMU. 

```bash
$ make
```

The default target compiles all the files, included tools, and then creates a `.img` file with the whole filesystem written to it. Then, `QEMU` is used to emulate the operating system (more specifically `qemu-system-i386` although it is written with support for 8086 in mind). If you want to use another emulator, use the flag `EMU` and `EMUFLAGS`. `EMU`, self evidently, is the emulator command. `EMUFLAGS` are the parameters to be passed to the command. It includes passing the location of the final binary, located in `build/floppy.img`. Remember to compile the project first or the file won't exist.

```bash
$ make EMU=bochs EMUFLAGS="-q"
```

Its useful in a development environment to have outputs of each command clearly visible. Personally, I prefer to keep it disabled until I *need* to view the output of each command. To print out each and every command being processed, pass in empty `Q` and `NO_OUT` flags. `Q` the lines themselves aren't printed to the console. `NO_OUT` hides any output that is printed from commands. For example, `$(Q)echo "Hello, world!" $(NO_OUT)` will not output anything, as by default `$(Q)` and `$(NO_OUT)` suppress any output.

```bash
$ make Q= NO_OUT=
```

### Debugging

While we are on the topic of development, every development environment needs a good debugger. Thus, you can use the debug target to launch `bochs` within debug mode. Through the debugger, the instructions can be paused or stepped through, while you have full access to every single register and flag on the emulator. You can also look through memory at an ygiven address, or look at the stack. Amazing tool to debug what's happening.

```bash
$ make debug
```

Another quirk of Makefiles is includes. If an included file is updated, then the whole project should ideally be recompiled. Of course, in larger projects, this will be a waste of time, but large project this is not. So, that bridge will be crossed when it comes to it. For now, the first step of debugging is recompiling using the following command.

```bash
$ make clean
```
## Tools

You might have noticed that there is a `tools` directory. It houses code for testing complex algorithms in a simpler development environment like C. I know C isn't really known for being simple, but when you've been coding in assembly for weeks on end, even C feels like Python.

### FAT12 Driver

The `tools/fat` directory contains FAT12 drivers in C, so the driver can be debugged in a more readable syntax. It also supports FAT16 as it only requires changing two lines. The lines to change are well documented within the file itself. However, keep in mind that FAT16 isn't fully supported yet (as Artemis uses FAT12).

## Notes

By default, if you're using QEMU, it also creates a file `qemu.log` with the assembly the virtual machine is running. It is extremely useful tool for debugging. Well, sometimes.
