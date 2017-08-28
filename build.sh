#!/bin/bash

TARGETS="lineage_lux-user lineage_mido-user lineage_m8-user"

OUTPUT_ROOT="/data/archive"
BUILD_ROOT="/data/build"
CCACHE_DIR="$BUILD_ROOT/ccache"

SCRIPT=$( readlink -m $( type -p $0 ))
SCRIPT_PATH="$(dirname "$SCRIPT")"

USE_CCACHE=1
CCACHE_SIZE="120G"


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
            targettmp=$(awk -F '_' '{print $2}' <<< $target)
	    # = lux-user
	    device=$(awk -F '-' '{print $1}' <<< $targettmp)
	    # = lux
	    buildtype=$(awk -F '-' '{print $2}' <<< $targettmp)
	    # = user
	    dstpath=$OUTPUT_ROOT/$rom/$device/
	    brunch $target
	    if [ $? == 127 ]
            then
                lunch $target && make -j $(nproc --all)
            fi
	    if [ $? == 0 ]
            then
	        mkdir -p $dstpath && mv out/target/product/$device/*OFFICIAL*.zip  $dstpath/$rom-microg-$device-$(date +'%Y%m%d_%H%M')-UNOFFICIAL.zip
            fi
            make clean
	fi
    done
done
rsync -av $OUTPUT_ROOT www-data@microg.me:/data/


