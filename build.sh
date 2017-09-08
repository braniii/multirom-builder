#!/bin/bash

TARGETS="
	lineage-14.1_bacon-user
	lineage-14.1_cheeseburger-user
	lineage-14.1_gemini-user
	lineage-14.1_hammerhead-user
	lineage-14.1_kenzo-user
	lineage-14.1_klte-user
	lineage-14.1_lux-user
	lineage-14.1_oneplus3-user
	lineage-14.1_osprey-user
	lineage-14.1_titan-user
	"
OUTPUT_ROOT="/data/archive"
BUILD_ROOT="/data/build"
CCACHE_DIR="$BUILD_ROOT/ccache"

SCRIPT=$( readlink -m $( type -p $0 ))
SCRIPT_PATH="$(dirname "$SCRIPT")"

USE_CCACHE=1
CCACHE_SIZE="120G"


export CM_BUILDTYPE=NIGHTLY

function setup_repo {
    ROM=$1
    ROMDIR=$2
    source "$SCRIPT_PATH/targets/$ROM/vars.sh"
    mkdir -p $ROMDIR
    cd $ROMDIR
    repo init -u $MANIFEST -b $BRANCH
    mkdir -p .repo/local_manifests
    for manifest in $SCRIPT_PATH/targets/general/local_manifests/*.xml
    do
        ln -s $manifest .repo/local_manifests/
    done
}

function apply_patches {
    PATCHDIR=$1
    echo $PATCHDIR
    if [ -d "$PATCHDIR" ]
    then
        for patch in $PATCHDIR/*.patch
	do
            patch --no-backup-if-mismatch -p1 -i $patch
	done
        for script in $PATCHDIR/*.sh
	do
            bash $script
	done
    fi
}


# Setup ccache
if [ $USE_CCACHE == 1 ]
then
    export USE_CCACHE
    export CCACHE_DIR
    ccache -M $CCACHE_SIZE
fi

# Fix new JACK compilers memory issue
export ANDROID_JACK_VM_ARGS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx4G"


# Grab distinct list of roms from targets
roms=""
for target in $TARGETS
do
    rom=$(awk -F '_' '{print $1;}' <<< $target)
    if [[ $roms != *$rom* ]]
    then
        roms+=$rom" "
    fi  
done

for rom in $roms
do
    romdir="$BUILD_ROOT/$rom" 
    if [ ! -d $romdir ]
    then
	setup_repo $rom $romdir
    fi
    cd $romdir
   
    # Cleanup our repo and sync
    repo forall -vc "git reset --hard"
    repo forall -vc "git clean -f"
    repo sync -f

    # Apply our own patches
    # Note: Order is important because of deps
    apply_patches "$SCRIPT_PATH/targets/general/patches"
    apply_patches "$SCRIPT_PATH/targets/$rom/patches"

    # Setup tools like lunch
    source build/envsetup.sh

    for target in $TARGETS
    do
	if [[ $target == $rom* ]]
	then
	    targetfirst=$(awk -F '_' '{print $1}' <<< $target)
	    # = lineage-14.1
            targetlast=$(awk -F '_' '{print $2}' <<< $target)
	    # = lux-user

	    romname=$(awk -F '-' '{print $1}' <<< $targetfirst)
	    # = lineage
	    version=$(awk -F '-' '{print $2}' <<< $targetfirst)
	    # = 14.1
	    device=$(awk -F '-' '{print $1}' <<< $targetlast)
	    # = lux
	    buildtype=$(awk -F '-' '{print $2}' <<< $targetlast)
	    # = user

            buildcombo=$romname"_"$targetlast
	    # = lineage_lux-user

	    dstpath=$OUTPUT_ROOT/$rom/$device/
	    timestamp=$(date +'%Y%m%d_%H%M')

	    mkdir -p $OUTPUT_ROOT/logs/
	    logpath=$OUTPUT_ROOT/logs/$rom-$device-$timestamp.log

	    brunch $buildcombo 1>>$logpath 2>&1
	    if [ $? == 127 ]
            then
                lunch $buildcombo 1>$logpath 2>&1
		if [ $? == 0 ]
		then
		    make -j $(nproc --all) 1>>$logpath 2>&1
		fi
            fi
	    if [ $? == 0 ]
            then
	        mkdir -p $dstpath && mv out/target/product/$device/*NIGHTLY*.zip  $dstpath/$rom-microg-$timestamp-$device.zip
            fi
            make clean
	fi
    done
done
rsync -av $OUTPUT_ROOT www-data@microg.me:/data/


