#!/bin/bash

cd resources/levels
rm -f *.bin
for f in *.lvl; do
	../../lvlconv/lvlconv ./"$f" ./"${f%&.*l}.bin"
done
cd ..
cat levels/*.bin > levels.bin
