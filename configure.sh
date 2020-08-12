#!/bin/sh

if [ "x$ROS_ARCH" = "x" ]; then
	echo Could not detect RosBE.
	exit 1
fi

# TODO: fix different arches, get actual version detection, document msvc option, line 11 uses a gnuism, cl.exe takes forever to start
echo -n Checking compiler suite...
if [ ! -z "$VCINSTALLDIR" ]; then
    if $VCINSTALLDIR/bin/x86/cl 2>&1 | grep -q "19\.[0-2][0-9]\.." ; then
	BUILD_ENVIRONMENT=VS
        PATH="$VCINSTALLDIR/bin/x86:${PATH}"
    else
	echo \$VCINSTALLDIR is set but an error occured, you may have either an outdated version or it doesnt exist.
	exit 1
    fi
else
    BUILD_ENVIRONMENT=MinGW
fi
echo $BUILD_ENVIRONMENT
ARCH=$ROS_ARCH
REACTOS_SOURCE_DIR=$(cd `dirname $0` && pwd)
REACTOS_OUTPUT_PATH=output-$BUILD_ENVIRONMENT-$ARCH

usage() {
	echo Invalid parameter given.
	exit 1
}

CMAKE_GENERATOR="Ninja"
while [ $# -gt 0 ]; do
	case $1 in
		-D)
			shift
			if echo "x$1" | grep 'x?*=*' > /dev/null; then
				ROS_CMAKEOPTS=$ROS_CMAKEOPTS" -D $1"
			else
				usage
			fi
		;;

		-D?*=*|-D?*)
			ROS_CMAKEOPTS=$ROS_CMAKEOPTS" $1"
		;;
		makefiles|Makefiles)
			CMAKE_GENERATOR="Unix Makefiles"
		;;
		*)
			usage
	esac

	shift
done

if [ "$REACTOS_SOURCE_DIR" = "$PWD" ]; then
	echo Creating directories in $REACTOS_OUTPUT_PATH
	mkdir -p "$REACTOS_OUTPUT_PATH"
	cd "$REACTOS_OUTPUT_PATH"
fi

echo Preparing reactos...
rm -f CMakeCache.txt host-tools/CMakeCache.txt
if [ "$BUILD_ENVIRONMENT" = "VS" ]; then
    ccmake -G "$CMAKE_GENERATOR" -DENABLE_CCACHE:BOOL=0 -DCMAKE_TOOLCHAIN_FILE:FILEPATH=toolchain-msvc.cmake -DARCH:STRING=$ARCH $EXTRA_ARGS $ROS_CMAKEOPTS "$REACTOS_SOURCE_DIR"
else
    ccmake -G "$CMAKE_GENERATOR" -DENABLE_CCACHE:BOOL=0 -DCMAKE_TOOLCHAIN_FILE:FILEPATH=toolchain-gcc.cmake -DARCH:STRING=$ARCH $EXTRA_ARGS $ROS_CMAKEOPTS "$REACTOS_SOURCE_DIR"
fi

echo Configure script complete! Enter directories and execute appropriate build commands \(ex: ninja, make, makex, etc...\).
