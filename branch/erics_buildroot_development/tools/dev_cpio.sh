mkdir -p /tmp/gmi-core-devices
cd /tmp/gmi-core-devices
tar cvf dev.tar /dev/ttyS0 /dev/ttyS1 /dev/ttyS2 /dev/ttyS3 /dev/null /dev/console /dev/tty1 /dev/tty2 /dev/tty3 /dev/tty4 /dev/tty4 /dev/tty5 /dev/tty6 /dev/tty7 /dev/tty8 /dev/tty9
tar xvf dev.tar
find dev | cpio --create --format=newc --quiet > gmi-core-devices.cpio 
gzip gmi-core-devices.cpio
mv  gmi-core-devices.cpio ~
cd ~
rm -r /tmp/gmi-core-devices
