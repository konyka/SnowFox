.PHONY: all

all:
	as boot.s -o boot.o
	ld boot.o -Ttext 0x7c00 --oformat=binary -Map boot.map -o boot.bin
	dd if=boot.bin of=boot.img bs=512 count=1 conv=notrunc

clean:
	rm -rf *.o *.img *.map *.bin

