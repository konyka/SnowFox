.PHONY: all

all:
	dd if=/dev/zero of=boot.img bs=512 count=2880
	sleep 2
	as boot.s -o boot.o
	ld boot.o -Ttext 0x7c00 --oformat=binary -Map boot.map -o boot.bin
	dd if=boot.bin of=boot.img bs=512 count=1 conv=notrunc
	as loader.s -o loader.o
	ld loader.o  -Ttext 0x1000 --oformat=binary -Map loader.map -o loader.bin

clean:
	rm -rf *.o *.map *.bin *.img

