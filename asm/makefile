all:
	nasm bootsec.asm -f bin -o ../bin/000-bootsec.bin
	nasm init.asm -f bin -o ../bin/001-init.bin
	cp splash/splash.bin ../bin/002-splash.bin
	dd if=/dev/zero of=../bin/002-splash.bin bs=1 count=1 seek=73727
	nasm sokoban/sokoban.asm -f bin -o ../bin/003-sokoban.bin

clean:
	-rm -rf ../bin

before:
	-mkdir ../bin
