splash: before
	cd splash && python img2bin.py > splash.bin
	dd if=/dev/zero of=splash/splash.bin bs=1 count=0 seek=73728

all: before splash
	cd asm && make all
	cp splash/splash.bin bin/002-splash.bin
	cd bin && cat *.bin | sponge > sokoboot.bin
	cd bin && cp sokoboot.bin ..
	dd status=noxfer conv=notrunc if=bin/sokoboot.bin of=sokoboot.img

clean:
	cd asm && make clean
	-rm sokoboot.img
	-rm -rf split

before:
	cd asm && make before

rebuild: clean all

run:
	qemu-system-i386 -boot a -fda sokoboot.img

split: sokoboot.img
	bash split.sh
