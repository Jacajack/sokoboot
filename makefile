all:
	nasm bootsec.asm -f bin -o bootsec.bin
	nasm boot.asm -f bin -o boot.bin
	nasm game.asm -f bin -o game.bin
	cat bootsec.bin boot.bin game.bin > os.bin
	cp os.bin disk.bin
	dd if=/dev/zero of=disk.bin bs=1 count=0 seek=1474560

run:
	qemu-system-i386 disk.bin
