all: before
	cd asm && make all
	cd bin && cat *.bin | sponge > sokoboot.bin
	cd bin && cp sokoboot.bin ..
	dd status=noxfer conv=notrunc if=bin/sokoboot.bin of=sokoboot.img

clean:
	cd asm && make clean
	-rm sokoboot.img

before:
	cd asm && make before
	

rebuild: clean all

run:
	qemu-system-i386 sokoboot.img
