lvdisplay
pvdisplay

fdisk /dev/sda
l (partition)
d (partition)
n (partition)
t (partition)
w

partprobe
lsblk
pvresize /dev/sda2
lvextend -l +100%FREE /dev/ol/root
xfs_growfs /dev/mapper/ol-root
df -h
