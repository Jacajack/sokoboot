all:
	nasm bootsec.asm -f bin -o ../bin/000-bootsec.bin
	nasm boot.asm -f bin -o ../bin/001-boot.bin
	nasm game.asm -f bin -o ../bin/002-game.bin

clean:
	-rm -rf ../bin

before:
	-mkdir ../bin
