# Welcome to DOS2B

DOS2B is an operating system that I am currently working on. DOS2B stands for "DOS but better". It is meant to replicate the function of the legacy MS-DOS operating systems. This will not be an accurate recreation as I will be adding some touches here and there myself. This project is meant as a hobby project that I'm doing for fun. I'm also learning the ins-and-outs of a computer this way.

## How do I run this?

To run the operating system, you need to first clone this repository. Then, run the following command in the same directory where the `Makefile` is located. Please note that you need to have the `qemu` and `nasm` packages installed in order to run this operating system.
  
```bash
make
```

And that's it! This should compile the operating system and open up a QEMU window with the operating system.

## README

I am yet to expose functions to programmers and implement an actual filesystem. 

As this is my first time experimenting with them, I might just try FAT filesystem in a 32-bit operating system (*\*cough\** [Project April](https://github.com/aryanjassal/project-april) *\*cough\**) first before implementing it here. I also need to allow system programmers to create binaries or applications to work with my operating system. This is the hardest stage (in my opinion) because I need to expose APIs for programmers *and* implement a filesystem to allow the files to be actually stored.
