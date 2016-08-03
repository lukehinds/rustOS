default: build

build: target/kernel.bin

.PHONY: clean

target/multiboot_header.o: src/asm/multiboot_header.asm
		mkdir -p target
		nasm -f elf64 src/asm/multiboot_header.asm -o target/multiboot_header.o

target/boot.o: src/asm/boot.asm
		mkdir -p target
		nasm -f elf64 src/asm/boot.asm -o target/boot.o

target/kernel.bin: target/multiboot_header.o target/boot.o src/asm/linker.ld cargo
		ld -n -o target/kernel.bin -T src/asm/linker.ld target/multiboot_header.o target/boot.o target/x86_64-unknown-rust_os-gnu/release/librust_os.a

target/os.iso: target/kernel.bin src/asm/grub.cfg
		mkdir -p target/isofiles/boot/grub
		cp src/asm/grub.cfg target/isofiles/boot/grub
		cp target/kernel.bin target/isofiles/boot/
		grub2-mkrescue -o target/os.iso target/isofiles

target/libcore:
		git clone http://github.com/intermezzos/libcore target/libcore
		cd target/libcore && git reset --hard 02e41cd5b925a1c878961042ecfb00470c68296b

target/libcore/target/x86_64-unknown-rust_os-gnu/libcore.rlib: target/libcore
		cp x86_64-unknown-rust_os-gnu.json target/libcore
		cd target/libcore && cargo build --release --features disable_float --target=x86_64-unknown-rust_os-gnu.json

cargo: target/libcore/target/x86_64-unknown-rust_os-gnu/libcore.rlib
		RUSTFLAGS="-L target/libcore/target/x86_64-unknown-rust_os-gnu/release" cargo build --release --target x86_64-unknown-rust_os-gnu.json


run: target/os.iso
		qemu-system-x86_64 -cdrom target/os.iso

clean:
		cargo clean
