qemu-system-aarch64 -machine virt -cpu cortex-a57 -kernel trusty-server-cloudimg-arm64-vmlinuz-generic -append 'root=/dev/vda1 console=ttyAMA0' -serial stdio -drive if=none,file=trusty-server-cloudimg-arm64-disk1.img,id=hd0 -device virtio-blk-device,drive=hd0 -S
