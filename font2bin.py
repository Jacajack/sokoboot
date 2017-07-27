#!/usr/bin/python
#Script usage: ./font2bin.py <font image file> > <binary file>

import sys
import math
import os
from PIL import Image

if len( sys.argv ) < 2:
	sys.stderr.write( "aborting - no input file!\n" );
	exit( 1 );

image = Image.open( sys.argv[1] );
image = image.convert( "RGB" );
binstdout = os.fdopen( sys.stdout.fileno( ), "wb" )
width, height = image.size
row = 0

if ( width != 8 ):
    sys.stderr.write( "aborting - bad font width" );
    exit( 1 );

#Each pixel in line corresponds to one bit in byte
#Each line is 1 byte
for y in range( 0, height ):
	row = 0;
        for x in range( 0, width ):
		r, g, b = image.getpixel( ( x, y ) );
                row |= ( r + g + b > 3 * 128 ) << x; 
	binstdout.write( chr( row ) );
