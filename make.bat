F:/nasm/nasm -f bin mainDOS.s -o pong.com
F:/nasm/nasm -f bin pong.s -o floopy.bin
::copy /b boot.bin+main.bin floppy.img
dd if=/dev/zero of=floppy.img bs=512 count=2880
dd if=floopy.bin of=floppy.img bs=512 seek=0 conv=notrunc
E:/qemu/qemu-system-i386 -fda floppy.img
