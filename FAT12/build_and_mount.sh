echo "Building bootloader.asm..."
nasm -o bootloader.bin -O 9 bootloader.asm
echo "Building FAT 12 filesystem..."
nasm -o myfat.bin -O 9 FAT12.asm
sudo losetup --offset 0 --sizelimit 262144 /dev/loop1 myfat.bin
#mkdosfs -F 12 /dev/loop1
#mkdosfs -F 12 myim.bin
sudo mount -t vfat -o rw,uid=1002,gid=1002 /dev/loop1 files
