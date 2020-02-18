#!/bin/bash
#
# Copyright (c) nexB Inc. http://www.nexb.com/ - All rights reserved.
#

# ScanCode release script
# This script creates and tests release archives in the dist/ dir

set -e

# un-comment to trace execution
set -x


function build_distribution {
    platform=$1
    dist_dir=dist/$platform
    mkdir -p $dist_dir
    echo "Building for: $platform"
    # install release manifest for this platform
    cp etc/release/MANIFEST.in.release-$platform MANIFEST.in
    # build proper
    bin/python setup.py --quiet --use-default-version clean --all sdist --formats=bztar,zip --dist-dir=$dist_dir
}


function run_test_scan {
    # run a test scan for a given archive
    platform=$1
    file_extension=$2
    extract_command=$3
    for archive in $platform/*.$file_extension;
        do
            echo "    RELEASE: Testing release archive: $archive ... "
            $($extract_command $archive)
            extract_dir=$(ls -d */)
            cd $extract_dir

            # this is needed for the zip
            chmod o+x scancode extractcode

            # minimal tests: update when new scans are available
            cmd="./scancode --quiet -lcip apache-2.0.LICENSE --json test_scan.json"
            echo "RUNNING TEST: $cmd"
            $cmd
            echo "TEST PASSED"

            cmd="./scancode --quiet -clipeu  apache-2.0.LICENSE --json-pp test_scan.json"
            echo "RUNNING TEST: $cmd"
            $cmd
            echo "TEST PASSED"

            cmd="./scancode --quiet -clipeu  apache-2.0.LICENSE --csv test_scan.csv"
            echo "RUNNING TEST: $cmd"
            $cmd
            echo "TEST PASSED"

            cmd="./scancode --quiet -clipeu apache-2.0.LICENSE --html test_scan.html"
            echo "RUNNING TEST: $cmd"
            $cmd
            echo "TEST PASSED"

            cmd="./scancode --quiet -clipeu apache-2.0.LICENSE --spdx-tv test_scan.spdx"
            echo "RUNNING TEST: $cmd"
            $cmd
            echo "TEST PASSED"

            cmd="./extractcode --quiet samples/arch"
            echo "RUNNING TEST: $cmd"
            $cmd
            echo "TEST PASSED"

            # cleanup
            cd ..
            rm -rf $extract_dir
            echo "    RELEASE: Success"
        done
}


################################################################################
echo "###  BUILDING ScanCode release ###"

echo "  RELEASE: Cleaning previous release archives, then setup and config: "
rm -rf dist/ build/

# backup dev manifest
cp MANIFEST.in MANIFEST.in.dev 

#./configure --clean
export CONFIGURE_QUIET=1
#./configure etc/conf

echo "  RELEASE: Building release archives..."
##############################################

PLATFORMS="python2-linux-64 python2-macos"
#python2-windows-32 python2-windows-64
#python3-linux-64 python3-macos python3-windows-32 python3-windows-64 everything"


for plat in $PLATFORMS;
do
    build_distribution $plat
done


echo "  RELEASE: Building release wheel..."
##############################################
bin/python setup.py --quiet --use-default-version clean --all bdist_wheel
    
# restore dev manifests
mv MANIFEST.in.dev MANIFEST.in


##############################################
cd dist
if [ "$1" != "--no-tests" ]; then
    echo "  RELEASE: Testing..."
    run_test_scan python2-linux-64 bz2 "tar -xf"
    run_test_scan python2-linux-64 zip "unzip -q"
else
    echo "  RELEASE: !!!!NOT Testing..."
fi


echo "###  RELEASE is ready for publishing  ###"

set +e
set +x
