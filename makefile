all: clean force bin/sokoboot.bin
	cd bin && cp sokoboot.bin ..
	dd status=noxfer conv=notrunc if=bin/sokoboot.bin of=sokoboot.img

bin/sokoboot.bin: bin/000-bootsec.bin bin/001-init.bin bin/002-sokoban.bin resources/levels.bin
	cat $^ > bin/sokoboot.bin

bin/000-bootsec.bin:
	cd asm && nasm bootsec.asm -f bin -o ../bin/000-bootsec.bin

bin/001-init.bin: resources/splash.bin
	cd asm && nasm init.asm -f bin -o ../bin/001-init.bin

bin/002-sokoban.bin: resources/sprites.bin
	cd asm && nasm sokoban.asm -f bin -o ../bin/002-sokoban.bin

resources/splash.bin:
	./img2bin.py resources/splash.png > resources/splash.bin
	dd if=/dev/zero of=resources/splash.bin bs=1 count=0 seek=73728

resources/sprites.bin:
	./img2bin.py resources/sprites.png > resources/sprites.bin

resources/levels.bin: mklvl/mklvl
	./build-levels.sh

resources: resources/levels.bin resources/sprites.bin resources/splash.bin

lmklvl/mklvl:
	cd lmklvl && make all

clean:
	-rm -r bin
	-rm -r split
	-rm sokoboot.img
	-rm sokoboot.bin

force:
	-mkdir bin

rebuild: clean all

run:
	qemu-system-i386 -vga cirrus -boot a -fda sokoboot.img

split: sokoboot.img
	bash split.sh
