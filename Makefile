.DEFAULT_GOAL := default

OSDEV_CFLAGS = -Wall \
    -Wextra \
    -std=gnu11 \
    -ffreestanding \
    -fno-stack-protector \
    -fno-stack-check \
    -fno-lto \
    -fPIE \
    -m64 \
    -march=x86-64 \
    -mno-80387 \
    -mno-mmx \
    -mno-sse \
    -mno-sse2 \
    -mno-red-zone
compile:
	tar -C ramdisk  --transform='s,^\./,,' --format=ustar -cvf ramdisk.tar .
	tar -vf ramdisk.tar --delete .
	objcopy -O elf64-x86-64 -B i386:x86-64 -I binary ramdisk.tar ramdisk.o
	objcopy -O elf64-x86-64 -B i386:x86-64 -I binary ramdisk/font.psf ramdisk/font.o

	#x86_64-elf-gcc -I. -c kernel/kernel.c -o kernel/kernel.o $(OSDEV_CFLAGS)
	#x86_64-elf-as boot/asm/boot.s -o boot/asm/boot.o


	nasm -f elf64 boot/asm/boot.s -o boot/asm/boot.o


	x86_64-elf-gcc -g -I. -c kernel/kernel.c -o kernel/kernel.o $(OSDEV_CFLAGS)
	x86_64-elf-gcc -g -I. -c kernel/mainframe/mainframe.c -o kernel/mainframe/mainframe.o $(OSDEV_CFLAGS)
	x86_64-elf-gcc -g -I. -c kernel/std/time.c -o kernel/std/time.o $(OSDEV_CFLAGS)
	x86_64-elf-gcc -g -I. -c kernel/std/string.c -o kernel/std/string.o $(OSDEV_CFLAGS)
	x86_64-elf-gcc -g -I. -c kernel/memory/kmalloc.c -o kernel/memory/kmalloc.o $(OSDEV_CFLAGS)
	x86_64-elf-gcc -g -I. -c kernel/drivers/io/io.c -o kernel/drivers/io/io.o $(OSDEV_CFLAGS)
	x86_64-elf-gcc -g -I. -c kernel/drivers/video/video.c -o kernel/drivers/video/video.o $(OSDEV_CFLAGS)
	x86_64-elf-gcc -g -I. -c kernel/drivers/keyboard/keyboard.c -o kernel/drivers/keyboard/keyboard.o $(OSDEV_CFLAGS)
	x86_64-elf-gcc -g -I. -c kernel/std/math.c -o kernel/std/math.o $(OSDEV_CFLAGS)
	x86_64-elf-gcc -g -I. -c boot/multiboot_islaos.c -o boot/multiboot_islaos.o $(OSDEV_CFLAGS)
	x86_64-elf-gcc -g -I. -c kernel/fonts/font_lib.c -o kernel/fonts/font_lib.o $(OSDEV_CFLAGS)
	x86_64-elf-gcc -g -I. -c kernel/mainframe/images/tga.c -o kernel/mainframe/images/tga.o $(OSDEV_CFLAGS)
	x86_64-elf-gcc -g -I. -c kernel/mainframe/games/tetris.c -o kernel/mainframe/games/tetris.o $(OSDEV_CFLAGS)
	x86_64-elf-gcc -g -I. -c kernel/ramdisk/ramdisk.c -o kernel/ramdisk/ramdisk.o $(OSDEV_CFLAGS)
	x86_64-elf-gcc -g -I. -c kernel/pit/pit.c -o kernel/pit/pit.o $(OSDEV_CFLAGS)
	x86_64-elf-gcc -g -I. -c kernel/serial/serial.c -o kernel/serial/serial.o $(OSDEV_CFLAGS)


	x86_64-elf-gcc -T linker.ld -o dist/IslaOS.bin -ffreestanding -O2 -nostdlib -lgcc \
	 boot/asm/boot.o boot/multiboot_islaos.o kernel/kernel.o kernel/fonts/font_lib.o kernel/memory/kmalloc.o \
	 kernel/drivers/io/io.o kernel/drivers/keyboard/keyboard.o kernel/std/math.o \
	 kernel/std/time.o kernel/mainframe/mainframe.o kernel/drivers/video/video.o kernel/std/string.o \
	 kernel/mainframe/images/tga.o kernel/ramdisk/ramdisk.o ramdisk.o \
	 kernel/mainframe/games/tetris.o kernel/pit/pit.o ramdisk/font.o kernel/serial/serial.o


	#x86_64-elf-gcc -T linker.ld -o dist/IslaOS.bin -ffreestanding -O2 -nostdlib -lgcc kernel/kernel.o

build_iso:
	cp -v dist/IslaOS.bin iso_root/boot/
	mkdir -p iso_root/boot/limine
	cp -v limine.cfg limine/limine-bios.sys limine/limine-bios-cd.bin \
		limine/limine-uefi-cd.bin iso_root/boot/limine/

	# Create the EFI boot tree and copy Limine's EFI executables over.
	mkdir -p iso_root/EFI/BOOT
	cp -v limine/BOOTX64.EFI iso_root/EFI/BOOT/
	cp -v limine/BOOTIA32.EFI iso_root/EFI/BOOT/
	
	# Create the bootable ISO.
	xorriso -as mkisofs -b boot/limine/limine-bios-cd.bin \
			-no-emul-boot -boot-load-size 4 -boot-info-table \
			--efi-boot boot/limine/limine-uefi-cd.bin \
			-efi-boot-part --efi-boot-image --protective-msdos-label \
			iso_root -o iso/IslaOS.iso
	
	# Install Limine stage 1 and 2 for legacy BIOS boot.
	./limine/limine bios-install iso/IslaOS.iso


clean:
	find . -name "*.o" -type f -delete
	find . -name "*.iso" -type f -delete
	find . -name "*.tar" -type f -delete

default:
	make compile
	make build_iso
	make boot
	qemu-system-x86_64 -serial file:serial.log -cdrom iso/IslaOS.iso -machine q35 -m 8192M \
	# -d int -no-shutdown -no-reboot #-bios /usr/share/edk2/x64/OVMF.fd