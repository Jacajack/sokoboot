all: clean force resources bin/sokoboot.bin
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

resources/splash.bin: resources/splash.png resources/splash.pal.bin
	./img2palbin.py resources/splash.png resources/splash.pal.bin > resources/splash.bin
	dd if=/dev/zero of=resources/splash.bin bs=1 count=0 seek=73728

resources/splash.pal.bin: resources/splash.png
	./img2pal.py resources/splash.png > resources/splash.pal.bin

resources/sprites.bin: resources/sprites.png resources/sprites.pal.bin
	./img2palbin.py resources/sprites.png resources/sprites.pal.bin > resources/sprites.bin
	
resources/sprites.pal.bin: resources/sprites.png
	./img2pal.py resources/sprites.png > resources/sprites.pal.bin

resources/levels.bin: mklvl/mklvl
	./build-levels.sh

resources/font.bin:
	./font2bin.py resources/font.png > resources/font.bin

resources: resources/levels.bin resources/sprites.bin resources/splash.bin resources/font.bin

mklvl/mklvl:
	make -C mklvl 	

clean:
	-rm -r bin
	-rm -r split
	-rm sokoboot.img
	-rm sokoboot.bin
	make -C mklvl clean

force:
	-mkdir bin

rebuild: clean all

run:
	qemu-system-i386 -cpu pentium -vga cirrus -boot a -fda sokoboot.img

split: sokoboot.img
	bash split.sh
