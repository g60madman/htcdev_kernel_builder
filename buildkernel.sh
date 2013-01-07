###################################################
#buildkernel.sh -                                 #
#Shell script to build kernel for HTC Evo V &     #
#HTC Evo 3D into a flashable package              #
#                                                 #
#Written by shane87                               #
#Modified by b_randon14, mantera, & g60madman	  #
###################################################

###################################
#    VARIBLES YOU CAN MODIFY 	  #
###################################

#Working directory where this files and all tools are located
export WORKDIR=/media/android/htcdev_kernel_builder

#The kernel source directory
export KERNELDIR=/media/android/htcdev_kernel_builder/kernel

#The kernel config file
export CONFIG=/media/android/htcdev_kernel_builder/kernel/arch/arm/configs/shooter_defconfig

#used in the build version and zip file name
export KERNEL_NAME=HTCDEV-Kernel
export BUILDVER=CM10


#################################
# DO NOT CHANGE BELOW THIS LINE #
#################################

#This is the kernel version that will be appended to the default kernel version
export KBUILD_BUILD_VERSION="$KERNEL_NAME.$TESTNUM"
#This is the name that the CWM flashable zip will be named as, MUST END WITH .zip!!
KERNELZIP_VERSION=$KERNEL_NAME-$BUILDVER.zip

#Extract boot.img and move files
export ARCH=arm
export CROSS_COMPILE=arm-eabi-
export PATH=$(pwd)/prebuilt/arm-eabi-4.4.3/bin:$PATH

#Cleanup the directory and extract the kernel ramdisk
cd ramdisk
rm -rf boot.img-ramdisk
cd $WORKDIR
cd releasetools
rm *.img
rm *.zip
rm kernel
cd $WORKDIR
./tools/extract-ramdisk.pl boot.img
mv boot.img-ramdisk ramdisk
rm boot.img-ramdisk.cpio.gz

#Change to kernel directory
cd $KERNELDIR

#This part exports the variables needed by the build script in order to build the kernel correctly.
#Update the PATH variable to reflect where your toolchain is located.

export ARCH=arm
export CROSS_COMPILE=arm-eabi-
export PATH=$(pwd)/prebuilt/arm-eabi-4.4.3/bin:$PATH

#This cleans out the source tree to ensure a good clean build
make clean

#This section initiates the build process, and it is optimized to read the processor info of your system and build as many things 
#as it can at one time to speed the make process up
if [ ! -e $KERNELDIR/.config ]
then
	echo "Copying config to .config"
        cp $CONFIG $KERNELDIR/.config
fi

make -j`grep 'processor' /proc/cpuinfo | wc -l`

#This section cleans out the working directory of any residual files from previous builds.
#Then it takes the zImage (compressed kernel image) and combines it with the init ramdisk created and packages it as a boot.img
#and then zips it into the flashable Zip file.
cd $WORKDIR/releasetools
rm -f *.img

if [ -e $KERNELDIR/arch/arm/boot/zImage ]
then
	cp $KERNELDIR/arch/arm/boot/zImage zImage

	../tools/bootimg/mkbootfs ../ramdisk/boot.img-ramdisk | gzip > ramdisk.gz
#	cp ../ramdisk/ramdisk.img ramdisk.img
	../tools/bootimg/mkbootimg --kernel zImage --ramdisk ramdisk.gz --cmdline "console=ttyHSL0 androidboot.hardware=shooter no_console_suspend=1" -o boot.img --base 0x48000000
	rm -f zImage
	rm -f *.gz
	rm -f ramdisk.img
	rm -f *.zip
	zip -r $KERNELZIP_VERSION *
        cp $KERNELDIR/arch/arm/boot/zImage ../releasetools/kernel
	cd ..
	echo "Finished building kernel." 
	echo "Flash the Zip file $KERNELZIP_VERSION through CWM to test it."
else
	echo "Houston... We have a problem!  Check for errors!"
fi
unset ARCH
