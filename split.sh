#!/bin/bash
if [[ -d split ]]; then rm -rf split; fi;
if [[ ! -d split ]]; then mkdir split; fi;
cp sokoboot.img split
cd split
split -b 18432 -a 2 -d sokoboot.img "tr"
find . -type f -name "tr*" -exec bash -c 'split -b 9216 -a 1 -d $0 "$0_h"' {} \;
find . -type f -name "tr*_h*" -exec bash -c 'split -b 512 -a 2 -d $0 "$0_sec"' {} \;
rm sokoboot.img
