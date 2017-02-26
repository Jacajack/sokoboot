all:
	nasm bootsec.asm -f bin -o ../bin/000-bootsec.bin
	nasm init.asm -f bin -o ../bin/001-init.bin
	nasm sokoban/sokoban.asm -f bin -o ../bin/003-sokoban.bin

clean:
	-rm -rf ../bin

before:
	-mkdir ../bin
